require 'rails_helper'

RSpec.describe Jobs::DiscourseChatMigrateFromSlackOfficial do
  let(:category) { Fabricate(:category) }

  describe 'when a uncategorized filter is present' do
    before do
      PluginStoreRow.create!(
        plugin_name: 'discourse-slack-official',
        key: "category_*",
        type_name: "JSON",
        value: "[{\"channel\":\"#channel1\",\"filter\":\"watch\"},{\"channel\":\"#channel2\",\"filter\":\"follow\"},{\"channel\":\"#channel1\",\"filter\":\"mute\"}]"
      )
    end

    it 'should create the right channels and rules' do
      described_class.new.execute_onceoff({})

      expect(DiscourseChat::Channel.count).to eq(2)
      expect(DiscourseChat::Rule.count).to eq(2)

      channel = DiscourseChat::Channel.first

      expect(channel.value['provider']).to eq("slack")
      expect(channel.value['data']['identifier']).to eq("#channel1")

      rule = DiscourseChat::Rule.first

      expect(rule.value['channel_id']).to eq(channel.id)
      expect(rule.value['filter']).to eq('mute')
      expect(rule.value['category_id']).to eq(nil)

      channel = DiscourseChat::Channel.last

      expect(channel.value['provider']).to eq("slack")
      expect(channel.value['data']['identifier']).to eq("#channel2")

      rule = DiscourseChat::Rule.last

      expect(rule.value['channel_id']).to eq(channel.id)
      expect(rule.value['filter']).to eq('follow')
      expect(rule.value['category_id']).to eq(nil)
    end
  end

  describe 'when filter contains an invalid tag' do
    let(:tag) { Fabricate(:tag) }

    before do
      PluginStoreRow.create!(
        plugin_name: 'discourse-slack-official',
        key: "category_#{category.id}",
        type_name: "JSON",
        value: "[{\"channel\":\"#slack-channel\",\"filter\":\"mute\",\"tags\":[\"#{tag.name}\",\"random-tag\"]}]"
      )
    end

    it 'should discard invalid tags' do
      described_class.new.execute_onceoff({})

      rule = DiscourseChat::Rule.first

      expect(rule.value['tags']).to eq([tag.name])
    end
  end

  describe 'when a category filter is present' do
    before do
      PluginStoreRow.create!(
        plugin_name: 'discourse-slack-official',
        key: "category_#{category.id}",
        type_name: "JSON",
        value: "[{\"channel\":\"#slack-channel\",\"filter\":\"mute\"}]"
      )
    end

    it 'should migrate the settings correctly' do
      described_class.new.execute_onceoff({})

      channel = DiscourseChat::Channel.first

      expect(channel.value['provider']).to eq("slack")
      expect(channel.value['data']['identifier']).to eq("#slack-channel")

      rule = DiscourseChat::Rule.first

      expect(rule.value['channel_id']).to eq(channel.id)
      expect(rule.value['filter']).to eq('mute')
      expect(rule.value['category_id']).to eq(category.id)
    end
  end

  describe 'when a category has been deleted' do
    before do
      PluginStoreRow.create!(
        plugin_name: 'discourse-slack-official',
        key: 'category_9999',
        type_name: "JSON",
        value: "[{\"channel\":\"#slack-channel\",\"filter\":\"mute\"}]"
      )
    end

    it 'should not migrate the settings' do
      described_class.new.execute_onceoff({})

      expect(DiscourseChat::Channel.count).to eq(0)
      expect(DiscourseChat::Rule.count).to eq(0)
    end
  end
end
