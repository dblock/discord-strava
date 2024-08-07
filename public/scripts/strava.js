var DiscordStrava = {};

$(document).ready(function() {

    DiscordStrava.message = function(text) {
        $('#messages').fadeOut('slow', function() {
            $('#messages').fadeIn('slow').html(text)
        });
    };

    DiscordStrava.errorMessage = function(message) {
        DiscordStrava.message(message)
        $('#messages').addClass('has-error');
    };

    DiscordStrava.error = function(xhr) {
        try {
            var message;
            if (xhr.responseText) {
                var rc = JSON.parse(xhr.responseText);
                if (rc && rc.error) {
                    message = rc.error;
                } else if (rc && rc.message) {
                    message = rc.message;
                    if (message == 'invalid_code') {
                        message = 'The code returned from the OAuth workflow was invalid.'
                    } else if (message == 'code_already_used') {
                        message = 'The code returned from the OAuth workflow has already been used.'
                    }
                } else if (rc && rc.error) {
                    message = rc.error;
                }
            }

            DiscordStrava.errorMessage(message || xhr.statusText || xhr.responseText || 'Unexpected Error');

        } catch (err) {
            DiscordStrava.errorMessage(err.message);
        }
    };
});