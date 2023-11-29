import { tracked } from "@glimmer/tracking";
import Controller from "@ember/controller";
import { action } from "@ember/object";
import { popupAjaxError } from "discourse/lib/ajax-error";
import ModalFunctionality from "discourse/mixins/modal-functionality";

export default class AdminPluginsChatIntegrationEditChannel extends Controller.extend(
  ModalFunctionality
) {
  @tracked validParams = false;

  @action
  isValidParams(validity) {
    return (this.validParams = validity);
  }

  @action
  handleKeyUp(e) {
    if (e.code === "Enter" && this.validParams) {
      this.save();
    }
  }

  @action
  cancel() {
    this.send("closeModal");
  }

  @action
  save() {
    if (!this.validParams) {
      return;
    }

    this.model.channel
      .save()
      .then(() => {
        this.send("closeModal");
      })
      .catch(popupAjaxError);
  }
}
