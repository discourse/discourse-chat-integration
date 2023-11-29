import { tracked } from "@glimmer/tracking";
import Controller from "@ember/controller";
import { action } from "@ember/object";
import { not } from "@ember/object/computed";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import ModalFunctionality from "discourse/mixins/modal-functionality";
import I18n from "I18n";

export default class AdminPluginsChatIntegrationTest extends Controller.extend(
  ModalFunctionality
) {
  @tracked loading = false;
  @not("model.topic_id") sendDisabled;

  @action
  handleKeyUp(e) {
    if (e.code === "Enter" && !this.sendDisabled) {
      this.send();
    }
  }

  @action
  send() {
    if (this.sendDisabled) {
      return;
    }
    this.loading = true;

    ajax("/admin/plugins/chat-integration/test", {
      data: {
        channel_id: this.model.channel.id,
        topic_id: this.model.topic_id,
      },
      type: "POST",
    })
      .then(() => {
        this.loading = false;
        this.flash(I18n.t("chat_integration.test_modal.success"), "success");
      })
      .catch(popupAjaxError);
  }
}
