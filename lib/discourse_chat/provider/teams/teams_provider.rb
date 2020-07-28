# frozen_string_literal: true

module DiscourseChat::Provider::TeamsProvider
  PROVIDER_NAME = "teams".freeze
  PROVIDER_ENABLED_SETTING = :chat_integration_slack_enabled
  CHANNEL_PARAMETERS = [
                        # { key: "identifier", regex: '^[@#]\S*$', unique: true }
                      ]

  def self.trigger_notification(post, channel)
    message = {
      "@type": "MessageCard",
      "@context": "http://schema.org/extensions",
      "themeColor": "0076D7",
      "summary": "Larry Bryant created a new task",
      "sections": [{
          "activityTitle": "![TestImage](https://47a92947.ngrok.io/Content/Images/default.png)Larry Bryant created a new task",
          "activitySubtitle": "On Project Tango",
          "activityImage": "https://teamsnodesample.azurewebsites.net/static/img/image5.png",
          "facts": [{
              "name": "Assigned to",
              "value": "Unassigned"
          }, {
              "name": "Due date",
              "value": "Mon May 01 2017 17:07:18 GMT-0700 (Pacific Daylight Time)"
          }, {
              "name": "Status",
              "value": "Not started"
          }],
          "markdown": true
      }],
      "potentialAction": [{
          "@type": "ActionCard",
          "name": "Add a comment",
          "inputs": [{
              "@type": "TextInput",
              "id": "comment",
              "isMultiline": false,
              "title": "Add a comment here for this task"
          }],
          "actions": [{
              "@type": "HttpPOST",
              "name": "Add comment",
              "target": "http://..."
          }]
      }, {
          "@type": "ActionCard",
          "name": "Set due date",
          "inputs": [{
              "@type": "DateInput",
              "id": "dueDate",
              "title": "Enter a due date for this task"
          }],
          "actions": [{
              "@type": "HttpPOST",
              "name": "Save",
              "target": "http://..."
          }]
      }, {
        "@type": "ActionCard",
        "name": "Change status",
        "inputs": [{
          "@type": "MultichoiceInput",
          "id": "list",
          "title": "Select a status",
          "isMultiSelect": "false",
          "choices": [{
            "display": "In Progress",
            "value": "1"
          }, {
            "display": "Active",
            "value": "2"
          }, {
            "display": "Closed",
            "value": "3"
          }]
        }],
        "actions": [{
          "@type": "HttpPOST",
          "name": "Save",
          "target": "http://..."
        }]
      }]
    }

    self.send_via_webhook(message)
  end

  def self.send_via_webhook(message)
    uri = URI("https://outlook.office.com/webhook/677980e4-e03b-4a5e-ad29-dc1ee0c32a80@9e9b5238-5ab2-496a-8e6a-e9cf05c7eb5c/IncomingWebhook/e7a1006ded44478992769d0c4f391e34/e028ca8a-e9c8-4c6c-a4d8-578f881a3cff")

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == 'https')

    req = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
    req.body = message.to_json
    response = http.request(req)

    unless response.kind_of? Net::HTTPSuccess
      if response.body.include?('invalid-channel')
        error_key = 'chat_integration.provider.rocketchat.errors.invalid_channel'
      else
        error_key = nil
      end
      raise ::DiscourseChat::ProviderError.new info: { error_key: error_key, request: req.body, response_code: response.code, response_body: response.body }
    end

  end
end