import { acceptance } from "helpers/qunit-helpers";
acceptance("Chat Integration", { 
  loggedIn: true,

  beforeEach() {
    const response = (object) => {
      return [
        200,
        {"Content-Type": "text/html; charset=utf-8"},
        object
      ];
    };
    server.get('/admin/plugins/chat/providers', () => {
      return response({ providers: [{name: 'dummy', id:'dummy',channel_regex:null}] });
    });
    server.get('/admin/plugins/chat/rules', () => {
      return response({ rules: [{"id":11,"provider":"dummy","channel":"#general","category_id":2,"tags":null,"filter":"follow","error_key":null}] });
    });
    server.put('/admin/plugins/chat/rules', () => {
      return response({ });
    });
    server.put('/admin/plugins/chat/rules/:id', () => {
      return response({ });
    });
    server.delete('/admin/plugins/chat/rules/:id', () => {
      return response({ });
    });
    server.post('/admin/plugins/chat/test', () => {
      return response({ });
    });

  }

});

test("Rules load successfully", assert => {
  visit("/admin/plugins/chat");

  andThen(() => {
    assert.ok(exists('#admin-plugin-chat table'), "it shows the table of rules");
    assert.equal(find('#admin-plugin-chat table tr td').eq(0).text().trim(), '#general', 'rule displayed');
  });
});

test("Create rule works", assert => {
  visit("/admin/plugins/chat");

  andThen(() => {
    click('#create_rule');
  });

  andThen(() => {
    assert.ok(exists('#chat_integration_edit_rule_modal'), 'it displays the modal');
    assert.ok(find('#save_rule').prop('disabled'), 'it disables the save button');
    fillIn('#channel-field', '#general');
    assert.ok(find('#save_rule').prop('disabled'), 'it enables the save button');
  });

  click('#save_rule');

  andThen(() => {
    assert.ok(!exists('#chat_integration_edit_rule_modal'), 'modal closes on save');
  })

});

test("Edit rule works", assert => {
  visit("/admin/plugins/chat");

  andThen(() => {
    assert.ok(exists('.edit:first'), 'edit button is displayed');
  });

  click('.edit:first');

  andThen(() => {
    assert.ok(exists('#chat_integration_edit_rule_modal'), 'modal opens on edit');
    assert.ok(!find('#save_rule').prop('disabled'), 'it enables the save button');
  });

  click('#save_rule');

  andThen(() => {
    assert.ok(!exists('#chat_integration_edit_rule_modal'), 'modal closes on save');
  });
});

test("Delete rule works", function(assert) {
  visit("/admin/plugins/chat");

  andThen(() => {
    assert.ok(exists('.delete:first'));
    click('.delete:first');
  });
});

test("Test provider works", assert => {
  visit("/admin/plugins/chat");

  andThen(() => {
    click('#test_provider');
  });

  andThen(() => {
    assert.ok(exists('#chat_integration_test_modal'), 'it displays the modal');
    assert.ok(find('#send_test').prop('disabled'), 'it disables the send button');
    fillIn('#channel-field', '#general');
    fillIn('#choose-topic-title', '9318');
  });

  andThen(() => {
    debugger;
    click('#chat_integration_test_modal .radio:first');
  });

  andThen(() => {
    assert.ok(!find('#send_test').prop('disabled'), 'it enables the send button');
  });

  andThen(() => {
    click('#send_test');
  });

  andThen(() => {
    assert.ok(exists('#chat_integration_test_modal'), 'modal doesn\'t close on send');
    assert.ok(exists('#modal-alert.alert-success'), 'success message displayed');
  })

});