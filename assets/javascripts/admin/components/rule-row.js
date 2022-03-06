import Component from "@ember/component";
import { popupAjaxError } from "discourse/lib/ajax-error";
import computed from "discourse-common/utils/decorators";

export default Component.extend({
  tagName: "tr",

  @computed("rule.type")
  isCategory(type) {
    return type === "normal";
  },

  @computed("rule.type")
  isMessage(type) {
    return type === "group_message";
  },

  @computed("rule.type")
  isMention(type) {
    return type === "group_mention";
  },

  actions: {
    delete(rule) {
      rule
        .destroyRecord()
        .then(() => this.refresh())
        .catch(popupAjaxError);
    },
  },
});
