import DiscourseRoute from "discourse/routes/discourse";
import { action } from "@ember/object";

export default class AdminPluginsChatIntegration extends DiscourseRoute {
  model() {
    return this.store.findAll("provider");
  }

  @action
  showSettings() {
    this.transitionTo("adminSiteSettingsCategory", "plugins", {
      queryParams: { filter: "chat_integration" },
    });
  }
}
