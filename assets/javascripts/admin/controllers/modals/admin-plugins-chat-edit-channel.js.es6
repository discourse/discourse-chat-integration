import Rule from 'discourse/plugins/discourse-chat-integration/admin/models/rule'
import ModalFunctionality from 'discourse/mixins/modal-functionality';
import { ajax } from 'discourse/lib/ajax';
import { extractError } from 'discourse/lib/ajax-error';
import InputValidation from 'discourse/models/input-validation';

export default Ember.Controller.extend(ModalFunctionality, {

  initThing: function(){
    console.log("Initialising controller");
    console.log(this.get('model.data'));
  }.on('init'),

  // The validation property must be defined at runtime since the possible parameters vary by provider
  setupValidations: function(){
    if(this.get('model.provider')){
      var theKeys = this.get('model.provider.channel_parameters').map( ( param ) => param['key'] );
      Ember.defineProperty(this,'paramValidation',Ember.computed('model.channel.data.{' + theKeys.join(',') + '}',this._paramValidation));
    }
  }.observes('model'),

  validate(parameter){
    var regString = parameter.regex;
    var regex = new RegExp(regString);
    var val = this.get('model.channel.data.'+parameter.key);

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
        reason: I18n.t('chat_integration.edit_channel_modal.channel_validation.ok')
      });
    }else{ // Failed regex
      return InputValidation.create({
        failed: true,
        reason: I18n.t('chat_integration.edit_channel_modal.channel_validation.fail')
      });
    }

  },

  _paramValidation: function(){
    var response = {}
    var parameters = this.get('model.provider.channel_parameters');
    parameters.forEach(parameter => {
      response[parameter.key] = this.validate(parameter);
    });
    return response;
  },

  saveDisabled: function(){
    var validations = this.get('paramValidation');
    
    if(!validations){ return true }

    var invalid = false;

    Object.keys(validations).forEach(key =>{
      if(!validations[key]){
        invalid = true;
      }
      if(!validations[key]['ok']){
       invalid = true;
      }
    });
      
    return invalid;
  }.property('paramValidation'),

  actions: {
    cancel: function(){
      this.send('closeModal');
    },

    save: function(){

    	const self = this;

    	this.get('model.channel').save().then(function(result) {
        self.send('closeModal');
      }).catch(function(error) {
        self.flash(extractError(error), 'error');
      });

    }
  }
});