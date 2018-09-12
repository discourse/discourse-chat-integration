import { popupAjaxError } from "discourse/lib/ajax-error";
import computed from "ember-addons/ember-computed-decorators";

export default Ember.Component.extend({
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
    edit() {
      this.sendAction("edit", this.get("rule"));
    },

    delete(rule) {
      rule
        .destroyRecord()
        .then(() => {
          this.send("refresh");
        })
        .catch(popupAjaxError);
    },

    refresh() {
      this.sendAction("refresh");
    }
  }
});
