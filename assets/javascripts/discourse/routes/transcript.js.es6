import { ajax } from 'discourse/lib/ajax';
import { popupAjaxError } from 'discourse/lib/ajax-error';

export default Discourse.Route.extend({
  beforeModel: function(transition) {

    if (Discourse.User.current()) {
      var secret = transition.params.transcript.secret;
      // User is logged in
      this.replaceWith('discovery.latest').then(e => {
        if (this.controllerFor('navigation/default').get('canCreateTopic')) {
          // User can create topic
          Ember.run.next(() => {
            ajax("/chat-transcript/"+secret).then(result => {
              e.send('createNewTopicViaParams', null, result['content'], null, null, null);
            }, popupAjaxError);
          });
        }
      });
    } else {
      // User is not logged in
      this.session.set("shouldRedirectToUrl", window.location.href);
      this.replaceWith('login');
    }
  }
});