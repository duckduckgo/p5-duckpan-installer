#!/usr/bin/env perl
#
# This script installs anything required to contribute Zero-click Info to DuckDuckGo
# In general:
#
# It installs local::lib if not one is already active (or perlbrew)
# It installs App::cpanminus and App::DuckPAN
# It uses duckpan to install DDG (duckpan DDG)
# It runs: duckpan check
#

use strict;
use warnings;
use 5.008;
use CPAN;
use Cwd;
use File::Spec;
use ExtUtils::MakeMaker qw( prompt );
use File::Temp qw/ tempfile tempdir /;
use HTTP::Tiny;

if ($^O eq 'MSWin32') {
	print "\n[ERROR] We dont support Win32.. sorry :(\n\n";
	exit 1;
}

print "\n";
print ' ____             _    ____             _     ____'."\n";
print '|  _ \\ _   _  ___| | _|  _ \\ _   _  ___| | __/ ___| ___'."\n";
print '| | | | | | |/ __| |/ / | | | | | |/ __| |/ / |  _ / _ \\'."\n";
print '| |_| | |_| | (__|   <| |_| | |_| | (__|   <| |_| | (_) |'."\n";
print '|____/ \\__,_|\\___|_|\\_\\____/ \\__,_|\\___|_|\\_\\\\____|\\___/'."\n";

my $_cpanm;
my $_cpanm_filename;

my $locallib = $ENV{PERL_LOCAL_LIB_ROOT};
my $set_locallib;

if ($locallib) {

	print "\nFound running local::lib on ".$locallib." - using this\n"

} else {

	print "\n\n";
	$set_locallib = prompt("Where you want to install local::lib?",$ENV{HOME}.'/perl5');
	print "\nInstalling local::lib and App::cpanminus...\n";
	if (system(cpanminus()." -n -l ".$set_locallib." local::lib App::cpanminus")) {
		print "\n\nFailure on install! Please fix the problem, or email us";
		print "\nat open\@duckduckgo.com with the build.log attached\n";
		exit 1;
	}

	my $bashrc = File::Spec->catfile($ENV{HOME},'.bashrc');
	my $extraline = 'eval $(perl -I'.$set_locallib.'/lib/perl5 -Mlocal::lib)';

	if (-f $bashrc) {

		open(my $bfh_read,'<', $bashrc);
		open(my $bfh_write,'>>', $bashrc);

		my @found = grep { chomp($_); $_ eq $extraline } <$bfh_read>;

		if (@found) {
			print "\nFound entry for local::lib in .bashrc\n";
		} else {
			print "\nAdding entry for local::lib to .bashrc\n";
			print $bfh_write "\n\n";
			print $bfh_write "# added by duckpan installer\n";
			print $bfh_write $extraline;
			print $bfh_write "\n\n";
		}

		close($bfh_read);
		close($bfh_write);

		print "\n";

	} else {

		print "\nWe didnt found a .bashrc in your home, so we suggest you";
		print "\nare using another shell, its important that you add this:\n\n";
		print $extraline;
		print "\n\nto your startup script, so that local::lib is active.";

	}

}

unless ($ENV{PERL_LOCAL_LIB_ROOT} || $ENV{PERLBREW_PATH}) {
	print "\n============================================================\n";
	print "\nlocal::lib (or perlbrew) is not active, if you just have";
	print "\ninstalled it, please relogin to your account and just start";
	print "\nthis installer like you did now!\n\n";
	exit 1;
}


my $cpanm = `which cpanm`;

unless ($cpanm) {
	print "\nInstalling cpanminus ...\n\n";
	if (system(cpanminus()." -n App::cpanminus")) {
		print "\n\nFailure on install! Please fix the problem, or email us";
		print "\nat open\@duckduckgo.com with the build.log attached\n";
		exit 1;
	}
}

print "\nInstalling App::DuckPAN...\n";
print "\n[WARNING] This may take a while :-)\n\n";

system('cpanm App::DuckPAN');






sub cpanminus {
	unless ($_cpanm) {
		print "\nFetching cpanminus from http://cpanmin.us/ ...\n";
		($_cpanm, $_cpanm_filename) = tempfile();
		my $http = HTTP::Tiny->new;
		my $response = $http->get('http://cpanmin.us/');

		unless ($response->{success}) {
			print "\nDownloading of cpanminus failed! Please try again later!\n";
			exit 1;
		}

		my $content = $response->{content};

		print $_cpanm $content;
		chmod 0755, $_cpanm_filename;

		close($_cpanm);
	}
	return $_cpanm_filename;
}

