#!/usr/bin/perl

use REST::Client;
use MIME::Base64;
use JSON;
use Data::Dumper;
use Moo;

use feature qw (say);

# Configurables
my $poolname = "Web Servers";
my $endpoint = "192.168.1.101:8080";
my $userpass = "sage:frey";

# http://server:8080/sagex/api?c=GetMediaFiles&start=0&size=10&1=T
# Older implementations of LWP check this to disable server verification
$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;

# Set up the connection
my $client = REST::Client->new();

# Newer implementations of LWP use this to disable server verification
# Try SSL_verify_mode => SSL_VERIFY_NONE.  0 is more compatible, but may be deprecated
$client->getUseragent()->ssl_opts( SSL_verify_mode => 0 );

$client->setHost("http://$endpoint");
$client->addHeader( "Authorization", "Basic " . encode_base64($userpass) );
my $start = 0;
my @to_del;
while (1) {

    # Perform a HTTP GET on this URI
    $client->GET(
"/sagex/api?c=EvaluateExpression&1=Sort(GetMediaFiles(\"T\"),false,\"Intelligent\")&start=$start&size=50&encoder=json"
    );

#$client->GET( "/sagex/api?c=EvaluateExpression&1=Sort(GetMediaFiles(\"T\"),false,\"Intelligent\")&start=$start&size=1&encoder=json" );
    die $client->responseContent() if ( $client->responseCode() >= 300 );
    my $r = decode_json( $client->responseContent() );

    #say Dumper($r);
    my $size = scalar( @{ $r->{Result} } );
    foreach my $res ( @{ $r->{Result} } ) {

        next if ( !$res->{IsFileCurrentlyRecording}  );

        #say $res->{MediaFileID};
        #
        #These don't show up on recording list
        if ( !$res->{IsCompleteRecording}) {
            push( @to_del, $res->{MediaFileID} );
            next;
        }
        if ( $res->{Airing}->{IsNotManualOrFavorite} ) {

  #		say "Title:",$res->{MediaTitle};#->{MediaFileID};
  #		say "Intellegent:",$res->{Airing}->{IsNotManualOrFavorite};#->MediaFileID};
        }
        if ( expected_length_time($res) - actual_length_time($res) >
            expected_length_time($res) / 10 )
        {
            push( @to_del, $res->{MediaFileID} );

#say "Title:",$res->{MediaTitle},'-',$res->{MediaFileMetadataProperties}->{SeasonNumber},':',$res->{MediaFileMetadataProperties}->{EpisodeNumber};#->{MediaFileID};
#say "run time:",actual_length_time($res);

        }
    }
    last if ( $size < 50 );
    $start += 50;
    exit;
}

foreach my $id (@to_del) {
    #delete_tv( $client, $id );
}

sub expected_length_time {
    my $id = shift;
    return ( $id->{Airing}->{AiringEndTime} - $id->{Airing}->{AiringStartTime} )
      / 1000 / 60;
}

sub actual_length_time {
    my $id = shift;
    return ( $id->{FileEndTime} - $id->{FileStartTime} ) / 1000 / 60;
}

sub delete_tv {
    my $client = shift;
    my $id     = shift;
    $client->GET(
        "/sagex/api?c=DeleteFileWithoutPrejudice&1=mediafile:$id&encoder=json");
    print $client->responseContent();
    die $client->responseContent() if ( $client->responseCode() >= 300 );

}
__END__
foreach my $id (@to_del)
{
say "To Del: $id";
$client->GET( "/sagex/api?c=DeleteFileWithoutPrejudice&1=mediafile:$id&encoder=json" );  
die $client->responseContent() if( $client->responseCode() >= 300 );
print $client->responseContent();

}
