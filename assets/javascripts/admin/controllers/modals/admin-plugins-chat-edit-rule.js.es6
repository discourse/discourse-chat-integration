import ModalFunctionality from 'discourse/mixins/modal-functionality';
import { popupAjaxError } from 'discourse/lib/ajax-error';
import computed from "ember-addons/ember-computed-decorators";

export default Ember.Controller.extend(ModalFunctionality, {
  saveDisabled: false,

  setupKeydown() {
    Ember.run.schedule('afterRender', () => {
      $('#chat_integration_edit_channel_modal').keydown(e => {
        if (e.keyCode === 13) {
          this.send('save');
        }
      });
    });
  }.on('init'),

  @computed('model.rule.type')
  showCategory(type) {
    return type === "normal";
  },

  actions: {
    cancel() {
      this.send('closeModal');
    },

    save() {
      if (this.get('saveDisabled')) return;

      this.get('model.rule').save().then(() => {
        this.send('closeModal');
      }).catch(popupAjaxError);
    }
  }
});
