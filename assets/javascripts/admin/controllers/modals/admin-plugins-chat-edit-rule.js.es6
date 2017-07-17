import Rule from 'discourse/plugins/discourse-chat-integration/admin/models/rule'
import ModalFunctionality from 'discourse/mixins/modal-functionality';
import { ajax } from 'discourse/lib/ajax';
import { extractError } from 'discourse/lib/ajax-error';
import InputValidation from 'discourse/models/input-validation';

export default Ember.Controller.extend(ModalFunctionality, {

  model: Rule.create({}),

  channelValidation: function(){

    var regString = this.get('model.provider.channel_regex');
    var regex = new RegExp(regString);
    var val = this.get('model.rule.channel');

    if(val == ""){ // Fail silently if field blank
      return InputValidation.create({
        failed: true,
      });
    }else if(!regString){ // Pass silently if no regex available for provider
      return InputValidation.create({
        ok: true,
      });
    }else if(regex.test(val)){ // Test against regex
      return InputValidation.create({
        ok: true,
        reason: I18n.t('chat_integration.edit_rule_modal.channel_validation.ok')
      });
    }else{ // Failed regex
      return InputValidation.create({
        failed: true,
        reason: I18n.t('chat_integration.edit_rule_modal.channel_validation.fail')
      });
    }
  }.property('model.rule.channel'),

  saveDisabled: function(){
    if(this.get('channelValidation.failed')){ return true }
      
    return false;
  }.property('channelValidation.failed'),

  actions: {
    cancel: function(){
      this.send('closeModal');
    },

    save: function(){

    	const self = this;

    	this.get('model.rule').update().then(function(result) {
        self.send('closeModal');
      }).catch(function(error) {
        self.flash(extractError(error), 'error');
      });

    }
  }
});