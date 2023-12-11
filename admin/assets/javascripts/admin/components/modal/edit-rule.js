import Component from "@glimmer/component";
import { action } from "@ember/object";
import { inject as service } from "@ember/service";
import { popupAjaxError } from "discourse/lib/ajax-error";

export default class EditRule extends Component {
  @service siteSettings;

  @action
  async save(rule) {
    try {
      await rule.save();
      this.args.closeModal();
    } catch (e) {
      popupAjaxError(e);
    }
  }
}
