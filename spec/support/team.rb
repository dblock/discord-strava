RSpec.shared_context 'team activation', shared_context: :metadata do
  before do
    allow(Discord::Bot.instance).to receive_messages(info: ActiveSupport::HashWithIndifferentAccess.new(
      id: 'guild_id',
      name: 'guild name',
      system_channel_id: 'system_channel_id'
    ), send_message: ActiveSupport::HashWithIndifferentAccess.new(
      id: 'message_id',
      channel_id: 'channel_id'
    ))

    allow_any_instance_of(Discord::Client).to receive(:get).with('users/@me').and_return(
      ActiveSupport::HashWithIndifferentAccess.new(
        username: 'bot_owner_name',
        id: 'bot_owner_id'
      )
    )
  end
end
