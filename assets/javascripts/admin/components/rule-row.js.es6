import { popupAjaxError } from 'discourse/lib/ajax-error';

export default Ember.Component.extend({
  tagName: 'tr',

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