import { ajax } from 'discourse/lib/ajax';

export default Discourse.Route.extend({
  model() {
    return ajax("/chat/list-integrations.json").then(result => {
      return result.chat;
    });
  }
});
