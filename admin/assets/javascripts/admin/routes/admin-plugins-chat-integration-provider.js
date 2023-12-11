import { action } from "@ember/object";
import RSVP from "rsvp";
import Group from "discourse/models/group";
import DiscourseRoute from "discourse/routes/discourse";

export default class AdminPluginsChatIntegrationProvider extends DiscourseRoute {
  model(params) {
    return RSVP.hash({
      channels: this.store.findAll("channel", { provider: params.provider }),
      provider: this.modelFor("admin-plugins-chat-integration").findBy(
        "id",
        params.provider
      ),
      groups: Group.findAll(),
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
  }

  serialize(model) {
    return { provider: model["provider"].get("id") };
  }

  @action
  refreshProvider() {
    this.refresh();
  }
}
