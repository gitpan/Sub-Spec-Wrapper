package Sub::Spec::Wrapper;

use 5.010;
use strict;
use warnings;
use Log::Any '$log';

use Data::Dump::OneLine qw(dump1);
use Scalar::Util qw(blessed refaddr);
use Sub::Spec::Util;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(wrap_sub);

our $VERSION = '0.05'; # VERSION

our %SPEC;

$SPEC{wrap_sub} = {
    summary => 'Wrap subroutine to its implement Sub::Spec clauses',
    result => 'code',
    result_naked => 1,
    description => <<'_',

Will wrap subroutine with codes that implement Sub::Spec clauses, like ~timeout~
(using Perl's eval block), ~args~ (using Sah schema), etc. Will bless subroutine
(into ~Sub::Spec::Wrapped~) to mark that the subroutine has been wrapped.

Will not wrap again if input subroutine has already been wrapped (blessed),
unless ~force~ argument is set to true.

_
    required_args => [qw/sub spec/],
    args => {
        sub => ['code*' => {
            summary => 'The code to wrap',
        }],
        spec => ['hash*' => {
            summary => 'The sub spec',
        }],
        force => ['bool' => {
            summary => 'Whether to force wrap again even '.
                'when sub has been wrapped',
            default => 0,
        }],
    },
};
sub wrap_sub {
    my %args  = @_;
    my $sub   = $args{sub}   or die "Please specify sub";
    my $spec  = $args{spec}  or die "Please specify spec";
    my $force = $args{force};

    return $sub if blessed($sub) && !$force;

    # put the sub in a named variable, so it can be accessed by the wrapper
    # code.
    my $subname = "Sub::Spec::Wrapped::sub".refaddr($sub);
    {
        no strict 'refs';
        ${$subname} = $sub;
    }

    my $wrapper = __PACKAGE__->new(args=>\%args, spec=>$spec);
    $wrapper->add_line(
        'package Sub::Spec::Wrapped;',
        'sub {',
    );

    my $args_as = $spec->{args_as} // "hash";
    my $args_var = Sub::Spec::Util::parse_args_as($args_as)->{args_var};
    my $args_line;
    if ($args_as eq 'hash') {
        $args_line = 'my %args = @_;';
    } elsif ($args_as eq 'hashref') {
        $args_line = 'my $args = {@_};';
    } elsif ($args_as =~ /\A(arrayref|array)\z/) {
        # temp, eventually will use codegen_convert_args_to_array()
        $wrapper->add_line(
            '    require Sub::Spec::ConvertArgs::Array;',
            '    my $ares = Sub::Spec::ConvertArgs::Array::'.
                'convert_args_to_array(args=>{@_}, spec=>'.dump1($spec).');',
            '    return $ares if $ares->[0] != 200;',
            );
        if ($args_as eq 'array') {
            $args_line = 'my @args = @{$ares->[2]};';
        } else {
            $args_line = 'my $args = $ares->[2];';
        }
    } elsif ($args_as eq 'object') {
        die "Sorry, args_as 'object' is not supported yet";
    } else {
        die "Invalid args_as: $args_as, must be hash/hashref/".
            "array/arrayref/object";
    }
    $wrapper->add_line("    $args_line");

    $wrapper->add_line(
        '    my $res;',
    );

    $wrapper->call_handlers("before_eval", $spec);
    $wrapper->add_line('eval {');
    $wrapper->call_handlers("before_call", $spec);
    $wrapper->add_line('$res = $'.$subname."->($args_var);");
    $wrapper->add_line('};');
    $wrapper->add_line(
        '    my $eval_err = $@;',
        '    if ($eval_err) { return [500, "Sub died: $eval_err"] }',
    );
    $wrapper->call_handlers("after_eval", $spec);
    $wrapper->add_line(
        '    $res;',
        '}',
    );
    if ($log->is_trace) {
        $log->trace("wrapper code: ".join("\n", @{$wrapper->{code}}));
    }
    $wrapper->compile;
}

# oo interface
sub new {
    my ($class, %args) = @_;
    bless \%args, $class;
}

sub spec { $_[0]->{spec} }

sub args { $_[0]->{args} }

sub call_handlers {
    my ($self, $phase_name, $spec) = @_;

    $log->tracef("call_handlers(phase=%s)", $phase_name);
    for my $clause (keys %$spec) {
        my $pn = "Sub::Spec::Wrapper::Clause::$clause";
        my $pnp = $pn; $pnp =~ s!::!/!g; $pnp .= ".pm";
        eval { require $pnp };
        next if $@;
        #$log->trace("Package $pn exists");
        my $hn = "$pn\::$phase_name";
        next unless defined &{$hn};
        #$log->trace("Sub $hn exists");
        $log->tracef("Calling %s(%s)", $hn, $spec->{$clause});
        my $h = \&{$hn};
        $h->($self, $spec->{$clause});
    }
}

sub add_line {
    my ($self, @lines) = @_;
    $self->{code} //= [];
    push @{$self->{code}}, @lines;
}

sub compile {
    my ($self, @lines) = @_;
    my $res = eval join "\n", @{$self->{code}};
    die "BUG: Wrapper code can't be compiled: $@" if $@;
    $res;
}

1;
# ABSTRACT: Wrap subroutine to its implement Sub::Spec clauses


__END__
=pod

=head1 NAME

Sub::Spec::Wrapper - Wrap subroutine to its implement Sub::Spec clauses

=head1 VERSION

version 0.05

=head1 SYNOPSIS

 use Sub::Spec::Wrapper qw(wrap_sub);
 my $sub = wrap_sub(sub => sub {die "test\n"}, spec=>{});
 my $res = $sub->(); # [500, "Sub died: test"]

=head1 DESCRIPTION

B<NOTICE>: This module and the L<Sub::Spec> standard is deprecated as of Jan
2012. L<Rinci> is the new specification to replace Sub::Spec, it is about 95%
compatible with Sub::Spec, but corrects a few issues and is more generic.
C<Perinci::*> is the Perl implementation for Rinci and many of its modules can
handle existing Sub::Spec sub specs.

WARNING: PRELIMINARY VERSION, NOT EVERYTHING DESCRIBED IS IMPLEMENTED

This module provides wrap_sub() that implements/utilizes many spec clauses, like
C<args>, C<result>, C<timeout>, etc, via wrapping.

This module uses L<Log::Any> for logging.

=head1 FUNCTIONS

None are exported, but they are exportable.

=head2 wrap_sub(%args) -> RESULT


Wrap subroutine to its implement Sub::Spec clauses.

Will wrap subroutine with codes that implement Sub::Spec clauses, like ~timeout~
(using Perl's eval block), ~args~ (using Sah schema), etc. Will bless subroutine
(into ~Sub::Spec::Wrapped~) to mark that the subroutine has been wrapped.

Will not wrap again if input subroutine has already been wrapped (blessed),
unless ~force~ argument is set to true.

Arguments (C<*> denotes required arguments):

=over 4

=item * B<force> => I<bool> (default C<0>)

Whether to force wrap again even when sub has been wrapped.

=item * B<spec>* => I<hash>

The sub spec.

=item * B<sub>* => I<code>

The code to wrap.

=back

=head1 SEE ALSO

L<Sub::Spec>

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

