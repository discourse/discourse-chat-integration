import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import DiscourseRoute from "discourse/routes/discourse";
import { next } from "@ember/runloop";

export default DiscourseRoute.extend({
  model(params) {
    if (this.currentUser) {
      const secret = params.secret;

      this.replaceWith("discovery.latest").then((e) => {
        if (this.controllerFor("navigation/default").get("canCreateTopic")) {
          next(() => {
            ajax(`chat-transcript/${secret}`).then((result) => {
              e.send(
                "createNewTopicViaParams",
                null,
                result["content"],
                null,
                null,
                null
              );
            }, popupAjaxError);
          });
        }
      });
    } else {
      this.session.set("shouldRedirectToUrl", window.location.href);
      this.replaceWith("login");
    }
  },
});
