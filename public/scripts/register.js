$(document).ready(function() {
    // Discord OAuth
    var code = $.url('?code')
    var guild_id = $.url('?guild_id')
    var permissions = $.url('?permissions')
    if (code) {
        DiscordStrava.message('Working, please wait ...');
        $('#register').hide();
        $.ajax({
            type: "POST",
            url: "/api/teams",
            data: {
                code: code,
                guild_id: guild_id,
                permissions: permissions
            },
            success: function(data) {
                DiscordStrava.message('Team successfully registered!<br><br>Try <b>/strada connect</b> in a channel.');
            },
            error: DiscordStrava.error
        });
    }
});