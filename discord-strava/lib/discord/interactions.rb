module Discord
  module Interactions
    extend self

    class Type
      include Ruby::Enum

      define :PING, 1
      define :APPLICATION_COMMAND, 2
      define :MESSAGE_COMPONENT, 3
      define :APPLICATION_COMMAND_AUTOCOMPLETE, 4
      define :MODAL_SUBMIT, 5
    end

    class Messages
      include Ruby::Enum

      define :CROSSPOSTED, 1 << 0 #	this message has been published to subscribed channels (via Channel Following)
      define :IS_CROSSPOST, 1 << 1 #	this message originated from a message in another channel (via Channel Following)
      define :SUPPRESS_EMBEDS, 1 << 2 #	do not include any embeds when serializing this message
      define :SOURCE_MESSAGE_DELETED, 1 << 3 #	the source message for this crosspost has been deleted (via Channel Following)
      define :URGENT, 1 << 4 #	this message came from the urgent message system
      define :HAS_THREAD, 1 << 5 #	this message has an associated thread, with the same id as the message
      define :EPHEMERAL, 1 << 6 #	this message is only visible to the user who invoked the Interaction
      define :LOADING, 1 << 7 #	this message is an Interaction Response and the bot is "thinking"
      define :FAILED_TO_MENTION_SOME_ROLES_IN_THREAD, 1 << 8 #	this message failed to mention some roles and add their members to the thread
      define :SUPPRESS_NOTIFICATIONS, 1 << 12 # this message will not trigger push and desktop notifications
      define :IS_VOICE_MESSAGE, 1 << 13 # this message is a voice message
    end
  end
end