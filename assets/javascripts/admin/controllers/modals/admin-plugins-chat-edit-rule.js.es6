import FilterRule from 'discourse/plugins/discourse-chat/admin/models/filter-rule'
import { ajax } from 'discourse/lib/ajax';

export default Ember.Controller.extend({

  model: FilterRule.create({}),
  
  actions: {
    cancel: function(){
      this.set('model', null);
      this.set('workingCopy', null);
      this.send('closeModal');
    },
  }
});