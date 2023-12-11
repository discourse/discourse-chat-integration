import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { inject as service } from "@ember/service";
import { popupAjaxError } from "discourse/lib/ajax-error";

export default class EditRule extends Component {
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
