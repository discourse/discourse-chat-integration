import AdminPluginsChatProvider from 'discourse/plugins/discourse-chat-integration/admin/routes/admin-plugins-chat-provider'

export default Discourse.Route.extend({
	model(params, transition) {
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
