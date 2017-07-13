require 'rails_helper'
require_relative '../dummy_provider'

RSpec.describe DiscourseChat::Channel do
  include_context "dummy provider"


  it 'should save and load successfully' do
    expect(DiscourseChat::Channel.all.length).to eq(0)

    chan = DiscourseChat::Channel.create({
          provider:"dummy",
          descriptor: "#random",
        })

    expect(DiscourseChat::Channel.all.length).to eq(1)

    loadedChan = DiscourseChat::Channel.find(chan.id)

    expect(loadedChan.provider).to eq('dummy')
    expect(loadedChan.descriptor).to eq('#random')
    
  end

  it 'can be filtered by provider' do
    channel1 = DiscourseChat::Channel.create({provider:'dummy', descriptor:'blah'})
    channel2 = DiscourseChat::Channel.create({provider:'slack', descriptor:'#blah'})
    channel3 = DiscourseChat::Channel.create({provider:'slack', descriptor:'#blah'})

    expect(DiscourseChat::Channel.all.length).to eq(3)

    expect(DiscourseChat::Channel.with_provider('slack').length).to eq(2)
    expect(DiscourseChat::Channel.with_provider('dummy').length).to eq(1)
  end

  it 'can find its own rules' do
    channel = DiscourseChat::Channel.create({provider:'dummy', descriptor:'blah'})
    expect(channel.rules.size).to eq(0)
    DiscourseChat::Rule.create(channel: channel)
    DiscourseChat::Rule.create(channel: channel)
    expect(channel.rules.size).to eq(2)

  end

  describe 'validations' do
    let(:channel) { DiscourseChat::Channel.create(
        provider:"dummy",
        descriptor: "#general"
      ) }

    it 'validates provider correctly' do
      expect(channel.valid?).to eq(true)
      channel.provider = 'somerandomprovider'
      expect(channel.valid?).to eq(false)
    end

    it 'validates channel correctly' do
      expect(channel.valid?).to eq(true)
      channel.descriptor = ''
      expect(channel.valid?).to eq(false)
    end

  end
end