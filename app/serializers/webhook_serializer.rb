# frozen_string_literal: true

class DiscourseChat::WebhookSerializer < ApplicationSerializer
  attributes :id, :provider, :data
end
