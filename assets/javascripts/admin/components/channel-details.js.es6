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
          }).catch(popupAjaxError);
        }
      });
    },

    edit(channel){
      this.sendAction('edit', channel);
    },

    test(channel){
      this.sendAction('test', channel);
    },

    createRule(channel){
      this.sendAction('createRule', channel);
    },

    editRule(rule){
      this.sendAction('editRule', rule, this.get('channel'));
    },

    showError(error_key){
      bootbox.alert(I18n.t(error_key));
    },

  }
});