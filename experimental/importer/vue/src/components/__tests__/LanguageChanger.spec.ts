import { describe, it, expect } from "vitest";

import { mount } from "@vue/test-utils";
import LanguageChanger from "../LanguageChanger.vue";

describe("ImportMedia", () => {
  it("renders properly", () => {
    const wrapper = mount(LanguageChanger, {
      global: {
        mocks: {
          $i18n: {
            locale: "de",
          },
        },
      },
    });
    expect(wrapper.text()).toContain("de");
  });
});
