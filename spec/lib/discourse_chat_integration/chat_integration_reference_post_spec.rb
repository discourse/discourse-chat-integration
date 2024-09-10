# frozen_string_literal: true
require "rails_helper"

RSpec.describe DiscourseChatIntegration::ChatIntegrationReferencePost do
  fab!(:topic)
  fab!(:first_post) { Fabricate(:post, topic: topic) }
  let!(:context) do
    {
      "user" => Fabricate(:user),
      "topic" => topic,
      # every rule will add a kind and their context params
    }
  end

  describe "when creating when topic tags change" do
    before do
      context["kind"] = DiscourseAutomation::Triggers::TOPIC_TAGS_CHANGED
      context["added_tags"] = %w[tag1 tag2]
      context["removed_tags"] = %w[tag3 tag4]
    end

    it "should create a post with the correct raw" do
      post =
        described_class.new(
          user: context["user"],
          topic: context["topic"],
          kind: context["kind"],
          context: {
            "added_tags" => context["added_tags"],
            "removed_tags" => context["removed_tags"],
          },
        )
      expect(post.raw).to eq("Added #tag1, #tag2 and removed #tag3, #tag4")
    end

    it "should have a working excerpt" do
      post =
        described_class.new(
          user: context["user"],
          topic: context["topic"],
          kind: context["kind"],
          context: {
            "added_tags" => context["added_tags"],
            "removed_tags" => context["removed_tags"],
          },
        )
      expect(post.excerpt).to eq("Added #tag1, #tag2 and removed #tag3, #tag4")
    end
  end
end
