#!perl -w
use strict;

use Findbin;
my $base;
BEGIN {
  $base = $Findbin::bin || ".";
  unshift @INC, "$base/../lib"
};

use CGI;
use CGI::Carp qw( fatalsToBrowser );# Remove in production !
use CGI::Wiki::Simple;
use CGI::Wiki::Store::SQLite;
#use CGI::Wiki::Store::MySQL;

use CGI::Wiki::Simple::Plugin::Static( Welcome  => "There is an <a href='entrance'>entrance</a>. Speak <a href='Friend'>Friend</a> and <a href='Enter'>Enter</a>.",
                                         Enter    => "The <a href='entrance'>entrance</a> stays closed.",
                                         entrance => "It's a big and strong door.",
                                         Friend   => "You enter the deep dungeons of <a href='Moria'>Moria</a>.",
                                         );
use CGI::Wiki::Simple::Plugin::NodeList( name => 'AllNodes' );
use CGI::Wiki::Simple::Plugin::NodeList( name => 'AllCategories', re => '^Category:(.*)' );

# Ugly Perl 5.4 hack to get all of this working with my ISP!
Class::Delegation::INIT() if ($] < 5.006);

my $store = CGI::Wiki::Store::SQLite->new( dbname => "$base/mywiki.db" );
#my $store = CGI::Wiki::Store::MySQL->new( dbname => "test",
#                                          dbuser => "master",
#                                          dbpass => "master" );

# This is a quick check whether we can see the database
#$store->retrieve_node("index");

my $search = undef;
my $wiki = CGI::Wiki::Simple->new( TMPL_PATH => "$base/../templates",
                                   PARAMS => {
                                        store => $store,
                                      } )->run;