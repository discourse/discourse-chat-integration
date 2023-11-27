import Controller from "@ember/controller";
import showModal from "discourse/lib/show-modal";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";

const MODALS = {
  editChannel: "admin-plugins-chat-integration-edit-channel",
  testChannel: "admin-plugins-chat-integration-test",
  editRule: "admin-plugins-chat-integration-edit-rule",
  channelError: "admin-plugins-chat-integration-channel-error",
};

export default class AdminPluginsChatIntegrationEditRule extends Controller {
  @tracked modalShowing = false;

  get anyErrors() {
    const channels = this.model.channels;
    let anyErrors = false;

    channels.forEach((channel) => {
      if (channel.error_key) {
        anyErrors = true;
      }
    });

    return anyErrors;
  }

  triggerModal(model, modal) {
    this.modalShowing = true;

    showModal(modal, {
      model,
      admin: true,
    });
  }

  @action
  createChannel() {
    return this.triggerModal(
      {
        channel: this.store.createRecord("channel", {
          provider: this.model.provider.id,
          data: {},
        }),
        provider: this.model.provider,
      },
      MODALS.editChannel
    );
  }

  @action
  editChannel(channel) {
    return this.triggerModal(
      {
        channel,
        provider: this.model.provider,
      },
      MODALS.editChannel
    );
  }

  @action
  testChannel(channel) {
    return this.triggerModal({ channel }, MODALS.testChannel);
  }

  @action
  createRule(channel) {
    return this.triggerModal(
      {
        rule: this.store.createRecord("rule", {
          channel_id: channel.id,
          channel,
        }),
        channel,
        provider: this.model.provider,
        groups: this.model.groups,
      },
      MODALS.editRule
    );
  }

  @action
  editRuleWithChannel(rule, channel) {
    return this.triggerModal(
      {
        rule,
        channel,
        provider: this.model.provider,
        groups: this.model.groups,
      },
      MODALS.editRule
    );
  }

  @action
  showError(channel) {
    return this.triggerModal({ channel }, MODALS.channelError);
  }

  @action
  refresh() {
    this.send("refreshProvider");
  }
}
