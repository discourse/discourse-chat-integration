import { ajax } from 'discourse/lib/ajax';

export default Discourse.Route.extend({
  model() {
    return ajax("/chat/list-providers.json").then(result => {
      return result.chat;
    });
  }
});
