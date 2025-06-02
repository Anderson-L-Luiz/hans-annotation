<script setup lang="ts"></script>

<template>
  <div class="import">
    <h3>
      <label>{{ $t("Import.description") }}</label>
      <input
        id="formFileLg"
        class="form-control form-control-lg"
        ref="file"
        v-on:change="handleFileUpload()"
        type="file"
        accept=".mp4"
      />
      <label>{{ $t("Import.language") }}</label>
      <select v-model="metaUpload.language">
        <option selected="true">en</option>
        <option>de</option>
      </select>
      <br />
      <div>
        <div v-if="loading" class="progress">
          <div
            class="progress-bar progress-bar-striped progress-bar-animated"
            role="progressbar"
            :aria-valuenow="10"
            aria-valuemin="0"
            aria-valuemax="100"
            v-bind:style="{
              width: this.uploadStore.uploadPercentage + '%',
            }"
          ></div>
        </div>
        <br />
        <button
          type="button"
          class="btn btn-success"
          @click="submitUpload()"
          :disabled="disabled || loading"
        >
          {{ $t("Import.upload") }}
        </button>
        <br />
        <div v-if="this.loading && this.uploadStore.isUploadResponseOk">
          {{ $t("Import.ok") }}
        </div>
        <div v-else-if="this.loading && this.uploadStore.isUploadResponseError">
          {{ $t("Import.error") }}
        </div>
        <div v-else-if="this.loading && this.uploadStore.isUploadInProgress">
          {{ $t("Import.progress") }}
        </div>
      </div>
    </h3>
  </div>
</template>

<script>
import axios from "axios";
import { useUploadStore } from "@/stores/uploadStore";
export default {
  name: "ImportMedia",
  data() {
    return {
      file: "",
      metaUpload: {
        language: "en",
      },
      uploadResponse: "",
      uploadPercentage: 0,
      disabled: true,
      loading: false,
      uploadStore: useUploadStore(),
    };
  },
  methods: {
    handleFileUpload() {
      this.file = this.$refs.file.files[0];
      // console.log(">>>> 1st element in files array >>>> ", this.file);
      this.disabled = false;
    },
    submitUpload() {
      this.uploadResponse = "";
      this.uploadStore.setUploadPercentage(0);
      this.uploadStore.setUploadResponse(-1);
      this.loading = true;
      this.uploadFile();
    },
    //send file to minio with presigned upload URL
    uploadFile() {
      // console.log("Filepointer");
      // console.log(this.file);
      let data = {
        metaUpload: this.metaUpload,
        file: this.file,
      };
      this.uploadStore.upload(this.uploadStore, data);
      // console.log("Upload URL:" + uploadData.url);
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

.import h1,
.import h3 {
  text-align: center;
}

.import * {
  margin-top: 1em;
}

.import select {
  margin-left: 1em;
}

@media (min-width: 1024px) {
  .import h1,
  .import h3 {
    text-align: left;
  }
}
</style>
