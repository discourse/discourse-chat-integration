require 'rails_helper'

RSpec.describe DiscourseChat::Manager do

  let(:category) {Fabricate(:category)}
  let(:tag1){Fabricate(:tag)}

  describe '.status_for_channel' do
    
    context 'with no rules' do
      it 'includes the heading' do
        string = DiscourseChat::Helper.status_for_channel('slack','#general')
        expect(string).to include('Rules for this channel')
      end

      it 'includes the no_rules string' do
        string = DiscourseChat::Helper.status_for_channel('slack','#general')
        expect(string).to include('no rules')
      end
    end

    context 'with some rules' do
      before do
        DiscourseChat::Rule.new({provider: 'slack', channel: '#general', filter:'watch', category_id:category.id, tags:nil}).save!
        DiscourseChat::Rule.new({provider: 'slack', channel: '#general', filter:'mute', category_id:nil, tags:nil}).save!
        DiscourseChat::Rule.new({provider: 'slack', channel: '#general', filter:'follow', category_id:nil, tags:[tag1.name]}).save!
        DiscourseChat::Rule.new({provider: 'slack', channel: '#otherchannel', filter:'watch', category_id:1, tags:nil}).save!
      end

      it 'displays the correct rules' do
        string = DiscourseChat::Helper.status_for_channel('slack','#general')
        expect(string.scan('watch').size).to eq(1)
        expect(string.scan('mute').size).to eq(1)
        expect(string.scan('follow').size).to eq(1)
      end

      it 'enumerates the rules correctly' do
        string = DiscourseChat::Helper.status_for_channel('slack','#general')
        expect(string.scan('1)').size).to eq(1)
        expect(string.scan('2)').size).to eq(1)
        expect(string.scan('3)').size).to eq(1)
      end

      it 'only displays tags for rules with tags' do
        string = DiscourseChat::Helper.status_for_channel('slack','#general')
        expect(string.scan('with tags').size).to eq(0)

        SiteSetting.tagging_enabled = true
        string = DiscourseChat::Helper.status_for_channel('slack','#general')
        expect(string.scan('with tags').size).to eq(1)
      end

    end

  end

end