#!/usr/bin/perl -w
use strict;
use Test::More tests => 7;
use Test::Without::Module qw( HTML::Template );

BEGIN{ use_ok('CGI::Wiki::Simple') };

my $wiki = CGI::Wiki::Simple->new(
      PARAMS => { store => {}, header => "header", footer => "footer", style => "style"} # dummy store
   );
isa_ok($wiki, 'CGI::Wiki::Simple', "The created wiki");

for (qw(header footer style)) {
  is($wiki->param($_),$_,"Parameter '$_'");
};

$wiki = CGI::Wiki::Simple->new(
      PARAMS => { store => {}} # dummy store
   );
isa_ok($wiki, 'CGI::Wiki::Simple', "The created wiki");
is($wiki->param("style"),undef,"No preset style sheet");