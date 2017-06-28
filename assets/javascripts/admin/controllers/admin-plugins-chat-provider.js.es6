import FilterRule from 'discourse/plugins/discourse-chat/admin/models/filter-rule'
import { ajax } from 'discourse/lib/ajax';
import computed from "ember-addons/ember-computed-decorators";

export default Ember.Controller.extend({
	filters: [
    { id: 'watch', name: I18n.t('chat.filter.watch'), icon: 'exclamation-circle' },
    { id: 'follow', name: I18n.t('chat.filter.follow'), icon: 'circle'},
    { id: 'mute', name: I18n.t('chat.filter.mute'), icon: 'times-circle' }
  ],

  editing: FilterRule.create({}),

});