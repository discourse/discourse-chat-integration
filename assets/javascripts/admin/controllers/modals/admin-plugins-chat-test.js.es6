import ModalFunctionality from 'discourse/mixins/modal-functionality';
import { ajax } from 'discourse/lib/ajax';

export default Ember.Controller.extend(ModalFunctionality, {
	sendDisabled: function(){
		if(this.get('model').topic_id && this.get('model').channel){
			return false
		}
		return true
	}.property('model.topic_id', 'model.channel'),

	actions: {

		send: function(){
			self = this;
			this.set('loading', true);
			ajax("/admin/plugins/chat/test", {
        data: { provider: this.get('model.provider.name'), 
        				channel: this.get('model.channel'), 
        				topic_id: this.get('model.topic_id') 
        			},
        type: 'POST'
      }).then(function (result) {
        self.set('loading', false)
        self.flash(I18n.t('chat_integration.test_modal.success'), 'success');
      }, function(e) {
      	self.set('loading', false);
      	
      	var response = e.jqXHR.responseJSON
      	var error_key = 'chat_integration.test_modal.error'
      	debugger;
      	if(response['error_key']){
      		error_key = response['error_key']	
        }
        self.flash(I18n.t(error_key), 'error');
        
      });
		}

	}


});