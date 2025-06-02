<script setup lang="ts"></script>

<template>
  <div class="serviceConfig">
    <h3>
      <label>{{ $t("ServiceConfig.description") }}</label>
      <ul>
        <li v-for="(item, key) in jsonData" :key="key">
          {{ key }}: {{ item }}
        </li>
      </ul>
    </h3>
  </div>
</template>

<script>
import { useConfigStore } from "../stores/serviceConfigStore";
export default {
  name: "ServiceConfig",
  data() {
    return {
      jsonData: {},
    };
  },
  created() {
    this.loadJsonData();
  },
  methods: {
    loadJsonData() {
      this.jsonData = useConfigStore().config;
    },
  },
};
</script>

<style scoped>
h1 {
  font-weight: 500;
  font-size: 2.6rem;
  top: -10px;
}

h3 {
  font-size: 1.2rem;
}

.serviceConfig h1,
.serviceConfig h3 {
  text-align: center;
}

.serviceConfig * {
  margin-top: 1em;
}

.serviceConfig select {
  margin-left: 1em;
}

@media (min-width: 1024px) {
  .serviceConfig h1,
  .serviceConfig h3 {
    text-align: left;
  }
}
</style>
