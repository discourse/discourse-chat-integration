import Component from "@ember/component";
import { popupAjaxError } from "discourse/lib/ajax-error";
import I18n from "I18n";
import bootbox from "bootbox";

export default Component.extend({
  classNames: ["channel-details"],

  actions: {
    deleteChannel(channel) {
      bootbox.confirm(
        I18n.t("chat_integration.channel_delete_confirm"),
        I18n.t("no_value"),
        I18n.t("yes_value"),
        (result) => {
          if (result) {
            channel
              .destroyRecord()
              .then(() => this.refresh())
              .catch(popupAjaxError);
          }
        }
      );
    },

    editRule(rule) {
      this.editRuleWithChannel(rule, this.get("channel"));
    },
  },
});
