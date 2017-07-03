import Rule from 'discourse/plugins/discourse-chat-integration/admin/models/rule'
import { ajax } from 'discourse/lib/ajax';
import computed from "ember-addons/ember-computed-decorators";
import showModal from 'discourse/lib/show-modal';
import { popupAjaxError } from 'discourse/lib/ajax-error';


export default Ember.Controller.extend({
	modalShowing: false,
	
  actions:{
  	create(){
  		this.set('modalShowing', true);
      var model = {rule: this.store.createRecord('rule',{provider: this.get('model.provider').id}), provider:this.get('model.provider')};
  		showModal('admin-plugins-chat-edit-rule', { model: model, admin: true });
  	},
  	edit(rule){
  		this.set('modalShowing', true);
      var model = {rule: rule, provider:this.get('model.provider')};
  		showModal('admin-plugins-chat-edit-rule', { model: model, admin: true });
  	},
  	delete(rule){
  		const self = this;
  		rule.destroyRecord().then(function() {
        self.send('refresh');
      }).catch(popupAjaxError)
  	},

  }

});