#!/usr/bin/env perl
package Trakt;
use Moo;
use MooX::Options;
use REST::Client;
use Carp::Always;
use JSON;
use Data::Dumper;
use feature qw(say);
use autodie;

has host => ( is => 'ro', default => 'http://192.168.1.26:8989/api/' );
has 'api_key' =>( is => 'ro', default => '7039bfd9150342eb8ff86906c49db5d5' );
has client => (is =>'lazy');
sub _build_client {
      my $self   = shift;
      my $client = REST::Client->new( host => $self->host );
      my $ua     = $client->getUseragent;
      $ua->add_handler( "request_send", sub { shift->dump; return } );
      # $client->addHeader( 'Content-Type' => 'application/json' );
      $client->addHeader( 'X-Api-Key'    => $self->api_key );
      return $client;
}
sub run {
      my $self = shift;
      $self->client->GET('Episode?seriesId=1');
      print Dumper $self->client->responseContent;


}

sub get_all_episodes_from_series
{
      my $self = shift;
      $self->client->GET('Episode?seriesId=1');
      return from_json $self->client->responseContent;
}

sub get_all_series
{
    my $self=shift;
      $self->client->GET('series');
      return from_json $self->client->responseContent;

}
__PACKAGE__->new->run;
1;
