module Discord
  module Guilds
    extend Server
    extend self

    def info(guild_id)
      get("guilds/#{guild_id}")
    end
  end
end
