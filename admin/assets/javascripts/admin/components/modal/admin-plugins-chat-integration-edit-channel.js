import Component from "@glimmer/component";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { action } from "@ember/object";
import { tracked } from "@glimmer/tracking";

export default class AdminPluginsChatIntegrationEditChannel extends Component {
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
