import { describe, it, expect } from "vitest";

import { mount } from "@vue/test-utils";
import ServiceConfig from "../ServiceConfig.vue";

import { PiniaVuePlugin } from 'pinia'
import { createTestingPinia } from '@pinia/testing'

const $t = () => "Hochfahren";

describe("ImportMedia", () => {
  it("renders properly", () => {
    const wrapper = mount(ServiceConfig, {
      global: {
        mocks: {
          $t,
        },
      },
      pinia: createTestingPinia(),
    });
    //const wrapper = mount(ImportMedia);
    expect(wrapper.text()).toContain("Hochfahren");
  });
});
