import ModalFunctionality from 'discourse/mixins/modal-functionality';
import { ajax } from 'discourse/lib/ajax';

export default Ember.Controller.extend(ModalFunctionality, {
  setupKeydown: function() {
    Ember.run.schedule('afterRender', () => {
      $('#chat_integration_test_modal').keydown(e => {
        if (e.keyCode === 13) {
          this.send('send');
        }
      });
    });
  }.on('init'),

  sendDisabled: function(){
    if(this.get('model').topic_id){
      return false;
    }
    return true;
  }.property('model.topic_id'),

  actions: {

    send: function(){
      if(this.get('sendDisabled')){return;};
      self = this;
      this.set('loading', true);
      ajax("/admin/plugins/chat/test", {
        data: { channel_id: this.get('model.channel.id'),
                topic_id: this.get('model.topic_id')
              },
        type: 'POST'
      }).then(function () {
        self.set('loading', false);
        self.flash(I18n.t('chat_integration.test_modal.success'), 'success');
      }, function(e) {
        self.set('loading', false);

        var response = e.jqXHR.responseJSON;
        var error_key = 'chat_integration.test_modal.error';

        if(response['error_key']){
          error_key = response['error_key'];
        }
        self.flash(I18n.t(error_key), 'error');

      });
    }

  }


});