package Sub::Spec::Wrapper::Clause::result_naked;

sub after_eval {
    my ($wrapper, $val) = @_;
    if ($val) {
        $wrapper->add_line('$res = [200, "OK", $res];');
    }
}

1;


__END__
=pod

=head1 NAME

Sub::Spec::Wrapper::Clause::result_naked

=head1 VERSION

version 0.01

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

