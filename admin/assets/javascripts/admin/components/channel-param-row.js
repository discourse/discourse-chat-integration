import Component from "@glimmer/component";
import { action } from "@ember/object";
import I18n from "I18n";

export default class ChannelParamRow extends Component {
  get validation() {
    const value = this.args.channel.get(`data.${this.args.param.key}`);

    if (!value?.trim()) {
      return { failed: true };
    } else if (!this.args.param.regex) {
      return { ok: true };
    } else if (new RegExp(this.args.param.regex).test(value)) {
      return {
        ok: true,
        reason: I18n.t(
          "chat_integration.edit_channel_modal.channel_validation.ok"
        ),
      };
    } else {
      return {
        failed: true,
        reason: I18n.t(
          "chat_integration.edit_channel_modal.channel_validation.fail"
        ),
      };
    }
  }

  @action
  updateValue(event) {
    this.args.channel.set(`data.${this.args.param.key}`, event.target.value);
  }
}
