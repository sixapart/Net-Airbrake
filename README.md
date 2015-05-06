
# NAME

Net::Airbrake - Airbrake Notifier API Client

# SYNOPSIS

    use Net::Airbrake;

    my $airbrake = Net::Airbrake->new(
        api_key    => 'xxxxxxx',
        project_id => 9999999,
    );

    eval { die 'Oops' };
    $airbrake->notify($@);

# DESCRIPTION

Net::Airbrake is a client of [Airbrake](https://airbrake.io).

# METHODS

## new(\\%default)

## add\_error(\\%error)

## send(\\%option)

## notify(\\%error, \\%option)

# SEE ALSO

Notifier API V3 - [https://help.airbrake.io/kb/api-2/notifier-api-v3](https://help.airbrake.io/kb/api-2/notifier-api-v3)

# AUTHOR

Six Apart, Ltd. <sixapart@cpan.org>

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
