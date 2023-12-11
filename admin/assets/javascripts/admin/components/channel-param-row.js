import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import I18n from "I18n";

export default class ChannelParamRow extends Component {
  @tracked inputValue = this.args.channel.data[this.args.param.key] || "";

  get validation() {
    if (this.inputValue === "") {
      return { failed: true };
    } else if (!this.args.param.regex) {
      return { ok: true };
    } else if (new RegExp(this.args.param.regex).test(this.inputValue)) {
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
    this.args.channel.data[this.args.param.key] = event.target.value;
  }
}
