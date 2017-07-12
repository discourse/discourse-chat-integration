require 'rails_helper'

RSpec.describe DiscourseChat::Rule do

  let(:tag1){Fabricate(:tag)}
  let(:tag2){Fabricate(:tag)}

  describe '.alloc_key' do
    it 'should return sequential numbers' do 
      expect( DiscourseChat::Rule.create(provider:'slack',channel:'#general').key ).to eq("rule:1")
      expect( DiscourseChat::Rule.create(provider:'slack',channel:'#general').key ).to eq("rule:2")
      expect( DiscourseChat::Rule.create(provider:'slack',channel:'#general').key ).to eq("rule:3")
    end
  end

  it 'should save and load successfully' do
    expect(DiscourseChat::Rule.all.length).to eq(0)

    rule = DiscourseChat::Rule.create({
          provider:"slack",
          channel: "#general",
          category_id: 1,
          tags: [tag1.name, tag2.name],
          filter: 'watch'
        })

    expect(DiscourseChat::Rule.all.length).to eq(1)

    loadedRule = DiscourseChat::Rule.find(rule.id)

    expect(loadedRule.provider).to eq('slack')
    expect(loadedRule.channel).to eq('#general')
    expect(loadedRule.category_id).to eq(1)
    expect(loadedRule.tags).to contain_exactly(tag1.name,tag2.name)
    expect(loadedRule.filter).to eq('watch')

  end

  describe 'general operations' do
    before do
      rule = DiscourseChat::Rule.create({
          provider:"slack",
          channel: "#general",
          category_id: 1,
          tags: [tag1.name, tag2.name]
        })
    end

    it 'can be modified' do
      rule = DiscourseChat::Rule.all.first
      rule.channel = "#random"

      rule.save!

      rule = DiscourseChat::Rule.all.first
      expect(rule.channel).to eq('#random')
    end

    it 'can be deleted' do
      DiscourseChat::Rule.new({provider:'telegram', channel:'blah'}).save!
      expect(DiscourseChat::Rule.all.length).to eq(2)

      rule = DiscourseChat::Rule.all.first
      rule.destroy

      expect(DiscourseChat::Rule.all.length).to eq(1)
    end

    it 'can delete all' do
      DiscourseChat::Rule.new({provider:'telegram', channel:'blah'}).save!
      DiscourseChat::Rule.new({provider:'telegram', channel:'blah'}).save!
      DiscourseChat::Rule.new({provider:'telegram', channel:'blah'}).save!
      DiscourseChat::Rule.new({provider:'telegram', channel:'blah'}).save!
      
      expect(DiscourseChat::Rule.all.length).to eq(5)

      DiscourseChat::Rule.destroy_all

      expect(DiscourseChat::Rule.all.length).to eq(0)
    end

    it 'can be filtered by provider' do
      rule2 = DiscourseChat::Rule.new({provider:'telegram', channel:'blah'}).save!
      rule3 = DiscourseChat::Rule.new({provider:'slack', channel:'#blah'}).save!

      expect(DiscourseChat::Rule.all.length).to eq(3)

      expect(DiscourseChat::Rule.with_provider('slack').length).to eq(2)
      expect(DiscourseChat::Rule.with_provider('telegram').length).to eq(1)
    end

    it 'can be filtered by channel' do
      rule2 = DiscourseChat::Rule.new({provider:'telegram', channel:'blah'}).save!
      rule3 = DiscourseChat::Rule.new({provider:'slack', channel:'#blah'}).save!
      rule4 = DiscourseChat::Rule.new({provider:'slack', channel:'#general'}).save!
      rule5 = DiscourseChat::Rule.new({provider:'slack', channel:'#general'}).save!

      expect(DiscourseChat::Rule.all.length).to eq(5)

      expect(DiscourseChat::Rule.with_channel('slack','#general').length).to eq(3)
      expect(DiscourseChat::Rule.with_channel('slack', '#blah').length).to eq(1)
    end

    it 'can be filtered by category' do
      rule2 = DiscourseChat::Rule.new({provider:'slack', channel:'#blah', category_id: 1}).save!      
      rule3 = DiscourseChat::Rule.new({provider:'slack', channel:'#blah', category_id: nil}).save!

      expect(DiscourseChat::Rule.all.length).to eq(3)

      expect(DiscourseChat::Rule.with_category(1).length).to eq(2)
      expect(DiscourseChat::Rule.with_category(nil).length).to eq(1)
    end
  end

  describe 'validations' do
    
    let(:rule) do
      DiscourseChat::Rule.create({
          filter: 'watch',
          provider:"slack",
          channel: "#general",
          category_id: 1,
        })
    end

    it 'validates provider correctly' do
      expect(rule.valid?).to eq(true)
      rule.provider = 'somerandomprovider'
      expect(rule.valid?).to eq(false)
    end

    it 'validates channel correctly' do
      expect(rule.valid?).to eq(true)
      rule.channel = ''
      expect(rule.valid?).to eq(false)
      rule.channel = 'blah'
      expect(rule.valid?).to eq(false)
    end

    it 'validates category correctly' do
      expect(rule.valid?).to eq(true)
      rule.category_id = 99
      expect(rule.valid?).to eq(false)
    end

    it 'validates filter correctly' do
      expect(rule.valid?).to eq(true)
      rule.filter = 'follow'
      expect(rule.valid?).to eq(true)
      rule.filter = 'mute'
      expect(rule.valid?).to eq(true)
      rule.filter = ''
      expect(rule.valid?).to eq(false)
      rule.filter = 'somerandomstring'
      expect(rule.valid?).to eq(false)
    end

    it 'validates tags correctly' do
      expect(rule.valid?).to eq(true)
      rule.tags = []
      expect(rule.valid?).to eq(true)
      rule.tags = [tag1.name]
      expect(rule.valid?).to eq(true)
      rule.tags = [tag1.name, 'blah']
      expect(rule.valid?).to eq(false)
    end

    it "doesn't allow save when invalid" do
      expect(rule.valid?).to eq(true)
      rule.provider = 'somerandomprovider'
      expect(rule.valid?).to eq(false)
      expect(rule.save).to eq(false)
    end

  end
end