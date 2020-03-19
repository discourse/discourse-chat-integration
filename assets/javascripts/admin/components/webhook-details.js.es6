import { popupAjaxError } from "discourse/lib/ajax-error";

export default Ember.Component.extend({
  classNames: ["webhook-details"],

  actions: {
    deleteWebhook(webhook) {
      bootbox.confirm(
        I18n.t("chat_integration.webhook_delete_confirm"),
        I18n.t("no_value"),
        I18n.t("yes_value"),
        result => {
          if (result) {
            webhook
              .destroyRecord()
              .then(() => this.refresh())
              .catch(popupAjaxError);
          }
        }
      );
    }
  }
});
