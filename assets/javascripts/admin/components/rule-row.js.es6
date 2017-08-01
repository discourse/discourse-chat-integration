import { popupAjaxError } from 'discourse/lib/ajax-error';

export default Ember.Component.extend({
  tagName: 'tr',

  isCategory: function(){
    return this.get('rule.type') == 'normal'
  }.property('rule.type'),

  isMessage: function(){
    return this.get('rule.type') == 'group_message'
  }.property('rule.type'),

  isMention: function(){
    return this.get('rule.type') == 'group_mention'
  }.property('rule.type'),

  actions: {
    edit: function(){
      this.sendAction('edit', this.get('rule'))
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