package CGI::Wiki::Simple::Plugin::RecentChanges;
use CGI::Wiki::Simple::Plugin();
use HTML::Entities;

use vars qw($VERSION);
$VERSION = 0.05;

=head1 NAME

CGI::Wiki::Simple::Plugin::RecentChanges - Node that lists the recent changes

=head1 DESCRIPTION

This node lists the nodes that were changed in your wiki. This only works for nodes that
are stored within a CGI::Wiki::Store::Database, at least until I implement more of
the store properties for the plugins as well.

=head1 SYNOPSIS

=for example begin

  use CGI::Wiki::Simple;
  use CGI::Wiki::Simple::Plugin::RecentChanges( name => 'LastWeekChanges', days => 7 );
  # also
  use CGI::Wiki::Simple::Plugin::RecentChanges( name => 'Recent20Changes', count => 20 );
  # also
  use CGI::Wiki::Simple::Plugin::RecentChanges( name => 'RecentFileChanges', re => qr/^File:(.*)$/ );
  # This will display all changed nodes that match ^File:

=for example end

=cut

use vars qw(%re);

sub import {
    my ($module,%args) = @_;
    my $node = $args{name};
    $re{$node} = $args{re} || '^(.*)$';
    CGI::Wiki::Simple::Plugin::register_nodes(module => $module, name => $node);
};

sub retrieve_node {
  my (%args) = @_;

  my $node = $args{name};
  my $re = $re{$node};
  my %nodes = {};

  return (
       "<ul>" .
       join ("\n", map { "<li><a href='?node=$nodes{$_}'>".HTML::Entities::encode_entities($_)."</a></li>" }
                   sort { uc($a) cmp uc($b) }
                   keys %nodes)
     . "</ul>",0,"");
};

1;