module DiscordStrava
  INFO = <<~EOS.freeze
    I am Strada, a Discord bot powered by Strava #{DiscordStrava::VERSION}.

    © 2023-2025 Daniel Doubrovkine, Vestris LLC & Contributors, Open-Source, MIT License
    https://www.vestris.com

    Service at #{DiscordStrava::Service.url}
    Please report bugs or suggest features at https://github.com/dblock/discord-strava/issues.
  EOS
end
