import Controller from "@ember/controller";
import I18n from "I18n";
import ModalFunctionality from "discourse/mixins/modal-functionality";
import { popupAjaxError } from "discourse/lib/ajax-error";
import EmberObject, {
  defineProperty,
  computed as emberComputed,
} from "@ember/object";
import computed, { observes, on } from "discourse-common/utils/decorators";
import { schedule } from "@ember/runloop";

export default Controller.extend(ModalFunctionality, {
  @on("init")
  setupKeydown() {
    schedule("afterRender", () => {
      $("#chat-integration-edit-channel-modal").keydown((e) => {
        if (e.keyCode === 13) {
          this.send("save");
        }
      });
    });
  },

  // The validation property must be defined at runtime since the possible parameters vary by provider
  @observes("model")
  setupValidations() {
    if (this.get("model.provider")) {
      const theKeys = this.get("model.provider.channel_parameters").map(
        (param) => param["key"]
      );
      defineProperty(
        this,
        "paramValidation",
        emberComputed(
          `model.channel.data.{${theKeys.join(",")}}`,
          this._paramValidation
        )
      );
      this.notifyPropertyChange("paramValidation");
    }
  },

  validate(parameter) {
    const regString = parameter.regex;
    const regex = new RegExp(regString);
    let val = this.get(`model.channel.data.${parameter.key}`);

    if (val === undefined) {
      val = "";
    }

    if (val === "") {
      // Fail silently if field blank
      return EmberObject.create({
        failed: true,
      });
    } else if (!regString) {
      // Pass silently if no regex available for provider
      return EmberObject.create({
        ok: true,
      });
    } else if (regex.test(val)) {
      // Test against regex
      return EmberObject.create({
        ok: true,
        reason: I18n.t(
          "chat_integration.edit_channel_modal.channel_validation.ok"
        ),
      });
    } else {
      // Failed regex
      return EmberObject.create({
        failed: true,
        reason: I18n.t(
          "chat_integration.edit_channel_modal.channel_validation.fail"
        ),
      });
    }
  },

  _paramValidation() {
    const response = {};
    const parameters = this.get("model.provider.channel_parameters");

    parameters.forEach((parameter) => {
      response[parameter.key] = this.validate(parameter);
    });

    return response;
  },

  @computed("paramValidation")
  saveDisabled(paramValidation) {
    if (!paramValidation) {
      return true;
    }

    let invalid = false;

    Object.keys(paramValidation).forEach((key) => {
      if (!paramValidation[key]) {
        invalid = true;
      }

      if (!paramValidation[key]["ok"]) {
        invalid = true;
      }
    });

    return invalid;
  },

  actions: {
    cancel() {
      this.send("closeModal");
    },

    save() {
      if (this.get("saveDisabled")) {
        return;
      }

      this.get("model.channel")
        .save()
        .then(() => {
          this.send("closeModal");
        })
        .catch(popupAjaxError);
    },
  },
});
