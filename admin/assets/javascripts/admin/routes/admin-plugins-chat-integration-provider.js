import { action } from "@ember/object";
import Group from "discourse/models/group";
import DiscourseRoute from "discourse/routes/discourse";

export default class AdminPluginsChatIntegrationProvider extends DiscourseRoute {
  async model(params) {
    const [channels, provider, groups] = await Promise.all([
      this.store.findAll("channel", { provider: params.provider }),
      this.modelFor("admin-plugins-chat-integration").findBy(
        "id",
        params.provider
      ),
      Group.findAll(),
    ]);

    channels.forEach((channel) => {
      channel.set(
        "rules",
        channel.rules.map((rule) => {
          rule = this.store.createRecord("rule", rule);
          rule.set("channel", channel);
          return rule;
        })
      );
    });

    return {
      channels,
      provider,
      groups,
    };
  }

  serialize(model) {
    return { provider: model.provider.id };
  }

  @action
  refreshProvider() {
    this.refresh();
  }
}
