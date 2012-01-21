package Sub::Spec::Wrapper::Clause::timeout;

sub before_call {
    my ($wrapper, $val) = @_;
    if ($val > 0) {
        $wrapper->add_line(
            'local $SIG{ALRM} = sub { die "Timed out\n" };',
            'alarm('.($val+0).');'
        );
    }
}

sub after_call {
    my ($wrapper, $val) = @_;
    if ($val > 0) {
        $wrapper->add_line('alarm(0);');
    }
}

1;

__END__
=pod

=head1 NAME

Sub::Spec::Wrapper::Clause::timeout

=head1 VERSION

version 0.05

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

