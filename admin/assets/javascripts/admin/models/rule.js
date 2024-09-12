import { tracked } from "@glimmer/tracking";
import Category from "discourse/models/category";
import RestModel from "discourse/models/rest";
import I18n from "I18n";

export default class Rule extends RestModel {
  @tracked type = "normal";
  @tracked category_id = null;
  @tracked tags = null;
  @tracked channel_id = null;
  @tracked filter = "watch";
  @tracked error_key = null;

  available_types = [
    { id: "normal", name: I18n.t("chat_integration.type.normal") },
    {
      id: "group_message",
      name: I18n.t("chat_integration.type.group_message"),
    },
    {
      id: "group_mention",
      name: I18n.t("chat_integration.type.group_mention"),
    },
  ];

  get available_filters() {
    const available = [];
    const provider = this.channel.provider;

    if (provider === "slack") {
      available.push({
        id: "thread",
        name: I18n.t("chat_integration.filter.thread"),
        icon: "chevron-right",
      });
    }

    available.push(
      {
        id: "watch",
        name: I18n.t("chat_integration.filter.watch"),
        icon: "exclamation-circle",
      },
      {
        id: "follow",
        name: I18n.t("chat_integration.filter.follow"),
        icon: "circle",
      },
      {
        id: "tag_added",
        name: I18n.t("chat_integration.filter.tag_added"),
        icon: "tag",
      },
      {
        id: "mute",
        name: I18n.t("chat_integration.filter.mute"),
        icon: "times-circle",
      }
    );

    return available;
  }

  get category() {
    const categoryId = this.category_id;

    if (categoryId) {
      return Category.findById(categoryId);
    } else {
      return false;
    }
  }

  get filterName() {
    return I18n.t(`chat_integration.filter.${this.filter}`);
  }

  updateProperties() {
    return this.getProperties([
      "type",
      "category_id",
      "group_id",
      "tags",
      "filter",
    ]);
  }

  createProperties() {
    return this.getProperties([
      "type",
      "channel_id",
      "category_id",
      "group_id",
      "tags",
      "filter",
    ]);
  }
}
