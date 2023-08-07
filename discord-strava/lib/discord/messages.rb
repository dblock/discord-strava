module Discord
  module Messages
    extend Server
    extend self

    def create_dm(recipient_id)
      post(
        'users/@me/channels', {
          recipient_id: recipient_id
        }
      )
    end

    def send_message(channel_id, message)
      post("channels/#{channel_id}/messages", message.is_a?(String) ? { content: message } : message)
    end

    def update_message(channel_id, message_id, message)
      patch("channels/#{channel_id}/messages/#{message_id}", message.is_a?(String) ? { content: message } : message)
    end

    def delete_message(channel_id, message_id)
      delete("channels/#{channel_id}/messages/#{message_id}")
    end

    def send_dm(recipient_id, message)
      channel = create_dm(recipient_id)
      send_message(channel['id'], message)
    end
  end
end
