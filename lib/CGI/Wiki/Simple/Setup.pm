package CGI::Wiki::Simple::Setup;

use strict;

use CGI::Wiki;
use CGI::Wiki::Simple;
use Carp qw(croak);
use Digest::MD5 qw( md5_hex );

use vars qw($VERSION @NODES);

$VERSION = 0.08;

=head1 NAME

CGI::Wiki::Simple::Setup - Set up the wiki and fill content into some basic pages.

=head1 DESCRIPTION

This is a simple utility module that given a database sets up a complete wiki within it.

=head1 SYNOPSIS

=for example begin

  setup( dbname => "mywiki.db" );
  # This sets up a SQLite wiki within the file mywiki.db

=for example end

=cut

sub get_sqlite_store {
  my %args = @_;

  require CGI::Wiki::Store::SQLite;
  require CGI::Wiki::Setup::SQLite;

  if ($args{setup}) {
    CGI::Wiki::Setup::SQLite::cleardb($args{dbname})
      if $args{clear};
    CGI::Wiki::Setup::SQLite::setup($args{dbname})
  };

  # get the wiki store :
  my $store = CGI::Wiki::Store::SQLite->new( dbname => $args{dbname} );
  warn "Couldn't get store for $args{dbname}" unless $store;

  if ($args{check}) {
    $store->retrieve_node("index");
  };

  return $store;
};

sub get_store {
  my %args = @_;

  if ($args{dbtype} =~ /^sqlite$/i) {
    get_sqlite_store(%args);
  };
};

sub setup_if_needed {
  my %args = @_;

  eval { get_store( %args, check => 1 ); };
  setup(%args) if $@;
};

sub setup {
  my %args = @_;

  croak "No dbtype given"
    unless $args{dbtype};

  croak "Unknown database type $args{dbtype}"
    unless $args{dbtype} =~ /^sqlite$/i; # add mysql !

  my $store = get_store( %args, setup => 1 );
  print "Loading content\n";
  my $wiki = CGI::Wiki->new(
             store  => $store,
             search => undef );

  unless (@NODES) {
    @NODES = map {
      /^Title:\s+(.*?)\r?\n(.*)/ms
      ? { title => $1, content => $2 }
      : ()
    } do { undef $/; split /__NODE__/, <DATA> };
  };

  commit_content( %args, wiki => $wiki, nodes => [@NODES], );

  undef $wiki;
  $store->dbh->disconnect;
};

sub commit_content {
  my %args = @_;
  my $wiki = $args{wiki};
  my @nodes = @{$args{nodes}};
  foreach my $node (@nodes) {
    my $title = $node->{title};

    my %old_node = $wiki->retrieve_node($title);
    if (not $old_node{content} or $args{force}) {
      my $content = $node->{content};
      $content =~ s/\r\n/\n/g;
      my $cksum = $old_node{checksum};
      my $written = $wiki->write_node($title, $content, $cksum);
      if ($written) {
        #print "(Re)initialized node '$title'\n";
      } else {
        warn "Node '$title' not written\n";
      };
    } else {
      warn "Node '$title' already contains data. Not overwritten.";
      #warn $old_node{content};
    };
  };
};

=head1 COPYRIGHT

     Copyright (C) 2003 Max Maischein.  All Rights Reserved.

This code is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<CGI::Wiki>, L<CGI::Wiki::Simple>

=cut

__DATA__
__NODE__
Title: index
This is the main page of your new wiki. It was preset
by the automatic content setup.

If your wiki will be accessible to the general public, you might want
to make this node read only by loading the [CGI::Wiki::Simple::Plugin::Static]
plugin for this node :

     use CGI::Wiki::Simple::Plugin::Static index => 'Text for the index node';

This node was loaded initially by the setup program among other nodes :

     * [Wiki Howto]
     * [CGI::Wiki::Simple]
__NODE__
Title: Wiki Howto

This is a wiki, things are simple :

    1. Everybody can edit any node.
    2. Linking between nodes is done by putting the text in square brackets.
    3. Lists are created by indenting stuff 4 spaces.
    4. Paragraphs are delimited by an empty line
    5. Dividers are "----"

Some examples :

    * An unordered list

    1. First item
    2. Second item
    3. third item

    a. Another
    b. List

Some normal text. Note that
line
breaks
happen where you type them and where
they seem necessary.

    Some(code);
      in some programming language

[A Link]. [With a different target node|Another link]

Have fun.


__NODE__
Title: CGI::Wiki::Simple

This wiki is powered by CGI::Wiki::Simple (at http://search.cpan.org/search?mode=module&query=CGI::Wiki::Simple ).
CGI::Wiki::Simple was written by Max Maischein (cgi-wiki-simple@corion.net). Please report bugs
through the CPAN RT at http://rt.cpan.org/NoAuth/Bugs.html?Dist=CGI-Wiki-Simple .

CGI::Wiki::Simple again is based on CGI::Wiki (at http://search.cpan.org/search?mode=module&query=CGI::Wiki )
by Kate Plugh.

