#!/usr/bin/perl -w

# The first and simplest job scheduler in the boomstick ensemble

use strict;

my($arg, $DEBUG, @INFILES) = (1 == 0);

foreach $arg (@ARGV){
		if($arg eq "-d"){
				$DEBUG = (1 == 1);
		}else{
				push @INFILES, $arg;
		}
}

# XXX: these belong in a module :)
sub shellOut{
		my($cmd) = shift;
		
		if($DEBUG){
				print "$cmd\n";
		}else{
				system($cmd) || die;
		}
}

sub doAction{
		my($source, $action, $destination) = @_;
		
		if($action eq "makeiso"){
				shellOut("mkisofs -R -b  boot/grub/stage2_eltorito -no-emul-boot -boot-load-size 16 -boot-info-table -input-charset UTF-8 -o $destination $source");
		}elsif($action eq "cp"){
				shellOut("cp $source $destination");
		}elsif($action eq "configure"){

		}elsif($action eq "dsss"){

		}elsif($action eq "make"){

		}elsif($action eq "makeinstall"){

		}elsif($action eq "patch"){

		}elsif($action eq "crosskernelassemble"){

		}elsif($action eq "crosskernellink"){

		}elsif($action eq "crosskerneldcompile"){

		}elsif($action eq "crossuserlink"){

		}elsif($action eq "crossuserassemble"){

		}elsif($action eq "crossuserccompile"){

		}elsif($action eq "crossuserdcompile"){

		}elsif($action eq "userlink"){

		}elsif($action eq "userassemble"){

		}elsif($action eq "userccompile"){

		}elsif($action eq "userdcompile"){

		}else{
				print STDERR "unknown: $action\n";
		}
}


my($source, $action, $destination);

# currently assumes input has had a reverse topological sort applied
while(<STDIN>){
		chomp;
		if(m/(\S+) -([^- ]+)-> (\S+)/){
				$source = $1;
				$action = $2;
				$destination = $3;

				doAction($source, $action, $destination);
		}
}
