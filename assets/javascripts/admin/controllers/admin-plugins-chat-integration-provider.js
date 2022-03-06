import Controller from "@ember/controller";
import showModal from "discourse/lib/show-modal";
import computed from "discourse-common/utils/decorators";

export default Controller.extend({
  modalShowing: false,

  @computed("model.channels")
  anyErrors(channels) {
    let anyErrors = false;

    channels.forEach((channel) => {
      if (channel.error_key) {
        anyErrors = true;
      }
    });

    return anyErrors;
  },

  actions: {
    createChannel() {
      this.set("modalShowing", true);

      const model = {
        channel: this.store.createRecord("channel", {
          provider: this.get("model.provider.id"),
          data: {},
        }),
        provider: this.get("model.provider"),
      };

      showModal("admin-plugins-chat-integration-edit-channel", {
        model,
        admin: true,
      });
    },

    editChannel(channel) {
      this.set("modalShowing", true);

      const model = {
        channel,
        provider: this.get("model.provider"),
      };

      showModal("admin-plugins-chat-integration-edit-channel", {
        model,
        admin: true,
      });
    },

    testChannel(channel) {
      this.set("modalShowing", true);
      showModal("admin-plugins-chat-integration-test", {
        model: { channel },
        admin: true,
      });
    },

    createRule(channel) {
      this.set("modalShowing", true);

      const model = {
        rule: this.store.createRecord("rule", {
          channel_id: channel.id,
          channel,
        }),
        channel,
        provider: this.get("model.provider"),
        groups: this.get("model.groups"),
      };

      showModal("admin-plugins-chat-integration-edit-rule", {
        model,
        admin: true,
      });
    },

    editRuleWithChannel(rule, channel) {
      this.set("modalShowing", true);

      const model = {
        rule,
        channel,
        provider: this.get("model.provider"),
        groups: this.get("model.groups"),
      };

      showModal("admin-plugins-chat-integration-edit-rule", {
        model,
        admin: true,
      });
    },

    showError(channel) {
      this.set("modalShowing", true);

      showModal("admin-plugins-chat-integration-channel-error", {
        model: channel,
        admin: true,
      });
    },
  },
});
