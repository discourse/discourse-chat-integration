import FilterRule from 'discourse/plugins/discourse-chat/admin/models/filter-rule'
import { ajax } from 'discourse/lib/ajax';

export default Discourse.Route.extend({

  model(params, transition) {
    
    var url = '/admin/plugins/chat'
    if(params.provider !== undefined){
      url += `/${params.provider}`
    }
    url += '.json'

    return ajax(url).then(result => {
      var rules = result.rules.map(v => FilterRule.create(v))
      var providers = result.providers
      return {provider: result.provider, rules: rules, providers: providers};
    });
  },

  serialize: function(model, params) {
    return { provider: model['provider']};
  }
});
