# Importer

## Vue

Components:

- [Vue](https://vuejs.org/)
- [Pinia](https://pinia.vuejs.org/)
- [Bootstrap](https://getbootstrap.com/)
- [vue-i18n](https://vue-i18n.intlify.dev/guide/)
- [Axios](https://axios-http.com/)

Testing:

- [Vitest](https://vitest.dev/)
  - [Instructions](https://vuejs.org/guide/scaling-up/testing.html#unit-testing)

- [Cypress](https://www.cypress.io/)
  - [Instructions](https://vuejs.org/guide/scaling-up/testing.html#e2e-testing)

### Installation

```bash
npm install vue@latest @vue/cli@latest
npm init vue@latest

✔ Project name: … vue
✔ Add TypeScript? … Yes
✔ Add JSX Support? … No
✔ Add Vue Router for Single Page Application development? … Yes
✔ Add Pinia for state management? … Yes
✔ Add Vitest for Unit Testing? … Yes
✔ Add Cypress for End-to-End testing? … Yes
✔ Add ESLint for code quality? … Yes
✔ Add Prettier for code formatting? … Yes

cd vue

npm install && \
npm install --save bootstrap && \
npm install vue-i18n@9 && \
npm install axios && \
npm install @pinia/testing

npm run dev
```
