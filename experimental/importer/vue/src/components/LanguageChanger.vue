<script setup lang="ts"></script>

<template>
  <select v-model="$i18n.locale">
    <option>de</option>
    <option selected="true">en</option>
  </select>
</template>

<script>
import { useLocaleStore } from "../stores/localeStore";

export default {
  // Still buggy check: https://kazupon.github.io/vue-i18n/guide/locale.html
  name: "LanguageChanger",
  data() {
    return {
      lang: "en",
    };
  },
  beforeRouteUpdate() {
    useLocaleStore().locale = this.$i18n.locale;
  },
};
</script>
