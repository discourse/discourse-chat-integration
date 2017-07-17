require 'rails_helper'

RSpec.describe PostCreator do
  let(:first_post) { Fabricate(:post) }
  let(:topic) { Fabricate(:topic, posts: [first_post]) }

  before do
    SiteSetting.queue_jobs = true
    Jobs::NotifyChats.jobs.clear
  end

  describe 'when a post is created' do
    describe 'when plugin is enabled' do
      before do
        SiteSetting.chat_integration_enabled = true
      end

      it 'should schedule a chat notification job' do
        Timecop.freeze do
          post = PostCreator.new(topic.user,
            raw: 'Some post content',
            topic_id: topic.id
          ).create!

          job = Jobs::NotifyChats.jobs.last

          expect(job['at'])
            .to eq((Time.zone.now + SiteSetting.chat_integration_delay_seconds.seconds).to_f)

          expect(job['args'].first['post_id']).to eq(post.id)
        end
      end
    end

    describe 'when plugin is not enabled' do
      before do
        SiteSetting.chat_integration_enabled = false
      end

      it 'should not schedule a job for chat notifications' do
        PostCreator.new(topic.user,
          raw: 'Some post content',
          topic_id: topic.id
        ).create!

        expect(Jobs::NotifyChats.jobs).to eq([])
      end
    end
  end
end
