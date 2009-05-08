#!/usr/bin/perl
use strict;
use 5.008_001;

package GCal::QuickAdd;
use Net::Google::Calendar 0.97;
use Any::Moose;
use YAML;

has gcal => (
    is => 'rw', isa => "Net::Google::Calendar",
    default => sub { Net::Google::Calendar->new },
    lazy => 1,
);

has config => (
    is => 'rw', isa => "HashRef",
);

has configfile => (
    is => 'rw', isa => "Str",
    default => "$ENV{HOME}/.gcal-quickadd.yml",
);

has username => (
    is => 'rw', isa => "Str",
);

has token => (
    is => 'rw', isa => "Str",
);

sub run {
    my $self = shift;
    my @args = @_;
    my $text = join " ", @args or die "Usage: gcal-quickadd.pl [some free text]\n";

    $self->init_authentication;
    $self->post_event($text);
}

sub post_event {
    my $self = shift;
    my($text) = @_;

    my $entry = Net::Google::Calendar::Entry->new;
    $entry->content($text);
    $entry->quick_add(1);

    my $res = $self->gcal->add_entry($entry) or die $@;
    printf "Event '%s' created at %s.\n", $res->title, ($res->when)[0]->set_time_zone('local');
}

sub init_authentication {
    my $self = shift;

    if (my $config = eval { YAML::LoadFile($self->configfile) }) {
        $self->config($config);
        $self->gcal->auth($self->config->{username}, $self->config->{token});
        $self->gcal->auth_object->auth_type(Net::Google::AuthSub::CLIENT_LOGIN);
        return 1;
    }

    require Term::Prompt;
    my $username = Term::Prompt::prompt('s' => 'Your Google Email:', '', '', sub { shift =~ /\S/ });
    my $password = Term::Prompt::prompt(p => 'Password:', '', '');
    print "\n"; # ohmy

    unless ($username =~ /\@/) {
        $username .= '@gmail.com';
    }

    $self->gcal->login($username, $password);

    if ($self->gcal->auth_object->authorised) {
        $self->config({ username => $username, token => $self->gcal->auth_object->auth_token });
        YAML::DumpFile($self->configfile, $self->config);
    } else {
        die "Google AuthSub authentication failed.\n";
    }
}

package main;
GCal::QuickAdd->new->run(@ARGV);

__END__

=head1 NAME

gcal-quickadd.pl - Quick-adds an event to your Google Calendar from command line

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 LICENSE

Same as Perl (Artistic and GPL).

=cut

