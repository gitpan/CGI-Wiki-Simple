#!/usr/bin/perl -w
use strict;
use FindBin;
use File::Spec;
use Test::More tests => 12;

BEGIN {
  use_ok( "CGI::Wiki" );
  use_ok( "CGI::Wiki::Simple::Setup" );
};

SKIP: {

eval {
    require DBD::SQLite;
    require CGI::Wiki::Setup::SQLite;
    require CGI::Wiki::Store::SQLite;
};
skip "Need SQLite to test CGI interaction", 10
  if $@;

my $dbname = 'test_mywiki.db';

# We need a fresh start !
unlink $dbname if -f $dbname;

CGI::Wiki::Simple::Setup::setup( dbname => $dbname, dbtype => 'sqlite' );
ok( -f $dbname, 'SQLite db was generated' );

sub one_connection(&) {
  my $store = CGI::Wiki::Store::SQLite->new( dbname => $dbname );
  isa_ok( $store, 'CGI::Wiki::Store::Database' );
  my $search = undef;
  my $wiki = CGI::Wiki->new( store => $store, search => $search );

  shift->($store,$wiki);

  undef $wiki;
  $store->dbh->disconnect;
};

# get a wiki store :
my @nodes;
one_connection { @nodes = $_[1]->list_all_nodes };
cmp_ok(scalar @nodes, '>', 0, "Stored some initial nodes");
my $initial_node_count = @nodes;

one_connection {
  CGI::Wiki::Simple::Setup::commit_content( wiki => $_[1],
    nodes => [ { title => '__non_existing_test_node', content => "Created by $0" } ] );
  @nodes = $_[1]->list_all_nodes;
};
is(scalar @nodes, $initial_node_count+1, "Stored one additional node");

{
  my $warned;
  local $SIG{__WARN__} = sub { $warned++ };
  CGI::Wiki::Simple::Setup::setup( dbname => $dbname, dbtype => 'sqlite', force => 0 );
  is($warned, $initial_node_count, "We warn instead of overwriting existing nodes");
};

one_connection {
  @nodes = $_[1]->list_all_nodes;
};
is(scalar @nodes, $initial_node_count+1, "Node count stays the same");

CGI::Wiki::Simple::Setup::setup( dbname => $dbname, dbtype => 'sqlite', clear => 1 );
one_connection {
  @nodes = $_[1]->list_all_nodes;
};
is(scalar @nodes, $initial_node_count, "Clear wipes all content");

unlink $dbname
  or diag "Couldn't remove $dbname : $!";

};
