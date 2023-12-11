import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { popupAjaxError } from "discourse/lib/ajax-error";

export default class EditChannel extends Component {
  @tracked validParams = false;

  // @action
  // handleKeyUp(e) {
  //   if (e.code === "Enter" && this.validParams) {
  //     this.save();
  //   }
  // }

  @action
  async save() {
    // if (!this.validParams) {
    //   return;
    // }

    try {
      await this.model.channel.save();
      this.args.closeModal();
    } catch (e) {
      popupAjaxError(e);
    }
  }
}
