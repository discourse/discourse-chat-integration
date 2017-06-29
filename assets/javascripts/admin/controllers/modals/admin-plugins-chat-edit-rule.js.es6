import Rule from 'discourse/plugins/discourse-chat/admin/models/rule'
import ModalFunctionality from 'discourse/mixins/modal-functionality';
import { ajax } from 'discourse/lib/ajax';
import { extractError } from 'discourse/lib/ajax-error';

export default Ember.Controller.extend(ModalFunctionality, {

  model: Rule.create({}),

  actions: {
    cancel: function(){
      this.send('closeModal');
    },

    save: function(){

    	const self = this;

    	this.get('model').update().then(function(result) {
        self.send('closeModal');
        if (result.responseJson.success) {
          self.transitionToRoute('tags.show', result.responseJson.tag.id);
        } else {
          self.flash(extractError(result.responseJson.errors[0]), 'error');
        }
      }).catch(function(error) {
        self.flash(extractError(error), 'error');
      });

    }
  }
});