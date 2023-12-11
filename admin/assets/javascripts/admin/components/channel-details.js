import Component from "@glimmer/component";
import { action } from "@ember/object";
import { inject as service } from "@ember/service";
import { popupAjaxError } from "discourse/lib/ajax-error";
import I18n from "I18n";

export default class ChannelDetails extends Component {
  @service dialog;
  @service siteSettings;

  @action
  deleteChannel(channel) {
    this.dialog.deleteConfirm({
      message: I18n.t("chat_integration.channel_delete_confirm"),
      didConfirm: () => {
        return channel
          .destroyRecord()
          .then(() => this.args.refresh())
          .catch(popupAjaxError);
      },
    });
  }
}
