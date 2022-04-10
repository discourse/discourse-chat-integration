import {
  acceptance,
  exists,
  query,
  queryAll,
} from "discourse/tests/helpers/qunit-helpers";
import { test } from "qunit";
import { click, fillIn, triggerKeyEvent, visit } from "@ember/test-helpers";

const response = (object) => {
  return [200, { "Content-Type": "text/html; charset=utf-8" }, object];
};

const jsonResponse = (object) => {
  return [200, { "Content-Type": "application/json; charset=utf-8" }, object];
};

acceptance("Chat Integration", function (needs) {
  needs.user();

  needs.pretender((server) => {
    server.get("/admin/plugins/chat-integration/providers", () => {
      return jsonResponse({
        providers: [
          {
            name: "dummy",
            id: "dummy",
            channel_parameters: [{ key: "somekey", regex: "^\\S+$" }],
          },
        ],
      });
    });

    server.get("/admin/plugins/chat-integration/channels", () => {
      return jsonResponse({
        channels: [
          {
            id: 97,
            provider: "dummy",
            data: { somekey: "#general" },
            rules: [
              {
                id: 98,
                channel_id: 97,
                category_id: null,
                team_id: null,
                type: "normal",
                tags: [],
                filter: "watch",
                new_topic_prefix: "New topic test.",
                new_reply_prefix: "New reply test.",
                error_key: null,
              },
            ],
          },
        ],
      });
    });

    server.post("/admin/plugins/chat-integration/channels", () => {
      return response({});
    });

    server.put("/admin/plugins/chat-integration/channels/:id", () => {
      return response({});
    });

    server.delete("/admin/plugins/chat-integration/channels/:id", () => {
      return response({});
    });

    server.post("/admin/plugins/chat-integration/rules", () => {
      return response({});
    });

    server.put("/admin/plugins/chat-integration/rules/:id", () => {
      return response({});
    });

    server.delete("/admin/plugins/chat-integration/rules/:id", () => {
      return response({});
    });

    server.post("/admin/plugins/chat-integration/test", () => {
      return response({});
    });

    server.get("/groups/search.json", () => {
      return jsonResponse([]);
    });
  });

  test("Rules load successfully", async function (assert) {
    await visit("/admin/plugins/chat-integration");

    assert.ok(
      exists("#admin-plugin-chat table"),
      "it shows the table of rules"
    );

    assert.strictEqual(
      queryAll("#admin-plugin-chat table tr td")[0].innerText.trim(),
      "All posts and replies",
      "rule displayed"
    );
  });

  test("Create channel works", async function (assert) {
    await visit("/admin/plugins/chat-integration");
    await click("#create-channel");

    assert.ok(
      exists("#chat-integration-edit-channel-modal"),
      "it displays the modal"
    );
    assert.ok(query("#save-channel").disabled, "it disables the save button");

    await fillIn("#chat-integration-edit-channel-modal input", "#general");

    assert.notOk(query("#save-channel").disabled, "it enables the save button");

    await click("#save-channel");

    assert.notOk(
      exists("#chat-integration-edit-channel-modal"),
      "modal closes on save"
    );
  });

  test("Edit channel works", async function (assert) {
    await visit("/admin/plugins/chat-integration");
    await click(".channel-header button");

    assert.ok(
      exists("#chat-integration-edit-channel-modal"),
      "it displays the modal"
    );
    assert.notOk(query("#save-channel").disabled, "save is enabled");

    await fillIn("#chat-integration-edit-channel-modal input", " general");

    assert.ok(query("#save-channel").disabled, "it disables the save button");

    await fillIn("#chat-integration-edit-channel-modal input", "#random");

    // Press enter
    await triggerKeyEvent(
      "#chat-integration-edit-channel-modal input",
      "keydown",
      13
    );

    assert.notOk(
      exists("#chat-integration-edit-channel-modal"),
      "modal saves on enter"
    );
  });

  test("Create rule works", async function (assert) {
    await visit("/admin/plugins/chat-integration");

    assert.ok(exists(".channel-footer button"), "create button is displayed");

    await click(".channel-footer button");

    assert.ok(
      exists("#chat-integration-edit-rule_modal"),
      "modal opens on edit"
    );
    assert.notOk(query("#save-rule").disabled, "save is enabled");

    await click("#save-rule");

    assert.notOk(
      exists("#chat-integration-edit-rule_modal"),
      "modal closes on save"
    );
  });

  test("Edit rule works", async function (assert) {
    await visit("/admin/plugins/chat-integration");

    assert.ok(exists(".edit"), "edit button is displayed");

    await click(".edit");

    assert.ok(
      exists("#chat-integration-edit-rule_modal"),
      "modal opens on edit"
    );
    assert.notOk(query("#save-rule").disabled, "it enables the save button");

    await click("#save-rule");

    assert.notOk(
      exists("#chat-integration-edit-rule_modal"),
      "modal closes on save"
    );
  });

  test("Delete channel works", async function (assert) {
    await visit("/admin/plugins/chat-integration");

    assert.ok(
      exists(".channel-header .delete-channel"),
      "delete buttons exists"
    );
    await click(".channel-header .delete-channel");

    assert.ok(exists("div.bootbox"), "modal is displayed");
    await click("div.bootbox .btn-primary");

    assert.notOk(exists("div.bootbox"), "modal has closed");
  });

  test("Delete rule works", async function (assert) {
    await visit("/admin/plugins/chat-integration");

    assert.ok(exists(".delete"));
    await click(".delete");
  });

  test("Test channel works", async function (assert) {
    await visit("/admin/plugins/chat-integration");

    await click(".btn-chat-test");

    assert.ok(exists("#chat_integration_test_modal"), "it displays the modal");
    assert.ok(query("#send-test").disabled, "it disables the send button");

    await fillIn("#choose-topic-title", "9318");
    await click("#chat_integration_test_modal .radio");

    assert.notOk(query("#send-test").disabled, "it enables the send button");

    await click("#send-test");

    assert.ok(
      exists("#chat_integration_test_modal"),
      "modal doesn't close on send"
    );
    assert.ok(
      exists("#modal-alert.alert-success"),
      "success message displayed"
    );
  });
});
