import { tracked } from "@glimmer/tracking";
import Controller from "@ember/controller";
import { action } from "@ember/object";
import { inject as service } from "@ember/service";
import ChannelErrorModal from "../components/modal/channel-error";
import EditChannelModal from "../components/modal/edit-channel";
import EditRuleModal from "../components/modal/edit-rule";
import TestModal from "../components/modal/test";

export default class AdminPluginsChatIntegrationProvider extends Controller {
  @service modal;
  @service store;

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

  triggerModal(modal, model) {
    this.modalShowing = true;

    this.modal.show(modal, {
      model: {
        ...model,
        admin: true,
      },
    });
  }

  @action
  createChannel() {
    return this.triggerModal(EditChannelModal, {
      channel: this.store.createRecord("channel", {
        provider: this.model.provider.id,
        data: {},
      }),
      provider: this.model.provider,
    });
  }

  @action
  editChannel(channel) {
    return this.triggerModal(EditChannelModal, {
      channel,
      provider: this.model.provider,
    });
  }

  @action
  testChannel(channel) {
    return this.triggerModal(TestModal, { channel });
  }

  @action
  createRule(channel) {
    return this.triggerModal(EditRuleModal, {
      rule: this.store.createRecord("rule", {
        channel_id: channel.id,
        channel,
      }),
      channel,
      provider: this.model.provider,
      groups: this.model.groups,
    });
  }

  @action
  editRuleWithChannel(rule, channel) {
    return this.triggerModal(EditRuleModal, {
      rule,
      channel,
      provider: this.model.provider,
      groups: this.model.groups,
    });
  }

  @action
  showError(channel) {
    return this.triggerModal(ChannelErrorModal, { channel });
  }

  @action
  refresh() {
    this.send("refreshProvider");
  }
}
