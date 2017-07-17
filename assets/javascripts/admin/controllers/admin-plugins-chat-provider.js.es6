import Rule from 'discourse/plugins/discourse-chat-integration/admin/models/rule'
import { ajax } from 'discourse/lib/ajax';
import computed from "ember-addons/ember-computed-decorators";
import showModal from 'discourse/lib/show-modal';
import { popupAjaxError } from 'discourse/lib/ajax-error';


export default Ember.Controller.extend({
	modalShowing: false,
	
  anyErrors: function(){
    var anyErrors = false;
    this.get('model.rules').forEach(function(rule){
      if(rule.error_key){
        anyErrors = true;
      }
    });
    return anyErrors;
  }.property('model.rules'),

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
    showError(error_key){
      bootbox.alert(I18n.t(error_key));
    },
    test(){
      this.set('modalShowing', true);
      var model = {provider:this.get('model.provider'), channel:''}
      showModal('admin-plugins-chat-test', { model: model, admin: true });
    }

  }

});