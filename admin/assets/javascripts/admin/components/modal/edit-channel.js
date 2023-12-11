import Component from "@glimmer/component";
import { action } from "@ember/object";
import { popupAjaxError } from "discourse/lib/ajax-error";

export default class EditChannel extends Component {
  get validParams() {
    return this.args.model.provider.channel_parameters.every((param) => {
      const value = this.args.model.channel.get(`data.${param.key}`);

      if (!value?.trim()) {
        return false;
      }

      if (!param.regex) {
        return true;
      }

      return new RegExp(param.regex).test(value);
    });
  }

  @action
  async save() {
    try {
      await this.args.model.channel.save();
      this.args.closeModal();
    } catch (e) {
      popupAjaxError(e);
    }
  }
}
