import DiscourseRoute from "discourse/routes/discourse";
import Group from "discourse/models/group";

export default DiscourseRoute.extend({
  model(params) {
    return Ember.RSVP.hash({
      channels: this.store.findAll("channel", { provider: params.provider }),
      provider: this.modelFor("admin-plugins-chat").findBy(
        "id",
        params.provider
      ),
      groups: Group.findAll().then((groups) => {
        return groups.filter((g) => !g.get("automatic"));
      }),
    }).then((value) => {
      value.channels.forEach((channel) => {
        channel.set(
          "rules",
          channel.rules.map((rule) => {
            rule = this.store.createRecord("rule", rule);
            rule.set("channel", channel);
            return rule;
          })
        );
      });

      return value;
    });
  },

  serialize(model) {
    return { provider: model["provider"].get("id") };
  },

  actions: {
    closeModal() {
      if (this.get("controller.modalShowing")) {
        this.refresh();
        this.set("controller.modalShowing", false);
      }

      return true; // Continue bubbling up, so the modal actually closes
    },

    refreshProvider() {
      this.refresh();
    },
  },
});
