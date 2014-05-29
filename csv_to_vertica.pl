#!/usr/bin/env perl
#================================================
# Convert CSV file to Vertica input file format
#================================================

while (<>) {
	chomp;
	my @row = split /;/, $_, -1;
	my @newrow = ();
	foreach (@row) {
		my $is_string = s/^"(.*)"$/\1/;
		s/\\/\\\\/g;
		s/""/\\"/g;
		push @newrow, $is_string ? "\"$_\"" : $_;
	}
	print join(";", @newrow)."\n";
}

