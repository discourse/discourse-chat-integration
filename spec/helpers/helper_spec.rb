require 'rails_helper'
require_relative '../dummy_provider'

RSpec.describe DiscourseChat::Manager do
  include_context "dummy provider"

  let(:chan1){DiscourseChat::Channel.create!(provider:'dummy')}
  let(:chan2){DiscourseChat::Channel.create!(provider:'dummy')}

  let(:category) {Fabricate(:category)}

  let(:category) {Fabricate(:category)}
  let(:tag1){Fabricate(:tag)}
  let(:tag2){Fabricate(:tag)}
  let(:tag3){Fabricate(:tag)}

  describe '.status_for_channel' do
    
    context 'with no rules' do
      it 'includes the heading' do
        string = DiscourseChat::Helper.status_for_channel(chan1)
        expect(string).to include('dummy.status.header')
      end

      it 'includes the no_rules string' do
        string = DiscourseChat::Helper.status_for_channel(chan1)
        expect(string).to include('dummy.status.no_rules')
      end
    end

    context 'with some rules' do
      before do
        DiscourseChat::Rule.create!(channel: chan1, filter:'watch', category_id:category.id, tags:nil)
        DiscourseChat::Rule.create!(channel: chan1, filter:'mute', category_id:nil, tags:nil)
        DiscourseChat::Rule.create!(channel: chan1, filter:'follow', category_id:nil, tags:[tag1.name])
        DiscourseChat::Rule.create!(channel: chan2, filter:'watch', category_id:1, tags:nil)
      end

      it 'displays the correct rules' do
        string = DiscourseChat::Helper.status_for_channel(chan1)
        expect(string.scan('status.rule_string').size).to eq(3)
      end

      it 'only displays tags for rules with tags' do
        string = DiscourseChat::Helper.status_for_channel(chan1)
        expect(string.scan('rule_string_tags_suffix').size).to eq(0)

        SiteSetting.tagging_enabled = true
        string = DiscourseChat::Helper.status_for_channel(chan1)
        expect(string.scan('rule_string_tags_suffix').size).to eq(1)
      end

    end

  end

  describe '.delete_by_index' do
    let(:category2) {Fabricate(:category)}
    let(:category3) {Fabricate(:category)}

    it 'deletes the correct rule' do
      # Three identical rules, with different categories 
      # Status will be sorted by category id, so they should
      # be in this order
      rule1 = DiscourseChat::Rule.create(channel: chan1,
                                      filter: 'watch',
                                      category_id: category.id,
                                      tags: [tag1.name, tag2.name]
                                      )
      rule2 = DiscourseChat::Rule.create(channel: chan1,
                                      filter: 'watch',
                                      category_id: category2.id,
                                      tags: [tag1.name, tag2.name]
                                      )
      rule3 = DiscourseChat::Rule.create(channel: chan1,
                                      filter: 'watch',
                                      category_id: category3.id,
                                      tags: [tag1.name, tag2.name]
                                      )

      expect(DiscourseChat::Rule.all.size).to eq(3)

      expect(DiscourseChat::Helper.delete_by_index(chan1,2)).to eq(:deleted)

      expect(DiscourseChat::Rule.all.size).to eq(2)
      expect(DiscourseChat::Rule.all.map(&:category_id)).to contain_exactly(category.id, category3.id)
    end

    it 'fails gracefully for out of range indexes' do
      rule1 = DiscourseChat::Rule.create(channel: chan1,
                                        filter: 'watch',
                                        category_id: category.id,
                                        tags: [tag1.name, tag2.name]
                                        )

      expect(DiscourseChat::Helper.delete_by_index(chan1,-1)).to eq(false)
      expect(DiscourseChat::Helper.delete_by_index(chan1,0)).to eq(false)
      expect(DiscourseChat::Helper.delete_by_index(chan1,2)).to eq(false)

      expect(DiscourseChat::Helper.delete_by_index(chan1,1)).to eq(:deleted)
    end


  end

  describe '.smart_create_rule' do

    it 'creates a rule when there are none' do
      val = DiscourseChat::Helper.smart_create_rule(channel: chan1,
                                                    filter: 'watch',
                                                    category_id: category.id,
                                                    tags: [tag1.name]
                                                    )
      expect(val).to eq(:created)

      record = DiscourseChat::Rule.all.first
      expect(record.channel).to eq(chan1)
      expect(record.filter).to eq('watch')
      expect(record.category_id).to eq(category.id)
      expect(record.tags).to eq([tag1.name])
    end

    it 'updates a rule when it has the same category and tags' do
      existing = DiscourseChat::Rule.create!(channel:chan1,
                                          filter: 'watch',
                                          category_id: category.id,
                                          tags: [tag2.name, tag1.name]
                                        )

      val = DiscourseChat::Helper.smart_create_rule(channel: chan1,
                                                    filter: 'mute',
                                                    category_id: category.id,
                                                    tags: [tag1.name, tag2.name]
                                                    )

      expect(val).to eq(:updated)

      expect(DiscourseChat::Rule.all.size).to eq(1)
      expect(DiscourseChat::Rule.all.first.filter).to eq('mute')
    end

    it 'updates a rule when it has the same category and filter' do
      existing = DiscourseChat::Rule.create(channel: chan1,
                                            filter: 'watch',
                                            category_id: category.id,
                                            tags: [tag1.name, tag2.name]
                                            )

      val = DiscourseChat::Helper.smart_create_rule(channel: chan1,
                                                    filter: 'watch',
                                                    category_id: category.id,
                                                    tags: [tag1.name, tag3.name]
                                                    )

      expect(val).to eq(:updated)

      expect(DiscourseChat::Rule.all.size).to eq(1)
      expect(DiscourseChat::Rule.all.first.tags).to contain_exactly(tag1.name, tag2.name, tag3.name)
    end

    it 'destroys duplicate rules on save' do
      DiscourseChat::Rule.create!(channel: chan1, filter: 'watch')
      DiscourseChat::Rule.create!(channel: chan1, filter: 'watch')
      expect(DiscourseChat::Rule.all.size).to eq(2)
      val = DiscourseChat::Helper.smart_create_rule(channel: chan1,
                                                    filter: 'watch',
                                                    category_id: nil,
                                                    tags: nil
                                                    )
      expect(val).to eq(:updated)
      expect(DiscourseChat::Rule.all.size).to eq(1)
    end

    it 'returns false on error' do
      val = DiscourseChat::Helper.smart_create_rule(channel: chan1, filter: 'blah')

      expect(val).to eq(false)
    end
  end

end