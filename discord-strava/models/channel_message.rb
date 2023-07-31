class ChannelMessage
  include Mongoid::Document

  field :message_id, type: String
  field :channel_id, type: String
end
