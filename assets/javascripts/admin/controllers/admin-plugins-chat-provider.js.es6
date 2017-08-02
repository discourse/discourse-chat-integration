import showModal from 'discourse/lib/show-modal';

export default Ember.Controller.extend({
	modalShowing: false,

  anyErrors: function(){
    var anyErrors = false;
    this.get('model.channels').forEach(function(channel){
      if(channel.error_key){
        anyErrors = true;
      }
    });
    return anyErrors;
  }.property('model.channels'),

  actions:{
  	createChannel(){
  		this.set('modalShowing', true);
      var model = {channel: this.store.createRecord('channel',{provider: this.get('model.provider').id, data:{}},), provider:this.get('model.provider')};
  		showModal('admin-plugins-chat-edit-channel', { model: model, admin: true });
  	},
  	editChannel(channel){
  		this.set('modalShowing', true);
      var model = {channel: channel, provider: this.get('model.provider')};
  		showModal('admin-plugins-chat-edit-channel', { model: model, admin: true });
  	},
    testChannel(channel){
      this.set('modalShowing', true);
      var model = {channel:channel};
      showModal('admin-plugins-chat-test', { model: model, admin: true });
    },

    createRule(channel){
      this.set('modalShowing', true);
      var model = {rule: this.store.createRecord('rule',{channel_id: channel.id}), channel:channel, provider:this.get('model.provider'), groups:this.get('model.groups')};
      showModal('admin-plugins-chat-edit-rule', { model: model, admin: true });
    },
    editRule(rule, channel){
      this.set('modalShowing', true);
      var model = {rule: rule, channel:channel, provider:this.get('model.provider'), groups:this.get('model.groups')};
      showModal('admin-plugins-chat-edit-rule', { model: model, admin: true });
    },

  }

});