import { popupAjaxError } from 'discourse/lib/ajax-error';

export default Ember.Component.extend({
  tagName: 'tr',
  editing: false,

  autoEdit: function(){
    if(!this.get('rule').id){
      this.set('editing', true);
    }
  }.on('init'),

  actions: {
    edit: function(){
      this.set('editing', true);
    },

    cancel: function(){
      this.send('refresh');
    },

    save: function(){
      this.get('rule').save().then(result => {
        this.send('refresh');
      }).catch(popupAjaxError);
    },

    delete(rule){
      rule.destroyRecord().then(() => {
        this.send('refresh');
      }).catch(popupAjaxError)
    },

    refresh: function(){
      this.sendAction('refresh');
    }
  }
});