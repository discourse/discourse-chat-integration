import Controller from "@ember/controller";
import ModalFunctionality from "discourse/mixins/modal-functionality";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { inject as service } from "@ember/service";

export default class AdminPluginsChatIntegrationEditRule extends Controller.extend(
  ModalFunctionality
) {
  @service siteSettings;
  @tracked saveDisabled = false;

  get showCategory() {
    return this.model.rule.type === "normal";
  }

  get currentRuleType() {
    return this.model.rule.type;
  }

  @action
  save(rule) {
    if (this.saveDisabled) {
      return;
    }

    rule
      .save()
      .then(() => this.send("closeModal"))
      .catch(popupAjaxError);
  }

  @action
  handleKeyUp(e) {
    if (e.code === "Enter") {
      this.save();
    }
  }

  @action
  onChangeRuleType(type) {
    this.model.rule.type = type;
    this.currentRuleType = type;
    if (type !== "normal") {
      this.showCategory = false;
    } else {
      this.showCategory = true;
    }
  }
}
