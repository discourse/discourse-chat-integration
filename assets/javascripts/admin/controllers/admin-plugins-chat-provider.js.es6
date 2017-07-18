import Rule from 'discourse/plugins/discourse-chat-integration/admin/models/rule'
import { ajax } from 'discourse/lib/ajax';
import computed from "ember-addons/ember-computed-decorators";
import showModal from 'discourse/lib/show-modal';
import { popupAjaxError } from 'discourse/lib/ajax-error';


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
      var model = {channel:channel}
      showModal('admin-plugins-chat-test', { model: model, admin: true });
    },
    showError(error_key){
      bootbox.alert(I18n.t(error_key));
    },



  }

});