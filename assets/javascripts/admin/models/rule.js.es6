import RestModel from 'discourse/models/rest';
import Category from 'discourse/models/category';
import computed from "ember-addons/ember-computed-decorators";

export default RestModel.extend({
  available_filters: [
    { id: 'watch', name: I18n.t('chat_integration.filter.watch'), icon: 'exclamation-circle' },
    { id: 'follow', name: I18n.t('chat_integration.filter.follow'), icon: 'circle'},
    { id: 'mute', name: I18n.t('chat_integration.filter.mute'), icon: 'times-circle' }
  ],

  available_types: [
    { id: 'normal', name: I18n.t('chat_integration.type.normal')},
    { id: 'group_message', name: I18n.t('chat_integration.type.group_message')},
    { id: 'group_mention', name: I18n.t('chat_integration.type.group_mention')}
  ],

  category_id: null,
  tags: null,
  channel_id: null,
  filter: 'watch',
  type: 'normal',
  error_key: null,

  
  removeUnneededInfo: function(){
    const type=this.get('type');
    if(type=='normal'){
      this.set('group_id', null);
    }else{
      this.set('category_id', null);
    }
  }.observes('type'),

  @computed('category_id')
  category(categoryId) {
    if (categoryId){
      return Category.findById(categoryId);
    }else {
      return false;
    }
  },

  @computed('filter')
  filterName(filter) {
    return I18n.t(`chat_integration.filter.${filter}`);
  },

  updateProperties() {
    var prop_names = ['type','category_id','group_id','tags','filter'];
    return this.getProperties(prop_names);
  },

  createProperties() {
    var prop_names = ['type','channel_id', 'category_id','group_id','tags','filter'];
    return this.getProperties(prop_names);
  }

});
