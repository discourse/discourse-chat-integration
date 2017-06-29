import Rule from 'discourse/plugins/discourse-chat/admin/models/rule'
import { ajax } from 'discourse/lib/ajax';
import computed from "ember-addons/ember-computed-decorators";
import showModal from 'discourse/lib/show-modal';


export default Ember.Controller.extend({
	modalShowing: false,

  actions:{
  	edit(rule){
  		this.set('modalShowing', true);
  		showModal('admin-plugins-chat-edit-rule', { model: rule, admin: true });
  	},

  }

});