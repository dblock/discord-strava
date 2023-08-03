Fabricator(:team) do
  token { Fabricate.sequence(:team_token) { |i| "abc-#{i}" } }
  guild_id { Fabricate.sequence(:guild_id) { |i| "guild-#{i}" } }
  guild_owner_id { Fabricate.sequence(:guild_owner_id) { |i| "user-#{i}" } }
  guild_name { Faker::Lorem.word }
  api { true }
end
