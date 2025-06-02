<template>
  <div class="openapi">
    <iframe
      class="openapi-iframe"
      src="http://127.0.0.1:5002/openapi/"
      allowfullscreen
    ></iframe>
  </div>
</template>

<style>
@media (min-width: 1024px) {
  .openapi {
    position: relative;
    overflow: hidden;
    width: 100%;
    height: 100vh;
    padding-top: 56.25%; /* 16:9 Aspect Ratio (divide 9 by 16 = 0.5625) */
    display: flex;
    align-items: center;
  }
  .openapi-iframe {
    position: absolute;
    top: 0;
    left: 0;
    bottom: 0;
    right: 0;
    width: 100%;
    height: 100%;
    border: none;
  }
}
</style>
