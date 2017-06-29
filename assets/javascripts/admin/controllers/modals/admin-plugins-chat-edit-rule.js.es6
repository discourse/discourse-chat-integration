import Rule from 'discourse/plugins/discourse-chat/admin/models/rule'
import { ajax } from 'discourse/lib/ajax';

export default Ember.Controller.extend({

  model: Rule.create({}),

  actions: {
    cancel: function(){

      this.send('closeModal');
    },
  }
});