import DiscourseRoute from "discourse/routes/discourse";
import { inject as service } from "@ember/service";

export default class AdminPluginsChatIntegrationIndex extends DiscourseRoute {
  @service router;

  afterModel(model) {
    if (model.totalRows > 0) {
      this.router.transitionTo(
        "adminPlugins.chat-integration.provider",
        model.get("firstObject").name
      );
    }
  }
}
