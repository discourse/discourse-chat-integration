import Rule from 'discourse/plugins/discourse-chat-integration/admin/models/rule'
import { ajax } from 'discourse/lib/ajax';

export default Discourse.Route.extend({

  model(params, transition) {
    return Ember.RSVP.hash({
      rules: this.store.find('rule', {provider: params.provider}),
      provider: params.provider
    });
  },

  serialize: function(model, params) {
    return { provider: model['provider']};
  },

  actions: {
    closeModal: function(data){
      if(this.get('controller.modalShowing')){
        this.refresh();
        this.set('controller.modalShowing', false);
      }

      return true; // Continue bubbling up, so the modal actually closes
    },

    refresh: function(data){
      this.refresh();
    }

  }
});
