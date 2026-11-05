# Design system guide

We use design systems in frontend projects to establish a single source of truth that promotes brand cohesion and reusability.

## Characteristics

Maintainability and scalability apply to any design system. Flexibility, performance and accessibility are a choice, based on what matters to the project.

| Characteristic | What to choose | Applies to |
| --- | --- | --- |
| Flexibility | Unopinionated headless libraries (Radix UI) over opinionated full libraries (Ant Design) | A choice |
| Performance | Unopinionated headless libraries (Radix UI) or a utility library over CSS-in-JS | A choice |
| Accessibility | A library that offers semantic HTML, ARIA labels and support for impaired users: keyboard support, screen reader support, colour contrast support | A choice |
| Maintainability | Rigid shared HOC wrappers and governance meetings | Any design system |
| Scalability | SemVer (major, minor, patch) and a documented rollout: clone and deprecate, or a coordinated staged migration | Any design system |

## Layers

A design system is built in this order, each layer on the one before:

1. **Design foundations:** tokens, atomic design, Figma.
2. **Styling methodology:** Sass, BEM, CSS or CSS Modules.
3. **Component library:** a shared component library with base components and HOC wrappers. It can be an npm package, monorepo shared packages or a monolith global folder. It has three dimensions: distributed or packaged, headless or pre-styled, opinionated or unopinionated.
4. **Styling layer:** Tailwind utilities, CSS variables and CVA. Multi-tenancy is decided here.
5. **Documentation and CI:** Storybook, and regression testing through Jest and Enzyme, or RTL unit tests, on the Storybook components.

## Styling methodologies

| Styling methodology | Onboarding | Naming convention | Reusability and scaling | Multi-tenancy |
| --- | --- | --- | --- | --- |
| Sass (SCSS) | Moderate | Flexible; team-defined | High | High |
| BEM | Easy | Excellent: strict convention | Moderate | Moderate |
| CSS | Easy | None enforced | Low to moderate | Moderate |
| CSS Modules | Easy | Locally scoped naming | High | High |

## Component libraries

Accessibility columns: how well the library supports accessibility, keyboard use and semantic HTML. Performance: whether the library uses runtime CSS-in-JS. Flexibility: whether it is headless or unstyled, and whether it is unopinionated.

| Component library | A11y support | Keyboard support | Semantic HTML | Runtime CSS-in-JS | Headless / unstyled | Unopinionated |
| --- | --- | --- | --- | --- | --- | --- |
| MUI | Strong | Yes | Yes | v5: yes; v6: Pigment option | Version-dependent | No: Google's design philosophy, specific ways to interact with theme providers and design tokens |
| Ant Design | Built-in | Yes | Yes | Yes (CSS-in-JS) | No | No |
| Chakra UI | Built-in | Yes | Yes | Yes | No | No |
| Shadcn/ui | Radix-based | Yes | Yes | No | Partially | Moderate: styled in a certain way |
| Radix UI | Strong | Yes | Yes | No | Yes | Yes |
| React Aria | Excellent | Yes | Yes | No | Yes | Yes |
| Mantine | Built-in | Yes | Yes | Yes | No | No: all-in-one, with form validation and state hooks |
| CSS Modules + custom components | Implementation-dependent | Implementation-dependent | Implementation-dependent | No | Yes | Yes |
| Emotion.js | N/A | N/A | N/A | Yes | N/A | Yes |
| Styled Components | N/A | N/A | N/A | Yes | N/A | Yes |
