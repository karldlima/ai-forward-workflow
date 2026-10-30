#!/usr/bin/env bash
set -u

hook_name="${1:-}"
input="$(cat)"
project_dir="${CLAUDE_PROJECT_DIR:-$(pwd)}"
preferences_file="$project_dir/artefacts/harness-preferences.md"
state_dir="${TMPDIR:-/tmp}/ai-forward-workflow-hooks"

commit_types="feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert"
conventional_subject="^(${commit_types})(\([^)]+\))?!?: .+"
conventional_in_command="(^|[\"'[:space:]]|\\\$\()(${commit_types})(\([^)]+\))?!?: [^[:space:]]"
pull_request_title="^([A-Z][A-Z0-9]+-[0-9]+ )?(${commit_types})(\([^)]+\))?!?: .+"
template_headings=("## Description" "## Testing")

turn_off_hint() {
  echo "The user can turn these off at any time by saying so: set \`$1: off\` under Hooks in artefacts/harness-preferences.md (or \`hooks: off\` for all of them), for example through /workflow-configure."
}

setting_is_off() {
  [ -f "$preferences_file" ] || return 1
  grep -Eiq "^[-*][[:space:]]*$1:[[:space:]]*off[[:space:]]*$" "$preferences_file"
}

hook_disabled() {
  setting_is_off "hooks" || setting_is_off "$1"
}

json_field() {
  printf '%s' "$input" | jq -r "$1 // empty" 2>/dev/null
}

emit_context() {
  jq -n --arg event "$1" --arg text "$2" \
    '{hookSpecificOutput: {hookEventName: $event, additionalContext: $text}}'
}

emit_deny() {
  jq -n --arg reason "$1" \
    '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $reason}}'
}

session_key() {
  json_field '.session_id' | tr -c 'A-Za-z0-9_-' '_'
}

command_hash() {
  printf '%s' "$(session_key)$1" | shasum | cut -d' ' -f1
}

marker_exists() {
  [ -f "$state_dir/$1" ]
}

mark() {
  mkdir -p "$state_dir" && : > "$state_dir/$1"
}

is_commit_command() {
  printf '%s' "$1" | grep -Eq '(^|[;&|[:space:]])git[[:space:]]+commit([[:space:]]|$)'
}

is_pr_create_command() {
  printf '%s' "$1" | grep -Eq '(^|[;&|[:space:]])gh[[:space:]]+pr[[:space:]]+create([[:space:]]|$)'
}

has_inline_message() {
  printf '%s' "$1" | grep -Eq '(^|[[:space:]])(-[a-zA-Z]*m|--message)([[:space:]=]|$)'
}

has_inline_body() {
  printf '%s' "$1" | grep -Eq '(^|[[:space:]])(-b|--body)([[:space:]=]|$)'
}

body_follows_template() {
  local body="$1" heading
  for heading in "${template_headings[@]}"; do
    printf '%s' "$body" | grep -Fq "$heading" || return 1
  done
}

commit_pre() {
  hook_disabled commit-hooks && return 0
  local command
  command="$(json_field '.tool_input.command')"
  is_commit_command "$command" || return 0
  has_inline_message "$command" || return 0
  printf '%s' "$command" | grep -Eq "$conventional_in_command" && return 0
  local key
  key="commit-$(command_hash "$command")"
  marker_exists "$key" && return 0
  mark "$key"
  emit_deny "This commit message does not follow the Conventional Commits convention (type(scope): description, with type one of ${commit_types//|/, }). Before committing: tell the user, offer to write the message for them from the staged changes, and suggest following the project's commit conventions (artefacts/conventional-commits.md in the project, otherwise the AI Forward Workflow default), or offer to help set conventions up if the project has none. If you wrote this message yourself, rewrite it to follow the convention. If the user wants it exactly as written, run the same command again and it will go through. $(turn_off_hint commit-hooks)"
}

