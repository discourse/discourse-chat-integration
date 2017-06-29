import Rule from 'discourse/plugins/discourse-chat/admin/models/rule'
import { ajax } from 'discourse/lib/ajax';
import computed from "ember-addons/ember-computed-decorators";
import showModal from 'discourse/lib/show-modal';
import { popupAjaxError } from 'discourse/lib/ajax-error';


export default Ember.Controller.extend({
	modalShowing: false,
	
  actions:{
  	create(provider){
  		this.set('modalShowing', true);
  		showModal('admin-plugins-chat-edit-rule', { model: this.store.createRecord('rule',{provider: provider}), admin: true });
  	},
  	edit(rule){
  		this.set('modalShowing', true);
  		showModal('admin-plugins-chat-edit-rule', { model: rule, admin: true });
  	},
  	delete(rule){
  		const self = this;
  		rule.destroyRecord().then(function() {
        self.send('refresh');
      }).catch(popupAjaxError)
  	},

  }

});