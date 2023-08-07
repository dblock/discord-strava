Fabricator(:channel_message) do
  channel_id { Fabricate.sequence(:channel_id) { |id| "channel-#{id}" } }
  message_id { Fabricate.sequence(:message_id) { |id| "message-#{id}" } }
end
