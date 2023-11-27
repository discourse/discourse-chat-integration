import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import DiscourseRoute from "discourse/routes/discourse";
import { inject as service } from "@ember/service";

export default class Trascript extends DiscourseRoute {
  @service currentUser;
  @service composer;
  @service router;

  async model(params) {
    if (!this.currentUser) {
      this.session.set("shouldRedirectToUrl", window.location.href);
      this.router.replaceWith("login");
      return;
    }

    const secret = params.secret;

    await this.router.replaceWith("discovery.latest").followRedirects();

    try {
      const result = await ajax(`chat-transcript/${secret}`);
      this.composer.openNewTopic({
        body: result.content,
      });
    } catch (e) {
      popupAjaxError(e);
    }
  }
}
