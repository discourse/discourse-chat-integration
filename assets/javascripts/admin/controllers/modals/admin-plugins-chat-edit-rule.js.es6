import Rule from 'discourse/plugins/discourse-chat-integration/admin/models/rule'
import ModalFunctionality from 'discourse/mixins/modal-functionality';
import { ajax } from 'discourse/lib/ajax';
import { extractError } from 'discourse/lib/ajax-error';
import InputValidation from 'discourse/models/input-validation';
import computed from "ember-addons/ember-computed-decorators";

export default Ember.Controller.extend(ModalFunctionality, {
  setupKeydown: function() {
    Ember.run.schedule('afterRender', () => {
      $('#chat_integration_edit_channel_modal').keydown(e => {
        if (e.keyCode === 13) {
          this.send('save');
        }
      });
    });
  }.on('init'),

  saveDisabled: function(){
    return false;
  }.property(),

  @computed('model.rule.type')
  showCategory: function(type){
    return (type == "normal")
  },

  actions: {
    cancel: function(){
      this.send('closeModal');
    },

    save: function(){
      if(this.get('saveDisabled')){return};

    	const self = this;

    	this.get('model.rule').save().then(function(result) {
        self.send('closeModal');
      }).catch(function(error) {
        self.flash(extractError(error), 'error');
      });

    }
  }
});