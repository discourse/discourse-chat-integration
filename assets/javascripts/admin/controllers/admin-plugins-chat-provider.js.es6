import FilterRule from 'discourse/plugins/discourse-chat/admin/models/filter-rule'
import { ajax } from 'discourse/lib/ajax';
import computed from "ember-addons/ember-computed-decorators";
import showModal from 'discourse/lib/show-modal';


export default Ember.Controller.extend({


  actions:{
  	edit(rule){
  		console.log(rule.hasDirtyAttributes);
  		showModal('admin-plugins-chat-edit-rule', { model: rule, admin: true });
  	},
  }

});