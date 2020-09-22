import ModalFunctionality from "discourse/mixins/modal-functionality";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { default as computed, on } from "discourse-common/utils/decorators";

export default Ember.Controller.extend(ModalFunctionality, {
  saveDisabled: false,

  @on("init")
  setupKeydown() {
    Ember.run.schedule("afterRender", () => {
      $("#chat-integration-edit-channel-modal").keydown((e) => {
        if (e.keyCode === 13) {
          this.send("save");
        }
      });
    });
  },

  @computed("model.rule.type")
  showCategory(type) {
    return type === "normal";
  },

  actions: {
    save(rule) {
      if (this.get("saveDisabled")) {
        return;
      }

      rule
        .save()
        .then(() => this.send("closeModal"))
        .catch(popupAjaxError);
    },
  },
});
