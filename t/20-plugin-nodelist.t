#!/usr/bin/perl -w
use strict;
use Test::More tests => 5;

use vars qw( $wiki @all_nodes );
BEGIN {
  @all_nodes = qw(foo bar baz foo:bar foo:baz foo:foo 1 2 3 4 5 );

  use Test::MockObject;
  $wiki = Test::MockObject->new();
  $wiki->set_list('list_all_nodes',@all_nodes);
};

BEGIN {
  use_ok('CGI::Wiki::Simple');
};

{ package CGI::Wiki::Simple::Plugin::NodeListTest1;
  use strict;
  use Test::More;
  my $wiki = $main::wiki->clear;
  eval q!use CGI::Wiki::Simple::Plugin::NodeList( name => 'Test::Test1' )!;

  is_deeply([CGI::Wiki::Simple::Plugin::NodeList::retrieve_node(wiki => $wiki, name => 'Test::Test1')],
  ["<ul><li><a href='../display/1'>1</a></li>
<li><a href='../display/2'>2</a></li>
<li><a href='../display/3'>3</a></li>
<li><a href='../display/4'>4</a></li>
<li><a href='../display/5'>5</a></li>
<li><a href='../display/bar'>bar</a></li>
<li><a href='../display/baz'>baz</a></li>
<li><a href='../display/foo'>foo</a></li>
<li><a href='../display/foo:bar'>foo:bar</a></li>
<li><a href='../display/foo:baz'>foo:baz</a></li>
<li><a href='../display/foo:foo'>foo:foo</a></li>
<li><a href='../display/Test::Test1'>Test::Test1</a></li></ul>",0,""],"All nodes");
};

{ package CGI::Wiki::Simple::Plugin::NodeListTest2;
  use strict;
  use Test::More;
  my $wiki = $main::wiki->clear;
  eval q!use CGI::Wiki::Simple::Plugin::NodeList( name => 'Test::Test2', re => '^foo:(.*)$' )!;

  is_deeply([CGI::Wiki::Simple::Plugin::NodeList::retrieve_node(wiki => $wiki, name => 'Test::Test2')],
  ["<ul><li><a href='../display/foo:bar'>bar</a></li>
<li><a href='../display/foo:baz'>baz</a></li>
<li><a href='../display/foo:foo'>foo</a></li></ul>",0,""],"String re");
};

{ package CGI::Wiki::Simple::Plugin::NodeListTest3;
  use strict;
  use Test::More;
  my $wiki = $main::wiki->clear;
  eval q!use CGI::Wiki::Simple::Plugin::NodeList( name => 'Test::Test3', re => '^(foo:.*)$' )!;

  is_deeply([CGI::Wiki::Simple::Plugin::NodeList::retrieve_node(wiki => $wiki, name => 'Test::Test3')],
  ["<ul><li><a href='../display/foo:bar'>foo:bar</a></li>
<li><a href='../display/foo:baz'>foo:baz</a></li>
<li><a href='../display/foo:foo'>foo:foo</a></li></ul>",0,""],"Complete string re");
};

{ package CGI::Wiki::Simple::Plugin::NodeListTest4;
  use strict;
  use Test::More;
  my $wiki = $main::wiki->clear;
  eval q!use CGI::Wiki::Simple::Plugin::NodeList( name => 'Test::Test4', re => qr/foo:(.*)/ )!;

  is_deeply([CGI::Wiki::Simple::Plugin::NodeList::retrieve_node(wiki => $wiki, name => 'Test::Test4')],
  ["<ul><li><a href='../display/foo:bar'>bar</a></li>
<li><a href='../display/foo:baz'>baz</a></li>
<li><a href='../display/foo:foo'>foo</a></li></ul>",0,""],"qr() re");
};