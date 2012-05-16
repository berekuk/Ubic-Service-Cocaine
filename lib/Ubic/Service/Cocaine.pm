package Ubic::Service::Cocaine;

# ABSTRACT: run cocaine as Ubic service

=head1 SYNOPSIS

    # /etc/ubic/service/cocaine.ini:
        module = Ubic::Service::Cocaine
        [options]
        endpoint = tcp://*:5000
        storage_driver = files
        storage_uri = /var/lib/cocaine

    # alternatively, here's the perl code which you can put into /etc/ubic/service/cocaine:
    use Ubic::Service::Cocaine;
    Ubic::Service::Cocaine->new({
        endpoint => 'tcp://*:5000',
        storage_driver => 'files',
        storage_uri => '/var/lib/cocaine',
    });

=head1 DESCRIPTION

This module provides the syntax sugar for running L<https://github.com/cocaine/cocaine-core> as ubic service.

Daemon's user is always B<cocaine>.

=cut

use strict;
use warnings;

use Ubic::Daemon qw(:all);

use parent qw(Ubic::Service::SimpleDaemon);

use Params::Validate qw(:all);

my %opt2arg = ();
for my $arg (qw(
    storage:driver
    storage:uri
    core:modules
    core:announce-endpoint
    core:announce-interval
    core:port-range
)) {
    my $opt = $arg;
    $opt =~ s/:/_/g;
    $opt =~ s/-/_/g;
    $opt2arg{$opt} = $arg;
}

=head1 CONSTRUCTOR

There is one mandatory parameter: I<endpoint>.

Optional parameters are: I<storage_driver>, I<storage_uri>, I<core_modules>, I<core_announce_endpoint>, I<core_port_range> and I<core_announce_interval>. There's also a boolean I<verbose> option.

=cut

sub new {
    my $class = shift;

    my $params = validate(@_, {
        endpoint        => { type => SCALAR },
        (
            map {
                $_ => { type => SCALAR, optional => 1 },
            } keys %opt2arg,
        ),
        verbose => { type => BOOLEAN, optional => 1 },
    });

    my $bin = [
        '/usr/bin/cocained',
        $params->{endpoint},
        ($params->{verbose} ? '--verbose' : ()),
        map {
            (defined($params->{$_}) ? ("--$opt2arg{$_}" => $params->{$_}) : ()),
        } keys %opt2arg,
    ];

    return $class->SUPER::new({
        bin => $bin,
        user => 'cocaine',
    });
}

sub start_impl {
    my $self = shift;
    unless (-d '/var/run/cocaine') {
        mkdir('/var/run/cocaine') or die "Can't create dir: $!";
    }
    $self->SUPER::start_impl(@_);
}

sub reload {
    my ( $self ) = @_;
    my $status = check_daemon($self->pidfile) or die 'not running';
    kill HUP => $status->pid;

    return 'reloaded';
}

=head1 TODO

As soon as Ubic will begin supporting yaml/json configs, we should replace C<core_blah> options with two-level C<< { core => { blah => ... } } >> options.

TCP check would be useful.

User and other SimpleDaemon parameters should be customizable.

=cut
1;

