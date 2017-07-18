import { popupAjaxError } from 'discourse/lib/ajax-error';

export default Ember.Component.extend({
  classNames: ['channel-details'],
  actions: {
    refresh: function(){
      this.sendAction('refresh');
    },

    delete(channel){
      bootbox.confirm(I18n.t("chat_integration.channel_delete_confirm"), I18n.t("no_value"), I18n.t("yes_value"), result => {
        if (result) {
          channel.destroyRecord().then(() => {
            this.send('refresh');
          }).catch(popupAjaxError)
        }
      });
    },

    edit(channel){
      this.sendAction('edit', channel)
    },

    test(channel){
      this.sendAction('test', channel)
    },

    createRule(channel){
      var newRule = this.get('store').createRecord('rule',{channel_id: channel.id});
      channel.rules.pushObject(newRule)
    },

    showError(error_key){
      bootbox.alert(I18n.t(error_key));
    },

  }
});