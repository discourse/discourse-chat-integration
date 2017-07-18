import { ajax } from 'discourse/lib/ajax';

export default Discourse.Route.extend({

  model(params, transition) {
    return Ember.RSVP.hash({
      channels: this.store.findAll('channel', {provider: params.provider}),
      provider: this.modelFor("admin-plugins-chat").findBy('id',params.provider)
    }).then(value => {
      value.channels.forEach(channel => {
        channel.set('rules', channel.rules.map(rule => {
          rule = this.store.createRecord('rule', rule);
          rule.channel = channel;
          return rule;
        }));
      });
      return value;
    });
  },

  serialize: function(model, params) {
    return { provider: model['provider'].get('id')};
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
