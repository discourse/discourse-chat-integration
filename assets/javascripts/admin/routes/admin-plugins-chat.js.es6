import AdminPluginsChatProvider from 'discourse/plugins/discourse-chat/admin/routes/admin-plugins-chat-provider'

export default Discourse.Route.extend({
	model(params, transition) {    
    return this.store.findAll('provider');
  }
});
