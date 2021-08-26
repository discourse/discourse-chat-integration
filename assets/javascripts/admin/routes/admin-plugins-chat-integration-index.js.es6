import DiscourseRoute from "discourse/routes/discourse";

export default DiscourseRoute.extend({
  afterModel(model) {
    if (model.totalRows > 0) {
      this.transitionTo(
        "adminPlugins.chat.provider",
        model.get("firstObject").name
      );
    }
  },
});
