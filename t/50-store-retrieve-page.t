#!/usr/bin/perl -w
use strict;
use FindBin;
use File::Spec;
use Test::More tests => 22;
use CGI;
use CGI::Carp;
use CGI::Wiki::TestConfig;
use DBI;
use Test::Without::Module qw( HTML::Template );
use Test::HTML::Content;

use vars qw( $cgi $wiki );

$^W = undef;

sub get_cgi_response {
  my $result = $wiki->run;
  my ($headers,$body) = split( /\015\012\015\012/ms, $result, 2);
  $headers = HTTP::Headers->new( map { /^(.*?): (.*)$/ ? ($1,$2) : () } split( /\r\n/, $headers ));
  my $response = HTTP::Response->new( 200, 'Testing', $headers, $body );
  $response;
};

SKIP: {

  BEGIN {
    eval { require HTTP::Response; };
    skip "Need HTTP::Response to test CGI interaction", 5
      if $@;
  };
  BEGIN {
    eval { 
      require DBD::SQLite;
      require CGI::Wiki::Setup::SQLite;
      require CGI::Wiki::Store::SQLite;
    };
    skip "Need SQLite to test CGI interaction", 5
      if $@;
  };

  BEGIN{ use_ok( "CGI::Wiki::Simple" ) };
  *CGI::Wiki::Simple::cgiapp_get_query = sub { $cgi };

  my $dbfile = $0;
  $dbfile =~ s/\.t$/.db/;

  diag "Creating test database $dbfile";
  CGI::Wiki::Setup::SQLite::cleardb($dbfile)
    if -f $dbfile;
  CGI::Wiki::Setup::SQLite::setup($dbfile);

  # Put in the test data.
  my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile", "", "",
                     { PrintError => 1, RaiseError => 1, AutoCommit => 1 } )
      or die "Couldn't connect to database: " . DBI->errstr;
  $dbh->disconnect;

  # get a wiki store :
  my $store = CGI::Wiki::Store::SQLite->new( dbname => $dbfile );
  isa_ok( $store, 'CGI::Wiki::Store::Database' );
  my $search = undef;

  $ENV{SCRIPT_NAME} = '/wiki/test';
  $ENV{CGI_APP_RETURN_ONLY} = "testing";

  # Set up the environment as to fake a real CGI environment :
  $cgi = CGI->new('');
  $cgi->path_info('/display/foo');

  # Now let our app run on the database :
  $wiki = CGI::Wiki::Simple->new( TMPL_PATH => 'templates',
    PARAMS => { store => $store, search => $search } );
  isa_ok( $wiki, "CGI::Wiki::Simple" );

  my $response = get_cgi_response();

  # Now check that our output looks like we intended :
  is( $response->header('Title'), "foo", "Title header" );
  like( $response->header('Content-type'), qr"^text/html", "Content type text/html" );
  # Ugh. RE-HTML-parsing. I gotta finish the port of Test::HTML::Content to XPath
  like($response->content, qr!<title>foo</title>!i, 'Title tag');
  like( $response->content, qr'<hr /><hr />', "Empty response wiki content");
  link_ok($response->content,'/wiki/test/preview/foo',"Edit link");
  no_link($response->content,'/wiki/test/display/foo',"No display link");
  # I also need form actions in T:H:C ...
  no_tag($response->content,'form', { action => '/wiki/test/commit/foo' },"Commit link");

  # Test our default page setup
  link_ok($response->content,'http://search.cpan.org/search?mode=module&query=CGI::Wiki',"CGI::Wiki link");
  tag_ok($response->content,'form', { action => '/wiki/test' },"Searchbox");

  # Now submit new content
  $cgi = CGI->new(*DATA);
  $cgi->path_info('/commit/foo');

  $wiki = CGI::Wiki::Simple->new( TMPL_PATH => 'templates',
    PARAMS => { store => $store, search => $search } );
  isa_ok( $wiki, "CGI::Wiki::Simple" );

  $response = get_cgi_response();
  is($response->header('Status'),'302 Moved','Redirect after edit');
  is($response->header('Location'),'/wiki/test/display/foo','Redirect url after edit');

  # Look at the edit page
  $cgi = CGI->new(*DATA);
  $cgi->path_info('/preview/foo');

  $wiki = CGI::Wiki::Simple->new( TMPL_PATH => 'templates',
    PARAMS => { store => $store, search => $search } );
  isa_ok( $wiki, "CGI::Wiki::Simple" );
  $response = get_cgi_response();

  no_link($response->content,'/wiki/test/preview/foo',"No edit link (edit page)");
  link_ok($response->content,'/wiki/test/display/foo',"Display link (edit page)");
  like($response->content,qr'\bTesting setting a new value\b','Editbox content');

  # Check that we receive the new content back
  $cgi = CGI->new(*DATA);
  $cgi->path_info('/display/foo');

  $wiki = CGI::Wiki::Simple->new( TMPL_PATH => 'templates',
    PARAMS => { store => $store, search => $search } );
  isa_ok( $wiki, "CGI::Wiki::Simple" );

  $response = get_cgi_response();
  is($response->header('Title'),'foo','Title');
  like( $response->content, qr'\bTesting setting a new value\b', "Filled wiki content");

  # Check for munging of HTML entities

  # Now edit the page again
  # Check the page title
  # Check the page headers
  # Submit it with a wrong MD5
  # And check that we end up on the conflict page

  # Add a test for sub render() :
  #   render with empty action list should return three no_link/no_tags
  #   render with combined action list should return the correct links/tags
  #   render with empty action list should return three no_link/no_tags
}

__DATA__
content=Testing%20setting%20a%20new%20value%0D%0A
save=commit
checksum=d41d8cd98f00b204e9800998ecf8427e
=
