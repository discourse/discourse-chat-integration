import Component from "@glimmer/component";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { i18n } from "discourse-i18n";

export default class ChannelDetails extends Component {
  @service dialog;
  @service siteSettings;

  @action
  deleteChannel(channel) {
    this.dialog.deleteConfirm({
      message: i18n("chat_integration.channel_delete_confirm"),
      didConfirm: () => {
        return channel
          .destroyRecord()
          .then(() => this.args.refresh())
          .catch(popupAjaxError);
      },
    });
  }
}
