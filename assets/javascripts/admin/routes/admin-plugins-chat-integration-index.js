import DiscourseRoute from "discourse/routes/discourse";

export default class AdminPluginsChatIntegrationIndex extends DiscourseRoute {
  afterModel(model) {
    if (model.totalRows > 0) {
      this.transitionTo(
        "adminPlugins.chat-integration.provider",
        model.get("firstObject").name
      );
    }
  }
}
