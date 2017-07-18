import RestModel from 'discourse/models/rest';

export default RestModel.extend({

  updateProperties() {
    var prop_names = ['data'];
    return this.getProperties(prop_names);
  },

  createProperties() {
    var prop_names = ['provider','data'];
    return this.getProperties(prop_names);
  }
});
