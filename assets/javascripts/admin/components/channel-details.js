import Component from "@ember/component";
import { popupAjaxError } from "discourse/lib/ajax-error";
import I18n from "I18n";
import { inject as service } from "@ember/service";

export default Component.extend({
  dialog: service(),
  classNames: ["channel-details"],

  actions: {
    deleteChannel(channel) {
      this.dialog.deleteConfirm({
        message: I18n.t("chat_integration.channel_delete_confirm"),
        didConfirm: () => {
          return channel
          .destroyRecord()
          .then(() => this.refresh())
          .catch(popupAjaxError);
        },
      });
    },

    editRule(rule) {
      this.editRuleWithChannel(rule, this.get("channel"));
    },
  },
});
