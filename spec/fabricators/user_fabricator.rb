Fabricator(:user) do
  user_id { Fabricate.sequence(:user_id) { |i| "user-#{i}" } }
  user_name { Faker::Internet.user_name }
  channel_id { Fabricate.sequence(:channel_id) { |i| "channel-#{i}" } }
  team { Team.first || Fabricate(:team) }
  athlete { |user| Fabricate.build(:athlete, user: user) }
end
