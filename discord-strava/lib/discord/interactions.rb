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

    class Channels
      include Ruby::Enum

      define :GUILD_TEXT, 0 #	a text channel within a server
      define :DM, 1 # a direct message between users
      define :GUILD_VOICE, 2 # a voice channel within a server
      define :GROUP_DM, 3 # a direct message between multiple users
      define :GUILD_CATEGORY, 4 # an organizational category that contains up to 50 channels
      define :GUILD_ANNOUNCEMENT, 5 # a channel that users can follow and crosspost into their own server (formerly news channels)
      define :ANNOUNCEMENT_THREAD, 10 # a temporary sub-channel within a GUILD_ANNOUNCEMENT channel
      define :PUBLIC_THREAD, 11 # a temporary sub-channel within a GUILD_TEXT or GUILD_FORUM channel
      define :PRIVATE_THREAD, 12 # a temporary sub-channel within a GUILD_TEXT channel that is only viewable by those invited and those with the MANAGE_THREADS permission
      define :GUILD_STAGE_VOICE, 13 # a voice channel for hosting events with an audience
      define :GUILD_DIRECTORY, 14 # the channel in a hub containing the listed servers
      define :GUILD_FORUM, 15 # Channel that can only contain threads
    end
  end
end
