import I18n from "I18n";
import ModalFunctionality from "discourse/mixins/modal-functionality";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { default as computed, on } from "discourse-common/utils/decorators";

export default Ember.Controller.extend(ModalFunctionality, {
  @on("init")
  setupKeydown() {
    Ember.run.schedule("afterRender", () => {
      $("#chat_integration_test_modal").keydown((e) => {
        if (e.keyCode === 13) {
          this.send("send");
        }
      });
    });
  },

  @computed("model.topic_id")
  sendDisabled(topicId) {
    return !topicId;
  },

  actions: {
    send() {
      if (this.get("sendDisabled")) return;
      this.set("loading", true);

      ajax("/admin/plugins/chat/test", {
        data: {
          channel_id: this.get("model.channel.id"),
          topic_id: this.get("model.topic_id"),
        },
        type: "POST",
      })
        .then(() => {
          this.set("loading", false);
          this.flash(I18n.t("chat_integration.test_modal.success"), "success");
        })
        .catch(popupAjaxError);
    },
  },
});
