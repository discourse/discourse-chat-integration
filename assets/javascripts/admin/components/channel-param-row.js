import Component from "@glimmer/component";
import EmberObject, { action } from "@ember/object";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";

export default class ChannelParamRow extends Component {
  @tracked inputValue = this.args.model.channel.data[this.args.param.key];

  get validate() {
    const parameter = this.args.param;
    const regString = parameter.regex;
    const regex = new RegExp(regString);

    if (this.inputValue === undefined) {
      this.inputValue = "";
    }

    if (this.inputValue === "") {
      // Fail silently if field blank
      this.args.isValidParams(false);
      return EmberObject.create({
        failed: true,
      });
    } else if (!regString) {
      // Pass silently if no regex available for provider
      this.args.isValidParams(true);
      return EmberObject.create({
        ok: true,
      });
    } else if (regex.test(this.inputValue)) {
      // Test against regex
      this.args.isValidParams(true);
      return EmberObject.create({
        ok: true,
        reason: I18n.t(
          "chat_integration.edit_channel_modal.channel_validation.ok"
        ),
      });
    } else {
      // Failed regex
      this.args.isValidParams(false);
      return EmberObject.create({
        failed: true,
        reason: I18n.t(
          "chat_integration.edit_channel_modal.channel_validation.fail"
        ),
      });
    }
  }
}
