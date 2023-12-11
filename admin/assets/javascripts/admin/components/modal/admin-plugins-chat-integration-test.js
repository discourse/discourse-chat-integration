import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import I18n from "I18n";

export default class AdminPluginsChatIntegrationTest extends Component {
  @tracked loading = false;
  @tracked flash;

  get sendDisabled() {
    return !this.args.model.topic_id;
  }

  @action
  async send() {
    if (this.sendDisabled) {
      return;
    }

    this.loading = true;

    try {
      await ajax("/admin/plugins/chat-integration/test", {
        data: {
          channel_id: this.args.model.channel.id,
          topic_id: this.args.model.topic_id,
        },
        type: "POST",
      });

      this.loading = false;
      this.flash = I18n.t("chat_integration.test_modal.success");
    } catch (e) {
      popupAjaxError(e);
    }
  }
}
