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
our $STATUS_CODE = {
    200 => 'Success',
    201 => 'Success',
    204 => 'Success',
    400 => 'Bad Request - Request Could\'t be parsed',
    401 => 'Unauthorized',
    403 => 'Forbidden. Invalid API',
    404 => 'No records exist',
    405 => 'Method not found',
    409 => 'Conflict',
    412 => 'Precondition failed',
    422 => 'Unprocessable Entity',
    500 => 'Server error',
    503 => 'Server overloaded',
    520 => 'Service Unavailable',
    522 => 'Service Unavailable',
};


has host => ( is => 'ro', default => 'https://api-v2launch.trakt.tv' );

# has host => (is=>'ro',default=>'https://api.staging.trakt.tv');
has client_id => (
    is => 'ro',
    default =>
      '5c62827b46e07476027395ed4b3db06513f7b7af6c41b25f4fda0116c0761179'
);
has client_secret => (
    is => 'ro',
    default =>
      '5973e1f99d4b1e98a4700769787b94d9b966f3571faabedddc2076e418766869'
);
has client => ( is => 'lazy' );
has access_token => ( is => 'rw', trigger => 1,default=>'bf8b9d6710719ae68dad9acbed484664ad7618517cfea466e5cfde6f34f02e5f', );
has refresh_token=>(is=>'rw');

sub _trigger_access_token {
    my $self  = shift;
    my $token = @_;
    $self->client->addHeader( 'Authorization' => $token );
}

sub _build_client {
    my $self   = shift;
    my $client = REST::Client->new( host => $self->host );
    my $ua     = $client->getUseragent;
    $ua->add_handler( "request_send", sub { shift->dump; return } );
    $client->addHeader( 'Content-Type'  => 'application/json' );
    $client->addHeader( 'trakt-api-key' => $self->client_id )
      ;    #client id found under api
    $client->addHeader( 'trakt-api-version' => 2 );
    $self->client->addHeader( 'Authorization' => $self->access_token) if $self->has_access_token;
    return $client;
}

sub run {
    my $self = shift;
    # $self->get_authorization

}

sub get_authorization {
    my $self = shift;
    my $data = {
        'code'          => 'fbe777f5',
        'client_id'     => $self->client_id,
        'client_secret' => $self->client_secret,
        'redirect_uri'  => 'urn:ietf:wg:oauth:2.0:oob',
        'grant_type'    => 'authorization_code'
    };

    $self->client->POST( 'oauth/token', to_json($data) );
    if ( $self->client->responseCode > 205 ) {

        say $self->client->responseCode;

        my $content = $self->client->responseContent;
        if ( $content =~ /^{/ ) {
            $content = from_json($content);
            print $content->{error_description};
        }
        else {
            print $STATUS_CODE->{ $self->client->responseCode };
        }
    }
    else {

        my $ret = from_json $self->client->responseContent;
        $self->access_token($ret->{access_token});
        $self->refresh_token($ret->{refresh_token});
        my $FH;
        open ($FH,'>','/home/eash/trakt.cfg');
        print $FH Dumper ($ret);
    }
}

__PACKAGE__->new->run;
1;
