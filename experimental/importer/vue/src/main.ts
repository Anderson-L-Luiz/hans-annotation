import "bootstrap/dist/css/bootstrap.min.css";
import "bootstrap";

import { createApp } from "vue";
import { createStore } from "./stores/serviceConfigStore";
import { createI18n } from "vue-i18n";

import App from "./App.vue";
import router from "./router";

// Annotation and ml-backend config
import extConfig from "./config/config.json";

const configuration = {
  config: extConfig,
};

//console.log("Configuration: " + JSON.stringify(configuration));

// i18n

import translationsDe from "./translations/de.json";
import translationsEn from "./translations/en.json";

const messages = {
  de: translationsDe,
  en: translationsEn,
};

const i18n = createI18n({
  locale: "en", // set locale
  fallbackLocale: "de", // set fallback locale
  messages,
});

// Initialization

const app = createApp(App);

app.use(createStore(configuration));
app.use(i18n);
app.use(router);

app.mount("#app");

import "bootstrap/dist/js/bootstrap.js";
