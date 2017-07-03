import AdminPluginsChatProvider from 'discourse/plugins/discourse-chat-integration/admin/routes/admin-plugins-chat-provider'

export default Discourse.Route.extend({
	afterModel(model, transition) {
		
		if(model.totalRows > 0){
			this.transitionTo('adminPlugins.chat.provider', model.get('firstObject').name);
		}
  }
});
