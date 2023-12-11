# frozen_string_literal: true

RSpec.describe "Create channel", type: :system do
  fab!(:admin)

  before do
    SiteSetting.chat_integration_enabled = true
    SiteSetting.chat_integration_discord_enabled = true
    sign_in(admin)
  end

  it "creates and displays a new channel" do
    visit("/admin/plugins/chat-integration/discord")

    expect(page).to have_no_css(".channel-details")

    click_button(I18n.t("js.chat_integration.create_channel"))

    find("input[name='param-name']").fill_in(with: "bloop")
    find("input[name='param-webhook_url']").fill_in(with: "https://discord.com/api/webhooks/bloop")
    click_button(I18n.t("js.chat_integration.edit_channel_modal.save"))

    expect(page).to have_css(".channel-details")
    expect(find(".channel-info")).to have_content("bloop")
  end
end