commit_post() {
  hook_disabled commit-hooks && return 0
  local command subject
  command="$(json_field '.tool_input.command')"
  is_commit_command "$command" || return 0
  subject="$(git -C "$project_dir" log -1 --format=%s 2>/dev/null)" || return 0
  [ -n "$subject" ] || return 0
  case "$subject" in Merge\ *) return 0 ;; esac
  printf '%s' "$subject" | grep -Eq "$conventional_subject" && return 0
  emit_context PostToolUse "The commit just made has the subject \"$subject\", which does not follow the Conventional Commits convention (type(scope): description, with type one of ${commit_types//|/, }). Evaluate it against the project's commit conventions, tell the user what is wrong, and offer to fix it with \`git commit --amend\` if it has not been pushed. Do not amend without the user's agreement. $(turn_off_hint commit-hooks)"
}

pr_pre() {
  hook_disabled pr-hooks && return 0
  local command
  command="$(json_field '.tool_input.command')"
  is_pr_create_command "$command" || return 0
  has_inline_body "$command" || return 0
  body_follows_template "$command" && return 0
  local key
  key="pr-$(command_hash "$command")"
  marker_exists "$key" && return 0
  mark "$key"
  emit_deny "This PR description does not follow the PR template (Ticket, Description, Acceptance criteria and Testing sections). Before creating the PR: tell the user, offer to write the title and description for them from the branch's changes, and suggest following the project's PR conventions (artefacts/pr-template.md in the project, otherwise the AI Forward Workflow default), or offer to help set a PR template up if the project has none. If you wrote this description yourself, rewrite it to follow the template. If the user wants it exactly as written, run the same command again and it will go through. $(turn_off_hint pr-hooks)"
}

pr_post() {
  hook_disabled pr-hooks && return 0
  local command url details title body problems=""
  command="$(json_field '.tool_input.command')"
  is_pr_create_command "$command" || return 0
  url="$(printf '%s' "$input" | grep -Eo 'https://[^" \\]+/pull/[0-9]+' | head -1)"
  [ -n "$url" ] || return 0
  details="$(gh pr view "$url" --json title,body 2>/dev/null)" || return 0
  title="$(printf '%s' "$details" | jq -r '.title')"
  body="$(printf '%s' "$details" | jq -r '.body')"
  printf '%s' "$title" | grep -Eq "$pull_request_title" || problems="the title \"$title\" does not follow the convention (optional ticket key, then type(scope): description). "
  body_follows_template "$body" || problems="${problems}the description is missing sections of the PR template (Ticket, Description, Acceptance criteria, Testing). "
  [ -n "$problems" ] || return 0
  emit_context PostToolUse "The PR just created ($url) does not follow the project's PR conventions: ${problems}Tell the user what is wrong and offer to fix it with \`gh pr edit\`. Do not edit the PR without the user's agreement. $(turn_off_hint pr-hooks)"
}

prompt_word_count() {
  printf '%s' "$1" | wc -w | tr -d ' '
}

