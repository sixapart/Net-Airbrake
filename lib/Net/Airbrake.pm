package Net::Airbrake;

use strict;
use warnings;

our $VERSION = '0.01';

use HTTP::Tiny;
use JSON qw(decode_json);
use Scope::Guard qw(guard);
use Net::Airbrake::Request;
use Net::Airbrake::Error;

use Class::Tiny {
    api_key     => undef,
    project_id  => undef,
    environment => $ENV{AIRBRAKE_ENV} || $ENV{PLACK_ENV} || 'default',
    _errors     => sub { [] },
    _ua         => sub { HTTP::Tiny->new(agent => "Net-Airbrake/$VERSION", timeout => 5) }
};

sub add_error {
    my $self = shift;
    my ($error) = @_;

    push @{$self->_errors}, Net::Airbrake::Error->new($error);
}

sub has_error {
    scalar @{shift->_errors} ? 1 : 0;
}

sub send {
    my $self = shift;
    my ($option) = @_;

    return unless $self->has_error;

    $self->_conceal_options($option);

    my $context = {
        os          => $^O,
        language    => "Perl $^V",
        environment => $self->environment,
        %{$option->{context} || {}},
    };
    my $req = Net::Airbrake::Request->new({
        errors      => $self->_errors,
        context     => $context,
        environment => $option->{environment} || {},
        session     => $option->{session}     || {},
        params      => $option->{params}      || {},
    });

    my $guard = guard { $self->_errors([]) };
    my $res = $self->_ua->request(POST => $self->_url, {
        content => $req->to_json,
        headers => { 'Content-Type' => 'application/json' },
    });
    die "Request failed to Airbrake: @{[$res->{status}]} @{[$res->{reason}]} (@{[$res->{content}]})"
        unless $res->{success};

    decode_json($res->{content});
}

sub notify {
    my $self = shift;
    my ($error, $option) = @_;

    $self->add_error($error);
    $self->send($option);
}

sub _url {
    my $self = shift;

    "https://airbrake.io/api/v3/projects/@{[$self->project_id]}/notices?key=@{[$self->api_key]}";
}

sub _conceal_options {
    my $self = shift;
    my ($option) = @_;

    for my $opt (qw(environment session params)) {
        for my $key (grep { /(?:cookie|password)/i } keys %{$option->{$opt}}) {
            $option->{$opt}{$key} =~ s/./*/g;
        }
    }
}

1;
__END__

=pod

=head1 NAME

Net::Airbrake - Airbrake Notifier API Client

=head1 SYNOPSIS

  use Net::Airbrake;

  my $airbrake = Net::Airbrake->new(
      api_key    => 'xxxxxxx',
      project_id => 9999999,
  );

  eval { die 'Oops' };
  $airbrake->notify($@);

=head1 DESCRIPTION

Net::Airbrake is a client of L<Airbrake|https://airbrake.io>.

=head1 METHODS

=head2 new(\%default)

=head2 add_error(\%error)

=head2 send(\%option)

=head2 notify(\%error, \%option)

=head1 SEE ALSO

Notifier API V3 - L<https://help.airbrake.io/kb/api-2/notifier-api-v3>

=head1 AUTHOR

Six Apart, Ltd. E<lt>sixapart@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
