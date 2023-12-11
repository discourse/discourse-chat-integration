<<<<<<< HEAD:admin/assets/javascripts/admin/components/modal/admin-plugins-chat-integration-edit-rule.js
import Component from "@glimmer/component";
import { popupAjaxError } from "discourse/lib/ajax-error";
=======
>>>>>>> main:admin/assets/javascripts/admin/controllers/modals/admin-plugins-chat-integration-edit-rule.js
import { tracked } from "@glimmer/tracking";
import Controller from "@ember/controller";
import { action } from "@ember/object";
import { inject as service } from "@ember/service";
import { popupAjaxError } from "discourse/lib/ajax-error";
import ModalFunctionality from "discourse/mixins/modal-functionality";

export default class AdminPluginsChatIntegrationEditRule extends Component {
  @service siteSettings;

  @tracked saveDisabled = false;

  get showCategory() {
    return this.args.model.rule.type === "normal";
  }

  get currentRuleType() {
    return this.args.model.rule.type;
  }

  @action
  async save(rule) {
    if (this.saveDisabled) {
      return;
    }

    try {
      await rule.save();
      this.args.closeModal();
    } catch (e) {
      popupAjaxError(e);
    }
  }

  @action
  onChangeRuleType(type) {
    this.args.model.rule.type = type;
    // TODO
    this.currentRuleType = type;

    // TODO
    if (type !== "normal") {
      this.showCategory = false;
    } else {
      this.showCategory = true;
    }
  }
}
