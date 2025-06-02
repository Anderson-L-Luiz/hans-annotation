import { defineStore } from "pinia";

export const useLocaleStore = defineStore({
  id: "localeStore",
  state: () => ({
    locale: "en",
  }),
  getters: {
    getLocale: (state) => state.locale,
  },
});
