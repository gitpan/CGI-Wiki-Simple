#!/usr/bin/perl -w
use strict;
use Getopt::Long;
use File::Spec;
use CGI::Wiki::Setup::SQLite;
use CGI::Wiki::Store::SQLite;
use CGI::Wiki;
use Digest::MD5;

my ($dbname, $help, $clear, $force_update );
GetOptions( "name=s"         => \$dbname,
            "help"           => \$help,
            "clear"          => \$clear,
            "force"          => \$force_update,
           );

unless (defined($dbname)) {
    print "You must supply a database name with the --name option\n";
    print "further help can be found by typing 'perldoc $0'\n";
    exit 1;
}

if ($help) {
    print "Help can be found by typing 'perldoc $0'\n";
    exit 0;
}

CGI::Wiki::Setup::SQLite::cleardb($dbname)
  if $clear;

CGI::Wiki::Setup::SQLite::setup($dbname);

# get the wiki store :
my $store = CGI::Wiki::Store::SQLite->new( dbname => $dbname );
my $wiki = CGI::Wiki->new(
           store  => $store,
				   search => undef );

sub commit_content {
  foreach my $node (@_) {
    my $title = $node->{title};

    my %old_node = $wiki->retrieve_node($title);
    if (defined $old_node{content} or $force_update) {
      my $content = $node->{content};
      $content =~ s/\r\n/\n/g;
      my $cksum = $old_node{checksum};
      my $written = $wiki->write_node($title, $content, $cksum);
      if ($written) {
        print "(Re)initialized node '$title'\n";
      } else {
        warn "Node '$title' not written\n";
      };
    } else {
      warn "Node '$title' already contains data. Not overwritten. Use --force to overwrite";
      warn $old_node{content};
    };
  };
};

my @nodes = do { undef $/; split /__NODE__/, <DATA> };
@nodes = map {
  /^Title:\s+(.*?)\r?\n(.*)/ms
  ? { title => $1, content => $2 }
  : ()
} @nodes;
print "Found ", scalar @nodes, " nodes.\n";

commit_content(@nodes);

=head1 NAME

simple-user-setup-sqlite - set up a wiki together with default content

=head1 SYNOPSIS

  # Set up or update the storage backend, leaving any existing data intact.
  # Useful for upgrading from old versions of CGI::Wiki to newer ones with
  # more backend features.

  simple-user-setup-sqlite --name mywiki.db

  # Overwrite the nodes with the default contents

  simple-user-setup-sqlite --name mywiki --clear

  # Clear out any existing data and set up a fresh backend from scratch.

  simple-user-setup-sqlite --name mywiki.db --clear

=head1 DESCRIPTION

Takes one mandatory argument:

=over 4

=item name

The name of the file to store the SQLite database in.  It will be
created if it doesn't already exist.

=back

and up to two optional flags:

=over 4

=item clear

Wipes out all preexisting data within your wiki. This is great
while you are testing and playing around, and fatal unless you
have good backups.

=item force

Overwrites already existing nodes with the content from this
file. This is still great while you are playing around and not
totally fatal, but good backups are still advisable.

=back

=head1 AUTHOR

Max Maischein (corion@cpan.org)

=head1 COPYRIGHT

     Copyright (C) 2003 Max Maischein.  All Rights Reserved.

This code is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<CGI::Wiki>

=cut

__DATA__
__NODE__
Title: index
This is the main page of your new wiki. If your wiki will be
accessible to the general public, you might want to make this
node read only by loading the [CGI::Wiki::Simple::Plugin::Static]
plugin for this node :

     use CGI::Wiki::Simple::Plugin::Static index => 'Text for the index node';

This node was loaded initially by the setup program among others :

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
