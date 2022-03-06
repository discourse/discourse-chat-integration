import Controller from "@ember/controller";
import ModalFunctionality from "discourse/mixins/modal-functionality";
import { popupAjaxError } from "discourse/lib/ajax-error";
import computed, { on } from "discourse-common/utils/decorators";
import { schedule } from "@ember/runloop";

export default Controller.extend(ModalFunctionality, {
  saveDisabled: false,

  @on("init")
  setupKeydown() {
    schedule("afterRender", () => {
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
