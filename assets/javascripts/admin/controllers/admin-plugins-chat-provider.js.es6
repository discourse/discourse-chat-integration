import showModal from "discourse/lib/show-modal";
import computed from "ember-addons/ember-computed-decorators";

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

  actions: {
    createChannel() {
      this.set("modalShowing", true);

      const model = {
        channel: this.store.createRecord("channel", {
          provider: this.get("model.provider.id"),
          data: {}
        }),
        provider: this.get("model.provider")
      };

      showModal("admin-plugins-chat-edit-channel", {
        model: model,
        admin: true
      });
    },

    editChannel(channel) {
      this.set("modalShowing", true);

      const model = {
        channel: channel,
        provider: this.get("model.provider")
      };

      showModal("admin-plugins-chat-edit-channel", {
        model: model,
        admin: true
      });
    },

    testChannel(channel) {
      this.set("modalShowing", true);
      showModal("admin-plugins-chat-test", {
        model: { channel: channel },
        admin: true
      });
    },

    createRule(channel) {
      this.set("modalShowing", true);

      const model = {
        rule: this.store.createRecord("rule", { channel_id: channel.id }),
        channel: channel,
        provider: this.get("model.provider"),
        groups: this.get("model.groups")
      };

      showModal("admin-plugins-chat-edit-rule", { model: model, admin: true });
    },
    editRule(rule, channel) {
      this.set("modalShowing", true);

      const model = {
        rule: rule,
        channel: channel,
        provider: this.get("model.provider"),
        groups: this.get("model.groups")
      };

      showModal("admin-plugins-chat-edit-rule", { model: model, admin: true });
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
