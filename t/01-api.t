#!/usr/bin/perl -w
use strict;
use Test::More;

use vars qw( @methods );
BEGIN {
  plan( tests => 9 );
  use_ok('CGI::Wiki::Simple');
  use_ok('CGI::Wiki::Simple::NoTemplates');

  @methods = qw(setup teardown inside_link);
};

my $wiki = CGI::Wiki::Simple->new(
      PARAMS => { store => {} } # dummy store
   );
isa_ok($wiki, 'CGI::Wiki::Simple', "Got a CGI::Wiki::Simple");
isa_ok($wiki, 'CGI::Application', "It's also a CGI::Application");

isa_ok($wiki->wiki, 'CGI::Wiki', '$wiki->wiki');

$wiki = CGI::Wiki::Simple::NoTemplates->new(
      PARAMS => { store => {} } # dummy store
   );
isa_ok($wiki, 'CGI::Wiki::Simple::NoTemplates', "Got a CGI::Wiki::Simple::NoTemplate");
isa_ok($wiki, 'CGI::Application', "It's also a CGI::Application");

can_ok($wiki, @methods);

isa_ok($wiki->wiki, 'CGI::Wiki', '$wiki->wiki');


