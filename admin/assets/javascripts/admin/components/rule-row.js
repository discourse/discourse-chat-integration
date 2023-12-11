import Component from "@glimmer/component";
import { action } from "@ember/object";
import { inject as service } from "@ember/service";
import { popupAjaxError } from "discourse/lib/ajax-error";

export default class RuleRow extends Component {
  @service siteSettings;

  get isCategory() {
    return this.args.rule.type === "normal";
  }

  get isMessage() {
    return this.args.rule.type === "group_message";
  }

  get isMention() {
    return this.args.rule.type === "group_mention";
  }

  @action
  delete(rule) {
    rule
      .destroyRecord()
      .then(() => this.args.refresh())
      .catch(popupAjaxError);
  }
}