prompt_is_command() {
  case "$1" in /*|!*) return 0 ;; esac
  return 1
}

prompt_refine() {
  hook_disabled prompt-refinement && return 0
  local prompt
  prompt="$(json_field '.prompt')"
  prompt_is_command "$prompt" && return 0
  [ "$(prompt_word_count "$prompt")" -ge 8 ] || return 0
  local text="If the user's prompt is a non-trivial task that is missing parts of the AI Forward Workflow prompt engineering template (role/persona, task, context and constraints, output format), offer before doing the work to write a refined version of their prompt in that format, and suggest shot-examples if the task has a specific input/output shape. Show the refined prompt and ask which to use; never rewrite it silently. Say nothing if the prompt is already clear and complete or is a short follow-up in an ongoing task."
  local key="prompt-hint-$(session_key)"
  if ! marker_exists "$key"; then
    mark "$key"
    text="$text Also tell the user once, in a line, that $(turn_off_hint prompt-refinement)"
  fi
  emit_context UserPromptSubmit "$text"
}

subagent_roles() {
  hook_disabled subagent-roles && return 0
  local prompt key
  prompt="$(json_field '.prompt')"
  prompt_is_command "$prompt" && return 0
  [ "$(prompt_word_count "$prompt")" -ge 15 ] || return 0
  key="roles-$(session_key)"
  marker_exists "$key" && return 0
  mark "$key"
  emit_context UserPromptSubmit "If the multi-step agent system is on (it is by default; check artefacts/harness-preferences.md) and this prompt is a multi-part task, offer once to set up roles for subagents related to it, as part of multi-agent orchestration (Orchestrator-Subagent pattern): propose two to four roles, each with a one-line responsibility and the tools it needs, for example a researcher, an implementer and a reviewer. Only if the user accepts, save each role as a subagent definition at .claude/agents/<role>.md in the project (frontmatter with name, description and tools, then the role's system prompt), and make sure .claude/agents/ is listed in .gitignore so the roles stay on the user's machine. Say nothing if the task is small. $(turn_off_hint subagent-roles)"
}

own_ci_exists() {
  local file workflow
  for file in .gitlab-ci.yml .circleci/config.yml Jenkinsfile azure-pipelines.yml .travis.yml bitbucket-pipelines.yml; do
    [ -e "$project_dir/$file" ] && return 0
  done
  for workflow in "$project_dir"/.github/workflows/*.y*ml; do
    [ -e "$workflow" ] || continue
    [ "$(basename "$workflow")" = "ai-forward-workflow-ci.yml" ] || return 0
  done
  return 1
}

npm_test_script_is_real() {
  jq -e '.scripts.test // empty | select(contains("no test specified") | not)' "$project_dir/package.json" >/dev/null 2>&1
}

detect_test_command() {
  cd "$project_dir" || return 1
  if [ -f package.json ] && npm_test_script_is_real; then
    if [ -f pnpm-lock.yaml ]; then echo "pnpm test"
    elif [ -f yarn.lock ]; then echo "yarn test"
    else echo "npm test"
    fi
  elif [ -f go.mod ]; then echo "go test ./..."
  elif [ -f Cargo.toml ]; then echo "cargo test"
  elif [ -f pytest.ini ] || [ -f pyproject.toml ] || [ -f tox.ini ]; then echo "python -m pytest"
  elif [ -f Makefile ] && grep -Eq '^test:' Makefile; then echo "make test"
  else return 1
  fi
}

head_commit() {
  git -C "$project_dir" rev-parse HEAD 2>/dev/null
}

record_head() {
  local head
  head="$(head_commit)" || return 0
  mkdir -p "$state_dir" && printf '%s' "$head" > "$state_dir/head-$(session_key)"
}

stop_ci() {
  hook_disabled ci-hook && return 0
  [ "$(json_field '.permission_mode')" = "auto" ] || return 0
  own_ci_exists && return 0
  local session head recorded command output status failures max_iterations=5
  session="$(session_key)"
  head="$(head_commit)" || return 0
  recorded="$(cat "$state_dir/head-$session" 2>/dev/null)"
  [ -n "$recorded" ] && [ "$head" != "$recorded" ] || return 0
  command="$(detect_test_command)" || return 0
  output="$(cd "$project_dir" && sh -c "$command" 2>&1)"
  status=$?
  if [ "$status" -eq 0 ]; then
    rm -f "$state_dir/failures-$session"
    record_head
    jq -n --arg text "CI tests passed after the commit (\`$command\`)." '{systemMessage: $text}'
    return 0
  fi
  failures=$(( $(cat "$state_dir/failures-$session" 2>/dev/null || echo 0) + 1 ))
  printf '%s' "$failures" > "$state_dir/failures-$session"
  if [ "$failures" -ge "$max_iterations" ]; then
    rm -f "$state_dir/failures-$session"
    record_head
    jq -n --arg text "CI tests (\`$command\`) still fail after $max_iterations attempts. The verification loop has stopped: this needs a human, so escalate it." '{systemMessage: $text}'
    return 0
  fi
  jq -n --arg reason "This project has no CI of its own, so the workflow's local CI check ran \`$command\` after your commit and it failed (attempt $failures of $max_iterations). Fix the failures, commit the fix and stop again; this is the verification loop. Last output:
$(printf '%s' "$output" | tail -40)
$(turn_off_hint ci-hook)" '{decision: "block", reason: $reason}'
}

case "$hook_name" in
  commit-pre) commit_pre ;;
  commit-post) commit_post ;;
  pr-pre) pr_pre ;;
  pr-post) pr_post ;;
  prompt-refine) prompt_refine ;;
  subagent-roles) subagent_roles ;;
  record-head) record_head ;;
  stop-ci) stop_ci ;;
esac
exit 0
