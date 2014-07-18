use feature qw(say);
package HDHomerun;
use Moose;
with 'MooseX::Getopt';
has '_config' => (isa => 'Str', is=>'ro', default=>'hdhomerun_config.exe');
has 'id' => (isa =>'Str', is =>'ro', lazy=>1, builder=>'_build_id');
has 'tuners'=>(isa=>'ArrayRef[Int]',is=>'ro',default=>sub{[1]});
has '_lock'=>(isa =>'Str',is=>'ro',default=>'192.168.3.103');
has 'max_scan'=>(isa=>'Int',is=>'rw',default=>1000);
has 'min_scan'=>(isa=>'Int',is=>'rw',default=>1);
sub _build_id
{
	chdir 'c:\Program Files\Silicondust\HDHomerun';
	my $self=shift;
	my $cmd= $self->_config .' discover';
	my $res=`$cmd`;
	chomp $res;
	$res=~s/hdhomerun device (\S*).*/$1/;
	return $res;
}

sub scan
{
	my $self=shift;
#	say "available tuners ".@{$self->tuners};
	my $num_tuners=scalar @{$self->tuners};
	#say @{$self->tuners};
	foreach my $tuner (@{$self->tuners})
	{
		$self->lock($tuner);
	}

	for( my $channel=$self->min_scan;$channel<=$self->max_scan;)
	{
		my @check;
		foreach my $tuner (@{$self->tuners})
		{
		say "Scanning Channel:$channel";
			push (@check,{ch=>$channel,tun=>$tuner}) if ($self->change_channel($channel,$tuner));
			$channel++;
		}
		next if (scalar @check ==0);
#sleep 1 ;
		foreach my $ch (@check)
		{
			$self->vstatus($ch->{ch},$ch->{tun});
		}

	}
	foreach my $tuner (@{$self->tuners})
	{
		$self->clear_lock($tuner);
	}
}

sub lock
{
	my $self=shift;
	my $tuner=shift;
	my $cmd=$self->_config. ' '.$self->id." set /tuner$tuner/lockkey ".$self->_lock;
	my $res=`$cmd`;
	return 1 if ($? == 0);
	say "did not lock";
	return 0;
}

sub clear_lock
{
	my $self=shift;
	my $tuner=shift;
	my $cmd=$self->_config. ' '.$self->id." key ".$self->_lock ." set /tuner$tuner/lockkey none";
	my $res=`$cmd`;
	return 1 if ($? == 0);
	say "did not clear lock";
	return 0;}

sub change_channel
{
	my $self=shift;
	my $channel=shift;
	my $tuner=shift;
	my $cmd=$self->_config. ' '.$self->id." key ".$self->_lock." set /tuner$tuner/vchannel ".$channel;
	my $res=`$cmd`;
	return 1 if ($? == 0);
	return 0;
}
sub fallback
{
	my $self=shift;
	my $channel=shift;
	my $tuner=shift;
	sleep 5;
        $self->change_channel($channel,$tuner);
	$self->vstatus($channel,$tuner);
}
sub vstatus
{
	my $self=shift;
	my $channel=shift;
	my $tuner=shift;
	my $cmd=$self->_config. ' '.$self->id." get /tuner$tuner/vstatus ".$channel;
	foreach  (0..10)
	{
		my $res_str=`$cmd`;
		chomp $res_str;
		
		if ($res_str=~/vch=0/)
		{ $self->fallback($channel,$tuner);
			return;
	       	} 
		#fix for channel names with ' HD' in it'
		$res_str=~s/ HD /HD /;
		my %res=split(/[=\s]/,$res_str);
		if ($res{auth} eq 'subscribed' && $res{cci} ne 'none')
		{
			say "$res_str";
			return; 
		}
		elsif($res{auth} eq 'not-subscribed')
		{
			say "$res_str";
			return;
		}
		elsif( $_ == 10)
		{
			say "$res_str";
		}
		sleep 1;
	}
#'cci' => 'none',
#'auth' => 'unspecified'
#'vch' => '104',
#'cgms' => 'none',
#'name' => 'COOK'
}

1;

package tuner;
use Moose;
has 'id' => (isa =>'Int',is=>'ro',default=>0);
has 'device_id'=>(isa=>'Str',is=>'ro',required=>1);
has '_key' =>(isa=>'Str',is=>'rw',lazy=>1,predicate=>'has__key', clearer=>'clear__key',builder=>'_build_key');



sub _cmd {
	my $self=shift;
	my $tuner=shift;
	my $device_cmd=shift;
	my $cmd;
	if ($self->has_key)
	{
		$cmd=$self->_config. ' '.$self->device_id." key ".$self->_key ." set /tuner$tuner/$device_cmd";
	}
	else
	{
		$cmd=$self->_config. ' '.$self->device_id." set /tuner$tuner/$device_cmd";
	}

	my $res=`$cmd`;
	return 1 if ($? == 0);
	say STDERR $res;
	return 0;
}


1;
package MAIN;
use feature qw(say);
my $app=HDHomerun->new_with_options();
$app->scan;
