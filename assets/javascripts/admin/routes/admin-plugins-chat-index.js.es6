export default Discourse.Route.extend({
  afterModel(model) {
    if (model.totalRows > 0) {
      this.transitionTo('adminPlugins.chat.provider', model.get('firstObject').name);
    }
  }
});
