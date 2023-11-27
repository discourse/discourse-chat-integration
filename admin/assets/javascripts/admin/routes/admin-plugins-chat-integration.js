import DiscourseRoute from "discourse/routes/discourse";
import { action } from "@ember/object";
import { inject as service } from "@ember/service";

export default class AdminPluginsChatIntegration extends DiscourseRoute {
  @service router;

  model() {
    return this.store.findAll("provider");
  }

  @action
  showSettings() {
    this.router.transitionTo("adminSiteSettingsCategory", "plugins", {
      queryParams: { filter: "chat_integration" },
    });
  }
}
