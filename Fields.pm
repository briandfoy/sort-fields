package Sort::Fields;

use strict;
use vars qw($VERSION @ISA @EXPORT);

require Exporter;
require AutoLoader;

@ISA = qw(Exporter AutoLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	fieldsort
);
$VERSION = '0.01';

use Carp;

sub fieldsort {
	my ($sep, $cols);
	if (ref $_[0]) {
		$sep = '\\s+'
	} else {
		$sep = shift;
	}
	unless (ref($cols = shift) eq 'ARRAY') {
		croak "fieldsort columns must be in anon array";
	}
	my (@sortcode, @col);
	my $level = 1;
	my $maxcol = -1;
	for (@$cols) {
		my ($a, $b) = /^-/ ? qw(b a) : qw(a b);
		my $op = /n$/ ? '<=>' : 'cmp';
		my ($col) = /(\d+)/;
		if ($col == 0) {  # column 0 gives the entire string
			push @sortcode, "\$${a}->[0] $op \$${b}->[0]";
			next;
		} 
		push @col, (/(\d+)/)[0] - 1;
		$maxcol = $col[-1] if $maxcol < $col[-1];
		push @sortcode, "\$${a}->[$level] $op \$${b}->[$level]";
		$level++;
	}
	my $sortfunc = eval "sub { " . join (" or ", @sortcode) . " } ";
	if ($@) {
		die "eval failed in fieldsort (internal error?)";
	}
	my $splitfunc = eval 'sub { (split /$sep/o, $_, $maxcol + 2)[@col] } ';
	if ($@) {
		croak "probable regexp error in fieldsort arg: /$sep/o";
	}
	return
		map $_->[0],
		sort { $sortfunc->() }
		map [$_, $splitfunc->($_)],
		@_;
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Sort::Fields - Sort lines containing delimited fields

=head1 SYNOPSIS

  use Sort::Fields;
  @sorted = fieldsort [3, '2n'], @lines;
  @sorted = fieldsort '\+', [-1, -3, 0], @lines;

=head1 DESCRIPTION

Sort::Fields provides a general purpose technique for efficiently sorting
lists of lines that contain data separated into fields.

Sort::Fields automatically imports a single subroutine, fieldsort.

The first argument to fieldsort is a delimiter string, which is
used as a regular expression argument for a C<split> operator.  The
delimiter string is optional.  If it is not supplied, fieldsort
splits each line using C</\s+/>.

The second argument is an array reference containing one or more 
field specifiers.  The specifiers indicate what fields in the strings
will be used to sort the data.  The specifier "1" indicates the first
field, "2" indicates the second, and so on.  A negative specifier
like "-2" means to sort on the second field in reverse (descending)
order.  To indicate a numeric rather than alphabetic comparison,
append "n" to the specifier.  A specifier of "0" means the entire
string ("-0" means the entire string, in reverse order).

The order in which the specifiers appear is the order in which they
will be used to sort the data.  The primary key is first, the secondary
key is second, and so on.

The remaining arguments are the data to be sorted.

=head1 EXAMPLES

Some sample data (in array C<@data>):

  123   asd   1.22   asdd
  32    ewq   2.32   asdd
  43    rewq  2.12   ewet
  51    erwt  34.2   ewet
  23    erww  4.21   ewet
  91    fdgs  3.43   ewet
  123   refs  3.22   asdd
  123   refs  4.32   asdd

  # alpha sort on column 1
  print fieldsort [1], @data;

  123   asd   1.22   asdd
  123   refs  3.22   asdd
  123   refs  4.32   asdd
  23    erww  4.21   ewet
  32    ewq   2.32   asdd
  43    rewq  2.12   ewet
  51    erwt  34.2   ewet
  91    fdgs  3.43   ewet

  # numeric sort on column 1
  print fieldsort ['1n'], @data;

  23    erww  4.21   ewet
  32    ewq   2.32   asdd
  43    rewq  2.12   ewet
  51    erwt  34.2   ewet
  91    fdgs  3.43   ewet
  123   asd   1.22   asdd
  123   refs  3.22   asdd
  123   refs  4.32   asdd

  # reverse numeric sort on column 1
  print fieldsort ['-1n'], @data;

  123   asd   1.22   asdd
  123   refs  3.22   asdd
  123   refs  4.32   asdd
  91    fdgs  3.43   ewet
  51    erwt  34.2   ewet
  43    rewq  2.12   ewet
  32    ewq   2.32   asdd
  23    erww  4.21   ewet

  # alpha sort on column 2, then alpha on entire line
  print fieldsort [2, 0], @data;

  123   asd   1.22   asdd
  51    erwt  34.2   ewet
  23    erww  4.21   ewet
  32    ewq   2.32   asdd
  91    fdgs  3.43   ewet
  123   refs  3.22   asdd
  123   refs  4.32   asdd
  43    rewq  2.12   ewet

  # alpha sort on column 4, then numeric on column 1, then reverse
  # numeric on column 3
  print fieldsort [4, '1n', '-3n'], @data;

  32    ewq   2.32   asdd
  123   refs  4.32   asdd
  123   refs  3.22   asdd
  123   asd   1.22   asdd
  23    erww  4.21   ewet
  43    rewq  2.12   ewet
  51    erwt  34.2   ewet
  91    fdgs  3.43   ewet

  # now, splitting on either literal period or whitespace
  # sort numeric on column 4 (fractional part of decimals) then
  # numeric on column 3 (whole part of decimals)
  print fieldsort '(?:\.|s+)', ['4n', '3n'], @data;

  51    erwt  34.2   ewet
  43    rewq  2.12   ewet
  23    erww  4.21   ewet
  123   asd   1.22   asdd
  123   refs  3.22   asdd
  32    ewq   2.32   asdd
  123   refs  4.32   asdd
  91    fdgs  3.43   ewet

  # alpha sort on column 4, then numeric on the entire line
  # NOTE: produces warnings under -w
  print fieldsort [4, '0n'], @data;

  32    ewq   2.32   asdd
  123   asd   1.22   asdd
  123   refs  3.22   asdd
  123   refs  4.32   asdd
  23    erww  4.21   ewet
  43    rewq  2.12   ewet
  51    erwt  34.2   ewet
  91    fdgs  3.43   ewet


=head1 BUGS

"TRIAL BALLOON VERSION" -- no tests!

Perhaps something should be done to catch things like:

  fieldsort '.', [1, 2], @lines;

C<'.'> translates to C<split /./> -- probably not what you want.

Passing blank lines and/or lines containing the wrong kind of
data (alphas instead of numbers) can result in copious warning messages
under C<-w>.

If the regexp contains memory parentheses (C<(...)> rather than C<(?:...)>),
split will function in "delimiter retention" mode, capturing the
contents of the parentheses as well as the stuff between the delimiters.
I could imagine how this could be useful, but on the other hand I
could also imagine how it could be confusing if encountered unexpectedly.
Caveat sortor.

=head1 AUTHOR

Joseph N. Hall, joseph@5sigma.com

=head1 SEE ALSO

perl(1).

=cut
