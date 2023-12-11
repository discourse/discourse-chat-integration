import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import I18n from "I18n";

export default class ChannelParamRow extends Component {
  @tracked inputValue = this.args.model.channel.data[this.args.param.key] || "";

  get validate() {
    const parameter = this.args.param;
    const regString = parameter.regex;
    const regex = new RegExp(regString);

    if (this.inputValue === "") {
      // Fail silently if field blank
      this.args.setValidParams(false);
      return {
        failed: true,
      };
    } else if (!regString) {
      // Pass silently if no regex available for provider
      this.args.setValidParams(true);
      return {
        ok: true,
      };
    } else if (regex.test(this.inputValue)) {
      // Test against regex
      this.args.setValidParams(true);
      return {
        ok: true,
        reason: I18n.t(
          "chat_integration.edit_channel_modal.channel_validation.ok"
        ),
      };
    } else {
      // Failed regex
      this.args.setValidParams(false);
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
    this.args.model.channel.data[this.args.param.key] = event.target.value;
  }
}
