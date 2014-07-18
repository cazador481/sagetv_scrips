#!/usr/bin/perl  
#Delete non intellegent and manual recordings  
use REST::Client;  
use MIME::Base64;  
use JSON;  
use feature qw (say);

# Configurables  
$poolname = "Web Servers";  
$endpoint = "server:8080";  
$userpass = "sage:frey";  
# http://server:8080/sagex/api?c=GetMediaFiles&start=0&size=10&1=T 
# Older implementations of LWP check this to disable server verification  
$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME}=0;  

# Set up the connection  
my $client = REST::Client->new( );  

# Newer implementations of LWP use this to disable server verification  
# Try SSL_verify_mode => SSL_VERIFY_NONE.  0 is more compatible, but may be deprecated  
$client->getUseragent()->ssl_opts( SSL_verify_mode => 0 );  

$client->setHost( "http://$endpoint" );  
$client->addHeader( "Authorization", "Basic ".encode_base64( $userpass ) );  
my $start=0; 
my @to_del;
while (1)
{
# Perform a HTTP GET on this URI  
	$client->GET( "/sagex/api?c=EvaluateExpression&1=Sort(GetMediaFiles(\"T\"),false,\"Intelligent\")&start=$start&size=50&encoder=json" );  
	die $client->responseContent() if( $client->responseCode() >= 300 );
	my $r = decode_json( $client->responseContent() ); 
	my $size=scalar(@{$r->{Result}});
	foreach my $res (@{$r->{Result}})
	{
		#say $res->{MediaFileID};
		 if ($res->{Airing}->{IsNotManualOrFavorite})
		 {
		say "Title:",$res->{MediaTitle};#->{MediaFileID};
		say "Intellegent:",$res->{Airing}->{IsNotManualOrFavorite};#->MediaFileID};
		push(@to_del,$res->{MediaFileID}) ;
		 }
	 }
	 last if ($size<50);;
	 $start+=50;
 }

 foreach my $id (@to_del)
 {
	say "To Del: $id";
	$client->GET( "/sagex/api?c=DeleteFileWithoutPrejudice&1=mediafile:$id&encoder=json" );  
	die $client->responseContent() if( $client->responseCode() >= 300 );
	print $client->responseContent();

 }
