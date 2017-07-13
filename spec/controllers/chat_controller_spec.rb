require 'rails_helper'
require_relative '../dummy_provider'

describe 'Chat Controller', type: :request do
  let(:first_post) { Fabricate(:post) }
  let(:topic) { Fabricate(:topic, posts: [first_post]) }
  let(:admin) { Fabricate(:admin) }
  let(:category) { Fabricate(:category) }
  let(:tag) { Fabricate(:tag) }

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

        expect(json['providers'].size).to eq(1)

        expect(json['providers'][0]).to eq('name'=> 'dummy',
                              'id'=> 'dummy',
                              'channel_regex'=> nil
                              )
      end
    end
  end

  describe 'testing providers' do
    include_examples 'admin constraints', 'get', '/admin/plugins/chat/test.json'

    context 'when signed in as an admin' do
      before do
        sign_in(admin)
      end

      it 'should return the right response' do
        post '/admin/plugins/chat/test.json', provider: 'dummy', channel: '#general', topic_id: topic.id

        expect(response).to be_success

        json = JSON.parse(response.body)
      end

      it 'should fail for invalid provider' do
        post '/admin/plugins/chat/test.json', provider: 'someprovider', channel: '#general', topic_id: topic.id

        expect(response).not_to be_success
      end
    end
  end

  describe 'viewing rules' do
    include_examples 'admin constraints', 'get', '/admin/plugins/chat/rules.json'

    context 'when signed in as an admin' do
      before do
        sign_in(admin)
      end

      it 'should return the right response' do
        rule = DiscourseChat::Rule.create({provider: 'dummy', channel: '#general', filter:'follow', category_id:category.id, tags:[tag.name]})

        get '/admin/plugins/chat/rules.json', provider:'dummy'

        expect(response).to be_success

        rules = JSON.parse(response.body)['rules']

        expect(rules.count).to eq(1)

        expect(rules.first).to eq(
          "channel" => "#general",
          "category_id" => category.id,
          "tags" => [tag.name],
          "filter" => "follow",
          "error_key" => nil,
          "id" => rule.id,
          "provider" => 'dummy'
        )
      end

      it 'should fail for invalid provider' do
        get '/admin/plugins/chat/rules.json', provider:'someprovider'

        expect(response).not_to be_success
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
        put '/admin/plugins/chat/rules.json',
          rule:{
            provider: 'dummy',
            channel: '#general',
            category_id: category.id,
            filter: 'watch',
            tags: [tag.name]
          }

        expect(response).to be_success

        rule = DiscourseChat::Rule.all.first

        expect(rule.provider).to eq('dummy')
        expect(rule.channel).to eq('#general')
        expect(rule.category_id).to eq(category.id)
        expect(rule.filter).to eq('watch')
        expect(rule.tags).to eq([tag.name])

      end

      it 'should fail for invalid params' do
        put '/admin/plugins/chat/rules.json',
          rule:{
            provider: 'dummy',
            channel: '#general',
            category_id: category.id,
            filter: 'watch',
            tags: ['somenonexistanttag']
          }

        expect(response).not_to be_success

      end
    end
  end

  describe 'updating a rule' do
    let(:rule){DiscourseChat::Rule.create({provider: 'dummy', channel: '#general', filter:'follow', category_id:category.id, tags:[tag.name]})}
    
    include_examples 'admin constraints', 'put', "/admin/plugins/chat/rules/1.json"

    context 'as an admin' do

      before do
        sign_in(admin)
      end

      it 'should be able update a rule' do
        put "/admin/plugins/chat/rules/#{rule.id}.json",
          rule:{
            provider: rule.provider,
            channel: '#random',
            category_id: rule.category_id,
            filter: rule.filter,
            tags: rule.tags
          }

        expect(response).to be_success

        rule = DiscourseChat::Rule.all.first

        expect(rule.provider).to eq('dummy')
        expect(rule.channel).to eq('#random')
        expect(rule.category_id).to eq(category.id)
        expect(rule.filter).to eq('follow')
        expect(rule.tags).to eq([tag.name])

      end

      it 'should fail for invalid params' do
        put "/admin/plugins/chat/rules/#{rule.id}.json",
          rule:{
            provider: 'dummy',
            channel: '#general',
            category_id: category.id,
            filter: 'watch',
            tags: ['somenonexistanttag']
          }

        expect(response).not_to be_success

      end
    end
  end

  describe 'deleting a rule' do
    let(:rule){DiscourseChat::Rule.create({provider: 'dummy', channel: '#general', filter:'follow', category_id:category.id, tags:[tag.name]})}
    
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
