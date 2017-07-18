require 'rails_helper'
require_relative '../dummy_provider'

describe 'Chat Controller', type: :request do
  let(:first_post) { Fabricate(:post) }
  let(:topic) { Fabricate(:topic, posts: [first_post]) }
  let(:admin) { Fabricate(:admin) }
  let(:category) { Fabricate(:category) }
  let(:category2) { Fabricate(:category) }
  let(:tag) { Fabricate(:tag) }
  let(:channel) { DiscourseChat::Channel.create(provider:'dummy') }

  include_context "dummy provider"

  before do
    SiteSetting.chat_integration_enabled = true
  end

  shared_examples 'admin constraints' do |action, route|
    context 'when user is not signed in' do
      it 'should raise the right error' do
        expect { send(action, route) }.to raise_error(ActionController::RoutingError)
      end
    end

    context 'when user is not an admin' do
      it 'should raise the right error' do
        sign_in(Fabricate(:user))
        expect { send(action, route) }.to raise_error(ActionController::RoutingError)
      end
    end
  end

  describe 'listing providers' do
    include_examples 'admin constraints', 'get', '/admin/plugins/chat/providers.json'

    context 'when signed in as an admin' do
      before do
        sign_in(admin)
      end

      it 'should return the right response' do
        get '/admin/plugins/chat/providers.json'

        expect(response).to be_success

        json = JSON.parse(response.body)

        expect(json['providers'].size).to eq(2)

        expect(json['providers'][0]).to eq('name'=> 'dummy',
                              'id'=> 'dummy',
                              'channel_parameters'=> []
                              )
      end
    end
  end

  describe 'testing channels' do
    include_examples 'admin constraints', 'get', '/admin/plugins/chat/test.json'

    context 'when signed in as an admin' do
      before do
        sign_in(admin)
      end

      it 'should return the right response' do
        post '/admin/plugins/chat/test.json', channel_id: channel.id, topic_id: topic.id

        expect(response).to be_success

        json = JSON.parse(response.body)
      end

      it 'should fail for invalid channel' do
        post '/admin/plugins/chat/test.json', channel_id: 999, topic_id: topic.id

        expect(response).not_to be_success
      end
    end
  end

  describe 'viewing channels' do
    include_examples 'admin constraints', 'get', '/admin/plugins/chat/channels.json'

    context 'when signed in as an admin' do
      before do
        sign_in(admin)
      end

      it 'should return the right response' do
        rule = DiscourseChat::Rule.create(channel: channel, filter:'follow', category_id:category.id, tags:[tag.name])

        get '/admin/plugins/chat/channels.json', provider:'dummy'

        expect(response).to be_success

        channels = JSON.parse(response.body)['channels']

        expect(channels.count).to eq(1)

        expect(channels.first).to eq(
          "id" => channel.id,
          "provider" => 'dummy',
          "data" => {},
          "error_key" => nil,
          "rules" => [{"id" => rule.id, "filter" => "follow", "channel_id" => channel.id, "category_id" => category.id, "tags" => [tag.name]}]
        )
      end

      it 'should fail for invalid provider' do
        get '/admin/plugins/chat/channels.json', provider:'someprovider'

        expect(response).not_to be_success
      end

    end
  end

  describe 'adding a channel' do
    include_examples 'admin constraints', 'post', '/admin/plugins/chat/channels.json'

    context 'as an admin' do

      before do
        sign_in(admin)
      end

      it 'should be able to add a new channel' do
        post '/admin/plugins/chat/channels.json',
          channel:{
            provider: 'dummy',
            data: {}
          }

        expect(response).to be_success

        channel = DiscourseChat::Channel.all.first

        expect(channel.provider).to eq('dummy')
      end

      it 'should fail for invalid params' do
        post '/admin/plugins/chat/channels.json',
          channel:{
            provider: 'dummy2',
            data: {val: 'something with whitespace'}
          }

        expect(response).not_to be_success

      end
    end
  end

  describe 'updating a channel' do
    let(:channel){DiscourseChat::Channel.create(provider:'dummy2', data:{val:"something"})}
    
    include_examples 'admin constraints', 'put', "/admin/plugins/chat/channels/1.json"

    context 'as an admin' do

      before do
        sign_in(admin)
      end

      it 'should be able update a channel' do
        put "/admin/plugins/chat/channels/#{channel.id}.json",
          channel:{
            data: {val: "something-else"}
          }

        expect(response).to be_success

        channel = DiscourseChat::Channel.all.first
        expect(channel.data).to eq({"val" => "something-else"})
      end

      it 'should fail for invalid params' do
        put "/admin/plugins/chat/channels/#{channel.id}.json",
          channel:{
            data: {val: "something with whitespace"}
          }

        expect(response).not_to be_success

      end
    end
  end

  describe 'deleting a channel' do
    let(:channel){DiscourseChat::Channel.create(provider:'dummy', data:{})}
    
    include_examples 'admin constraints', 'delete', "/admin/plugins/chat/channels/1.json"

    context 'as an admin' do

      before do
        sign_in(admin)
      end

      it 'should be able delete a channel' do
        delete "/admin/plugins/chat/channels/#{channel.id}.json"

        expect(response).to be_success

        expect(DiscourseChat::Channel.all.size).to eq(0)
      end
    end
  end

  describe 'adding a rule' do
    include_examples 'admin constraints', 'put', '/admin/plugins/chat/rules.json'

    context 'as an admin' do

      before do
        sign_in(admin)
      end

      it 'should be able to add a new rule' do
        post '/admin/plugins/chat/rules.json',
          rule:{
            channel_id: channel.id,
            category_id: category.id,
            filter: 'watch',
            tags: [tag.name]
          }

        expect(response).to be_success

        rule = DiscourseChat::Rule.all.first

        expect(rule.channel_id).to eq(channel.id)
        expect(rule.category_id).to eq(category.id)
        expect(rule.filter).to eq('watch')
        expect(rule.tags).to eq([tag.name])

      end

      it 'should fail for invalid params' do
        post '/admin/plugins/chat/rules.json',
          rule:{
            channel_id: channel.id,
            category_id: category.id,
            filter: 'watch',
            tags: ['somenonexistanttag']
          }

        expect(response).not_to be_success

      end
    end
  end

  describe 'updating a rule' do
    let(:rule){DiscourseChat::Rule.create(channel: channel, filter:'follow', category_id:category.id, tags:[tag.name])}
    
    include_examples 'admin constraints', 'put', "/admin/plugins/chat/rules/1.json"

    context 'as an admin' do

      before do
        sign_in(admin)
      end

      it 'should be able update a rule' do
        put "/admin/plugins/chat/rules/#{rule.id}.json",
          rule:{
            channel_id: channel.id,
            category_id: category2.id,
            filter: rule.filter,
            tags: rule.tags
          }

        expect(response).to be_success

        rule = DiscourseChat::Rule.all.first
        expect(rule.category_id).to eq(category2.id)
      end

      it 'should fail for invalid params' do
        put "/admin/plugins/chat/rules/#{rule.id}.json",
          rule:{
            channel_id: channel.id,
            category_id: category.id,
            filter: 'watch',
            tags: ['somenonexistanttag']
          }

        expect(response).not_to be_success

      end
    end
  end

  describe 'deleting a rule' do
    let(:rule){DiscourseChat::Rule.create(channel_id: channel.id, filter:'follow', category_id:category.id, tags:[tag.name])}
    
    include_examples 'admin constraints', 'delete', "/admin/plugins/chat/rules/1.json"

    context 'as an admin' do

      before do
        sign_in(admin)
      end

      it 'should be able delete a rule' do
        delete "/admin/plugins/chat/rules/#{rule.id}.json"

        expect(response).to be_success

        expect(DiscourseChat::Rule.all.size).to eq(0)
      end
    end
  end

end
