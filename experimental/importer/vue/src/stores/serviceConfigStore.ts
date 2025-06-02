import { createPinia, defineStore } from "pinia";

let initData = null;

export const createStore = (initStoreData) => {
  initData = { ...initStoreData };
  return createPinia();
};

export const useConfigStore = defineStore({
  id: "serviceConfigStore",
  state: () => initData,
});
