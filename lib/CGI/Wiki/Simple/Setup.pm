package CGI::Wiki::Simple::Setup;

use strict;

use CGI::Wiki;
use CGI::Wiki::Simple;
use Carp qw(croak);
use Digest::MD5 qw( md5_hex );

use vars qw($VERSION @NODES);

$VERSION = 0.10;

=head1 NAME

CGI::Wiki::Simple::Setup - Set up the wiki and fill content into some basic pages.

=head1 DESCRIPTION

This is a simple utility module that given a database sets up a complete wiki within it.

=head1 SYNOPSIS

=for example begin

  setup( dbtype => 'sqlite', dbname => "mywiki.db" );
  # This sets up a SQLite wiki within the file mywiki.db

=for example end

=cut

my %stores = (
  sqlite => 'SQLite',
  mysql  => 'MySQL',
  pg     => 'Pg',
);

sub get_store {
  my %args = @_;

  my @setup_args;
  my $dbtype;

  push @setup_args, $args{dbname};
  for (qw(dbuser dbpass)) {
    push @setup_args, $args{$_}
      if exists $args{$_};
  };

  $dbtype = delete $args{dbtype};

  croak "Unknown database type $dbtype"
    unless exists $stores{lc($dbtype)};
  $dbtype = $stores{lc($dbtype)};

  eval "use CGI::Wiki::Store::$dbtype; use CGI::Wiki::Setup::$dbtype";

  if ($args{setup}) {
    no strict 'refs';
    &{"CGI::Wiki::Setup::${dbtype}::cleardb"}(@setup_args)
      if $args{clear};
    &{"CGI::Wiki::Setup::${dbtype}::setup"}(@setup_args);
  };

  # get the wiki store :
  my $store = "CGI::Wiki::Store::$dbtype"->new( %args );
  warn "Couldn't get store for $args{dbname}" unless $store;

  $store->retrieve_node("index")
    if ($args{check});

  return $store;
};

sub setup_if_needed {
  my %args = @_;

  my $store;
  eval { $store = get_store( %args, check => 1 ); };
  setup(%args) if $@ or ! $store;
};

sub setup {
  my %args = @_;

  croak "No dbtype given"
    unless $args{dbtype};

  my $store = get_store( %args, setup => 1 );
  unless ($args{nocontent}) {
    print "Loading content\n"
      unless $args{silent};

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
  };

  $store->dbh->disconnect;
};

sub commit_content {
  my %args = @_;
  my $wiki = $args{wiki};

  croak "No wiki passed in the 'wiki' parameter"
    unless $wiki;

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
        print "(Re)initialized node '$title'\n"
          unless $args{silent};
      } else {
        warn "Node '$title' not written\n";
      };
    } else {
      warn "Node '$title' already contains data. Not overwritten.";
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
by Kate Pugh.

