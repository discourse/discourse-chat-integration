export default Discourse.Route.extend({
	model() {
    return this.store.findAll('provider');
  },

  actions: {
		showSettings: function(){
			this.transitionTo('adminSiteSettingsCategory', 'plugins', {
				queryParams: { filter: 'chat_integration'}
			});
		}
	}
});
