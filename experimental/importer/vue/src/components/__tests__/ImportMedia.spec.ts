import { describe, it, expect } from "vitest";

import { mount } from "@vue/test-utils";
import ImportMedia from "../ImportMedia.vue";

const $t = () => "Hochfahren";

describe("ImportMedia", () => {
  it("renders properly", () => {
    const wrapper = mount(ImportMedia, {
      global: {
        mocks: {
          $t,
        },
      },
    });
    //const wrapper = mount(ImportMedia);
    expect(wrapper.text()).toContain("Hochfahren");
  });
});
