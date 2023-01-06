import { action } from "@ember/object";
import Component from "@glimmer/component";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { tracked } from "@glimmer/tracking";
import { inject as service } from "@ember/service";
export default class RuleRow extends Component {
  @service siteSettings;
  @tracked isCategory = this.args.rule.type === "normal";
  @tracked isMessage = this.args.rule.type === "group_message";
  @tracked isMention = this.args.rule.type === "group_mention";

  @action
  delete(rule) {
    rule
      .destroyRecord()
      .then(() => this.args.refresh())
      .catch(popupAjaxError);
  }
}
