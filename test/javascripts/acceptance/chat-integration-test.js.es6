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
    server.get('/admin/plugins/chat/providers', () => { // eslint-disable-line no-undef
      return response({ providers: [{name: 'dummy', id:'dummy',channel_parameters:[{key:'somekey', regex:"^\\S+$"}]}] });
    });
    server.get('/admin/plugins/chat/channels', () => { // eslint-disable-line no-undef
      return response({"channels":[{"id":97,"provider":"dummy","data":{val:"#general"},"rules":[{"id":98,"channel_id":97,"category_id":null,"tags":[],"filter":"watch","error_key":null}]}]});
    });
    server.post('/admin/plugins/chat/channels', () => { // eslint-disable-line no-undef
      return response({ });
    });
    server.put('/admin/plugins/chat/channels/:id', () => { // eslint-disable-line no-undef
      return response({ });
    }); 
    server.delete('/admin/plugins/chat/channels/:id', () => { // eslint-disable-line no-undef
      return response({ });
    });
    server.post('/admin/plugins/chat/rules', () => { // eslint-disable-line no-undef
      return response({ });
    });
    server.put('/admin/plugins/chat/rules/:id', () => { // eslint-disable-line no-undef
      return response({ });
    });
    server.delete('/admin/plugins/chat/rules/:id', () => { // eslint-disable-line no-undef
      return response({ });
    });
    server.post('/admin/plugins/chat/test', () => { // eslint-disable-line no-undef
      return response({ });
    });
    server.get('/groups/search.json', () => { // eslint-disable-line no-undef
      return response([]);
    });

  }

});

test("Rules load successfully", assert => {
  visit("/admin/plugins/chat");

  andThen(() => {
    assert.ok(exists('#admin-plugin-chat table'), "it shows the table of rules");
    assert.equal(find('#admin-plugin-chat table tr td').eq(0).text().trim(), 'All posts and replies', 'rule displayed');
  });
});

test("Create channel works", assert => {
  visit("/admin/plugins/chat");

  andThen(() => {
    click('#create_channel');
  });

  andThen(() => {
    assert.ok(exists('#chat_integration_edit_channel_modal'), 'it displays the modal');
    assert.ok(find('#save_channel').prop('disabled'), 'it disables the save button');
    fillIn('#chat_integration_edit_channel_modal input', '#general');
  });

  andThen(() => {
    assert.ok(!find('#save_channel').prop('disabled'), 'it enables the save button');
  });

  andThen(() => {
    click('#save_channel');
  });

  andThen(() => {
    assert.ok(!exists('#chat_integration_edit_channel_modal'), 'modal closes on save');
  });

});

// test("Edit channel works", assert => {
//   visit("/admin/plugins/chat");

//   andThen(() => {
//     click('#create_channel');
//   });

//   andThen(() => {
//     assert.ok(exists('#chat_integration_edit_channel_modal'), 'it displays the modal');
//     assert.ok(find('#save_channel').prop('disabled'), 'it disables the save button');
//     fillIn('#chat_integration_edit_channel_modal input', '#general');
//   });

//   andThen(() => {
//     assert.ok(!find('#save_channel').prop('disabled'), 'it enables the save button');
//   })

//   andThen(() => {
//     click('#save_channel');
//   });

//   andThen(() => {
//     assert.ok(!exists('#chat_integration_edit_channel_modal'), 'modal closes on save');
//   })

// });

// test("Edit rule works", assert => {
//   visit("/admin/plugins/chat");

//   andThen(() => {
//     assert.ok(exists('.edit:first'), 'edit button is displayed');
//   });

//   click('.edit:first');

//   andThen(() => {
//     assert.ok(exists('#chat_integration_edit_rule_modal'), 'modal opens on edit');
//     assert.ok(!find('#save_rule').prop('disabled'), 'it enables the save button');
//   });

//   click('#save_rule');

//   andThen(() => {
//     assert.ok(!exists('#chat_integration_edit_rule_modal'), 'modal closes on save');
//   });
// });

// test("Delete rule works", function(assert) {
//   visit("/admin/plugins/chat");

//   andThen(() => {
//     assert.ok(exists('.delete:first'));
//     click('.delete:first');
//   });
// });

test("Test provider works", assert => {
  visit("/admin/plugins/chat");

  andThen(() => {
    click('.fa-rocket');
  });

  andThen(() => {
    assert.ok(exists('#chat_integration_test_modal'), 'it displays the modal');
    assert.ok(find('#send_test').prop('disabled'), 'it disables the send button');
    fillIn('#choose-topic-title', '9318');
  });

  andThen(() => {
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
  });

});