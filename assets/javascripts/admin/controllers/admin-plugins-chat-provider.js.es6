import showModal from "discourse/lib/show-modal";
import computed from "discourse-common/utils/decorators";

export default Ember.Controller.extend({
  modalShowing: false,

  @computed("model.channels")
  anyErrors(channels) {
    let anyErrors = false;

    channels.forEach(channel => {
      if (channel.error_key) {
        anyErrors = true;
      }
    });

    return anyErrors;
  },

  availableWebhooks() {
    const webhooks = this.get("model.webhooks");
    let available_webhooks = []
    webhooks.forEach(w => available_webhooks.push({ id: w.get("data.name"), name: w.get("data.name")}));
    return available_webhooks;
  },

  actions: {
    createWebhook() {
      this.set("modalShowing", true);

      const model = {
        webhook: this.store.createRecord("webhook", {
          provider: this.get("model.provider.id"),
          data: {}
        }),
        provider: this.get("model.provider")
      };

      showModal("admin-plugins-chat-edit-webhook", {
        model,
        admin: true
      });
    },

    editWebhook(webhook) {
      this.set("modalShowing", true);

      const model = {
        webhook,
        provider: this.get("model.provider")
      };

      showModal("admin-plugins-chat-edit-webhook", {
        model,
        admin: true
      });
    },

    createChannel() {
      this.set("modalShowing", true);

      const model = {
        channel: this.store.createRecord("channel", {
          provider: this.get("model.provider.id"),
          data: {}
        }),
        provider: this.get("model.provider"),
        webhooks: this.availableWebhooks()
      };

      showModal("admin-plugins-chat-edit-channel", {
        model,
        admin: true
      });
    },

    editChannel(channel) {
      this.set("modalShowing", true);

      const model = {
        channel,
        provider: this.get("model.provider"),
        webhooks: this.availableWebhooks()
      };

      showModal("admin-plugins-chat-edit-channel", {
        model,
        admin: true
      });
    },

    testChannel(channel) {
      this.set("modalShowing", true);
      showModal("admin-plugins-chat-test", {
        model: { channel },
        admin: true
      });
    },

    createRule(channel) {
      this.set("modalShowing", true);

      const model = {
        rule: this.store.createRecord("rule", { channel_id: channel.id }),
        channel,
        provider: this.get("model.provider"),
        groups: this.get("model.groups")
      };

      showModal("admin-plugins-chat-edit-rule", { model, admin: true });
    },

    editRuleWithChannel(rule, channel) {
      this.set("modalShowing", true);

      const model = {
        rule,
        channel,
        provider: this.get("model.provider"),
        groups: this.get("model.groups")
      };

      showModal("admin-plugins-chat-edit-rule", { model, admin: true });
    },

    showError(channel) {
      this.set("modalShowing", true);

      showModal("admin-plugins-chat-channel-error", {
        model: channel,
        admin: true
      });
    }
  }
});
