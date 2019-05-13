# frozen_string_literal: true

require 'rails_helper'
require_relative '../dummy_provider'

RSpec.describe DiscourseChat::Channel do
  include_context "dummy provider"
  include_context "validated dummy provider"

  it 'should save and load successfully' do
    expect(DiscourseChat::Channel.all.length).to eq(0)

    chan = DiscourseChat::Channel.create(provider: "dummy")

    expect(DiscourseChat::Channel.all.length).to eq(1)

    loadedChan = DiscourseChat::Channel.find(chan.id)

    expect(loadedChan.provider).to eq('dummy')

  end

  it 'should edit successfully' do
    channel = DiscourseChat::Channel.create!(provider: "dummy2", data: { val: "hello" })
    expect(channel.valid?).to eq(true)
    channel.save!
  end

  it 'can be filtered by provider' do
    channel1 = DiscourseChat::Channel.create!(provider: 'dummy')
    channel2 = DiscourseChat::Channel.create!(provider: 'dummy2', data: { val: "blah" })
    channel3 = DiscourseChat::Channel.create!(provider: 'dummy2', data: { val: "blah2" })

    expect(DiscourseChat::Channel.all.length).to eq(3)

    expect(DiscourseChat::Channel.with_provider('dummy2').length).to eq(2)
    expect(DiscourseChat::Channel.with_provider('dummy').length).to eq(1)
  end

  it 'can be filtered by data value' do
    channel2 = DiscourseChat::Channel.create!(provider: 'dummy2', data: { val: "foo" })
    channel3 = DiscourseChat::Channel.create!(provider: 'dummy2', data: { val: "blah" })

    expect(DiscourseChat::Channel.all.length).to eq(2)

    for_provider = DiscourseChat::Channel.with_provider('dummy2')
    expect(for_provider.length).to eq(2)

    expect(DiscourseChat::Channel.with_provider('dummy2').with_data_value('val', 'blah').length).to eq(1)
  end

  it 'can find its own rules' do
    channel = DiscourseChat::Channel.create(provider: 'dummy')
    expect(channel.rules.size).to eq(0)
    DiscourseChat::Rule.create(channel: channel)
    DiscourseChat::Rule.create(channel: channel)
    expect(channel.rules.size).to eq(2)
  end

  it 'destroys its rules on destroy' do
    channel = DiscourseChat::Channel.create(provider: 'dummy')
    expect(channel.rules.size).to eq(0)
    rule1 = DiscourseChat::Rule.create(channel: channel)
    rule2 = DiscourseChat::Rule.create(channel: channel)

    expect(DiscourseChat::Rule.with_channel(channel).exists?).to eq(true)
    channel.destroy()
    expect(DiscourseChat::Rule.with_channel(channel).exists?).to eq(false)
  end

  describe 'validations' do

    it 'validates provider correctly' do
      channel = DiscourseChat::Channel.create!(provider: "dummy")
      expect(channel.valid?).to eq(true)
      channel.provider = 'somerandomprovider'
      expect(channel.valid?).to eq(false)
    end

    it 'succeeds with valid data' do
      channel2 = DiscourseChat::Channel.new(provider: "dummy2", data: { val: "hello" })
      expect(channel2.valid?).to eq(true)
    end

    it 'disallows invalid data' do
      channel2 = DiscourseChat::Channel.new(provider: "dummy2", data: { val: '  ' })
      expect(channel2.valid?).to eq(false)
    end

    it 'disallows unknown keys' do
      channel2 = DiscourseChat::Channel.new(provider: "dummy2", data: { val: "hello", unknown: "world" })
      expect(channel2.valid?).to eq(false)
    end

    it 'requires all keys' do
      channel2 = DiscourseChat::Channel.new(provider: "dummy2", data: {})
      expect(channel2.valid?).to eq(false)
    end

    it 'disallows duplicate channels' do
      channel1 = DiscourseChat::Channel.create(provider: "dummy2", data: { val: "hello" })
      channel2 = DiscourseChat::Channel.new(provider: "dummy2", data: { val: "hello" })
      expect(channel2.valid?).to eq(false)
      channel2.data[:val] = "hello2"
      expect(channel2.valid?).to eq(true)
    end

  end
end
