import { defineStore } from "pinia";
import axios from "axios";

enum UploadResponse {
  None = -1,
  Ok = 0,
  InProgress = 1,
  Error = 2,
}

export const useUploadStore = defineStore({
  id: "uploadStore",
  state: () => ({
    uploadPercentage: 0,
    uploadResponse: UploadResponse.Error,
  }),
  getters: {
    getUploadPercentage: (state) => state.uploadPercentage,
    isUploadResponseOk: (state) => state.uploadResponse == UploadResponse.Ok,
    isUploadInProgress: (state) =>
      state.uploadResponse == UploadResponse.InProgress,
    isUploadResponseError: (state) =>
      state.uploadResponse == UploadResponse.Error,
  },
  actions: {
    setUploadPercentage(percentage: number) {
      this.$state.uploadPercentage = percentage;
    },

    setUploadResponse(status: UploadResponse) {
      this.$state.uploadResponse = status;
    },

    upload(mUploadStore, data) {
      const headers = {
        "Content-Type": "multipart/form-data",
      };

      const formData = new FormData();
      formData.append("file", data.file);
      //formData.append("filename", data.filename);
      //formData.append("url", data.url);
      formData.append("language", data.metaUpload.language.toString());

      return axios
        .post("api/upload", formData, {
          headers: headers,
          onUploadProgress: function (progressEvent) {
            mUploadStore.setUploadPercentage(
              (progressEvent.loaded / progressEvent.total) * 100 - 5
            );
            mUploadStore.setUploadResponse(UploadResponse.InProgress);
          },
        })
        .then(
          (response) => {
            // console.log(response);
            mUploadStore.setUploadPercentage(100);
            mUploadStore.setUploadResponse(UploadResponse.Ok);
          },
          (error) => {
            console.log(error);
            mUploadStore.setUploadPercentage(0);
            mUploadStore.setUploadResponse(UploadResponse.Error);
          }
        );
    },
  },
});
