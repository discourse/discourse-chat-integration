import { acceptance } from "discourse/tests/helpers/qunit-helpers";

acceptance("Chat Integration", function (needs) {
  needs.user();

  needs.pretender((server) => {
    const response = (object) => {
      return [200, { "Content-Type": "text/html; charset=utf-8" }, object];
    };

    const jsonResponse = (object) => {
      return [
        200,
        { "Content-Type": "application/json; charset=utf-8" },
        object,
      ];
    };

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

  test("Rules load successfully", async (assert) => {
    await visit("/admin/plugins/chat-integration");

    assert.ok(
      exists("#admin-plugin-chat table"),
      "it shows the table of rules"
    );

    assert.equal(
      find("#admin-plugin-chat table tr td").eq(0).text().trim(),
      "All posts and replies",
      "rule displayed"
    );
  });

  test("Create channel works", async (assert) => {
    await visit("/admin/plugins/chat-integration");
    await click("#create-channel");

    assert.ok(
      exists("#chat-integration-edit-channel-modal"),
      "it displays the modal"
    );
    assert.ok(
      find("#save-channel").prop("disabled"),
      "it disables the save button"
    );

    await fillIn("#chat-integration-edit-channel-modal input", "#general");

    assert.ok(
      find("#save-channel").prop("disabled") === false,
      "it enables the save button"
    );

    await click("#save-channel");

    assert.ok(
      !exists("#chat-integration-edit-channel-modal"),
      "modal closes on save"
    );
  });

  test("Edit channel works", async (assert) => {
    await visit("/admin/plugins/chat-integration");
    await click(".channel-header button:first");

    assert.ok(
      exists("#chat-integration-edit-channel-modal"),
      "it displays the modal"
    );
    assert.ok(!find("#save-channel").prop("disabled"), "save is enabled");

    await fillIn("#chat-integration-edit-channel-modal input", " general");

    assert.ok(
      find("#save-channel").prop("disabled"),
      "it disables the save button"
    );

    await fillIn("#chat-integration-edit-channel-modal input", "#random");

    andThen(() => {
      $("#chat-integration-edit-channel-modal input").trigger(
        $.Event("keydown", { keyCode: 13 })
      ); // Press enter
    });

    andThen(() => {
      assert.ok(
        !exists("#chat-integration-edit-channel-modal"),
        "modal saves on enter"
      );
    });
  });

  test("Create rule works", async (assert) => {
    await visit("/admin/plugins/chat-integration");

    assert.ok(
      exists(".channel-footer button:first"),
      "create button is displayed"
    );

    await click(".channel-footer button:first");

    assert.ok(
      exists("#chat-integration-edit-rule_modal"),
      "modal opens on edit"
    );
    assert.ok(find("#save-rule").prop("disabled") === false, "save is enabled");

    await click("#save-rule");

    assert.ok(
      !exists("#chat-integration-edit-rule_modal"),
      "modal closes on save"
    );
  });

  test("Edit rule works", async (assert) => {
    await visit("/admin/plugins/chat-integration");

    assert.ok(exists(".edit:first"), "edit button is displayed");

    await click(".edit:first");

    assert.ok(
      exists("#chat-integration-edit-rule_modal"),
      "modal opens on edit"
    );
    assert.ok(
      find("#save-rule").prop("disabled") === false,
      "it enables the save button"
    );

    await click("#save-rule");

    assert.ok(
      !exists("#chat-integration-edit-rule_modal"),
      "modal closes on save"
    );
  });

  test("Delete channel works", async (assert) => {
    await visit("/admin/plugins/chat-integration");

    assert.ok(exists(".channel-header button:last"), "delete button exists");
    await click(".channel-header button:last");

    assert.ok(exists("div.bootbox"), "modal is displayed");
    await click("div.bootbox .btn-primary");

    assert.ok(exists("div.bootbox") === false, "modal has closed");
  });

  test("Delete rule works", async (assert) => {
    await visit("/admin/plugins/chat-integration");

    assert.ok(exists(".delete:first"));
    await click(".delete:first");
  });

  test("Test channel works", async (assert) => {
    await visit("/admin/plugins/chat-integration");

    await click(".btn-chat-test");

    assert.ok(exists("#chat_integration_test_modal"), "it displays the modal");
    assert.ok(
      find("#send-test").prop("disabled"),
      "it disables the send button"
    );

    await fillIn("#choose-topic-title", "9318");
    await click("#chat_integration_test_modal .radio:first");

    assert.ok(
      find("#send-test").prop("disabled") === false,
      "it enables the send button"
    );

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
