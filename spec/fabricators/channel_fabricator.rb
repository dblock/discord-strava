Fabricator(:channel) do
  team
  channel_id { Fabricate.sequence(:channel_id) { |i| "channel-id-#{i}" } }
  channel_name { Fabricate.sequence(:channel_name) { |i| "channel-name-#{i}" } }
end
