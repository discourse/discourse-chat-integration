require 'rails_helper'

RSpec.describe DiscourseChat::Rule do
  describe '.alloc_id' do
    it 'should return sequential numbers' do 
      expect( DiscourseChat::Rule.alloc_id ).to eq(1)
      expect( DiscourseChat::Rule.alloc_id ).to eq(2)
      expect( DiscourseChat::Rule.alloc_id ).to eq(3)
    end
  end

  it 'should save and load successfully' do
    expect(DiscourseChat::Rule.all.length).to eq(0)

    rule = DiscourseChat::Rule.new({
          provider:"slack",
          channel: "#general",
          category_id: 2,
          tags: ['hello', 'world'],
          filter: 'watch'
        }).save

    expect(DiscourseChat::Rule.all.length).to eq(1)

    loadedRule = DiscourseChat::Rule.find(rule.id)

    expect(loadedRule.provider).to eq('slack')
    expect(loadedRule.channel).to eq('#general')
    expect(loadedRule.category_id).to eq(2)
    expect(loadedRule.tags).to contain_exactly('hello','world')
    expect(loadedRule.filter).to eq('watch')

  end

  describe 'general operations' do
    before do
      rule = DiscourseChat::Rule.new({
          provider:"slack",
          channel: "#general",
          category_id: 2,
          tags: ['hello', 'world']
        }).save
    end

    it 'can be modified' do
      rule = DiscourseChat::Rule.all.first
      rule.channel = "#random"

      rule.save

      rule = DiscourseChat::Rule.all.first
      expect(rule.channel).to eq('#random')
    end

    it 'can be deleted' do
      DiscourseChat::Rule.new.save
      expect(DiscourseChat::Rule.all.length).to eq(2)

      rule = DiscourseChat::Rule.all.first
      rule.destroy

      expect(DiscourseChat::Rule.all.length).to eq(1)
    end

    it 'can delete all' do
      DiscourseChat::Rule.new.save
      DiscourseChat::Rule.new.save
      DiscourseChat::Rule.new.save
      DiscourseChat::Rule.new.save

      expect(DiscourseChat::Rule.all.length).to eq(5)

      DiscourseChat::Rule.destroy_all

      expect(DiscourseChat::Rule.all.length).to eq(0)
    end

    it 'can be filtered by provider' do
      rule2 = DiscourseChat::Rule.new({provider:'telegram'}).save
      rule3 = DiscourseChat::Rule.new({provider:'slack'}).save

      expect(DiscourseChat::Rule.all.length).to eq(3)

      expect(DiscourseChat::Rule.all_for_provider('slack').length).to eq(2)
      expect(DiscourseChat::Rule.all_for_provider('telegram').length).to eq(1)
    end

    it 'can be filtered by category' do
      rule2 = DiscourseChat::Rule.new({category_id: 1}).save      
      rule3 = DiscourseChat::Rule.new({category_id: nil}).save

      expect(DiscourseChat::Rule.all.length).to eq(3)

      expect(DiscourseChat::Rule.all_for_category(2).length).to eq(1)
      expect(DiscourseChat::Rule.all_for_category(1).length).to eq(1)
      expect(DiscourseChat::Rule.all_for_category(nil).length).to eq(1)
    end

  end

end