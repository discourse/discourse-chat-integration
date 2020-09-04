import DiscourseRoute from "discourse/routes/discourse";

export default DiscourseRoute.extend({
  model() {
    return this.store.findAll("provider");
  },

  actions: {
    showSettings() {
      this.transitionTo("adminSiteSettingsCategory", "plugins", {
        queryParams: { filter: "chat_integration" },
      });
    },
  },
});
