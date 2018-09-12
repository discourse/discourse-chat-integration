import ModalFunctionality from "discourse/mixins/modal-functionality";
import { popupAjaxError } from "discourse/lib/ajax-error";
import {
  default as computed,
  on
} from "ember-addons/ember-computed-decorators";

export default Ember.Controller.extend(ModalFunctionality, {
  saveDisabled: false,

  @on("init")
  setupKeydown() {
    Ember.run.schedule("afterRender", () => {
      $("#chat-integration-edit-channel-modal").keydown(e => {
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
    cancel() {
      this.send("closeModal");
    },

    save() {
      if (this.get("saveDisabled")) return;

      this.get("model.rule")
        .save()
        .then(() => {
          this.send("closeModal");
        })
        .catch(popupAjaxError);
    }
  }
});
