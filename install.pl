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

$|=1;

use strict;
use warnings;
use 5.008;
use CPAN;
use Cwd;
use File::Spec;
use File::Temp qw/ tempfile tempdir /;
use HTTP::Tiny;

if (lc($^O) eq 'mswin32') {
	print_text(
		"",
		"[ERROR] We dont support Win32.. sorry :(",
		""
	);
	exit 1;
} elsif (lc($^O) ne 'linux') {
	print_text(
		"",
		"[WARNING] We dont support anything else then Linux, but you may try, if you want, but please consider getting some Linux system on trouble, for example a virtual machine with vmware or virtualbox, or a cloud server at linode or amazon (they have a free micro instance for a year). You can stop the installation with Ctrl-C now if you dont wanna try it.",
		""
	);
	print_wait(10);
}

if (getpwnam($ENV{USER}) == 0) {
	print_text(
		"",
		"[ERROR] DO NOT DO THIS AS ROOT! PLEASE USE A NORMAL USER ACCOUNT!",
		""
	);
	exit 1;	
}

print "\n";
print ' ____             _    ____             _     ____'."\n";
print '|  _ \\ _   _  ___| | _|  _ \\ _   _  ___| | __/ ___| ___'."\n";
print '| | | | | | |/ __| |/ / | | | | | |/ __| |/ / |  _ / _ \\'."\n";
print '| |_| | |_| | (__|   <| |_| | |_| | (__|   <| |_| | (_) |'."\n";
print '|____/ \\__,_|\\___|_|\\_\\____/ \\__,_|\\___|_|\\_\\\\____|\\___/'."\n";
print '========================================================='."\n";

my $_cpanm;
my $_cpanm_filename;

my $set_locallib;

if ($ENV{PERL_LOCAL_LIB_ROOT} || $ENV{PERL_MM_OPT} || $ENV{PERL_MB_OPT}) {

	print_text("Found running local::lib...");

} elsif (!defined $ENV{PERLBREW_PATH}) {

	$set_locallib = $ENV{HOME}.'/perl5';
	print_text(
		"",
		"Installing local::lib and App::cpanminus to ".$set_locallib."...",
		""
	);
	cpanminus_install_error() if (system("perl ".cpanminus()." -n -l ".$set_locallib." local::lib App::cpanminus"));

	my $bashrc = File::Spec->catfile($ENV{HOME},'.bashrc');
	my $extraline = 'eval $(perl -I'.$set_locallib.'/lib/perl5 -Mlocal::lib)';

	if ($ENV{SHELL} eq '/bin/bash') {

		open(my $bfh_read,'<', $bashrc);
		open(my $bfh_write,'>>', $bashrc);

		my @found = grep { chomp($_); $_ eq $extraline } <$bfh_read>;

		if (@found) {
			print_text("Found entry for local::lib in .bashrc");
		} else {
			print_text("Adding entry for local::lib to .bashrc");
			print $bfh_write "\n\n";
			print $bfh_write "# added by duckpan installer\n";
			print $bfh_write $extraline;
			print $bfh_write "\n\n";
		}

		close($bfh_read);
		close($bfh_write);

	} else {

		print_text(
			"",
			"You dont use bash, so we assume, that you know what you are doing, please add this line to your startup script of your shell:",
			$extraline,
			"so that local::lib is active, after you relogin.",
			""
		);

		print_wait(5);

	}

}

unless ($ENV{PERL_LOCAL_LIB_ROOT} || $ENV{PERL_MM_OPT} || $ENV{PERL_MB_OPT} || $ENV{PERLBREW_PATH}) {
	print_text(
		"============================================================",
		"local::lib (or perlbrew) is not active. If you ran this script for the first time, please now re-login to your user account and run it again!",
		"",
	);
	exit 1;
}


my $cpanm = `which cpanm`;

unless ($cpanm) {
	print_text("Installing cpanminus ...","");
	cpanminus_install_error() if (system("perl ".cpanminus()." -n App::cpanminus"));
}

print_text(
	"Installing App::DuckPAN...",
	"[WARNING] This may take a while :-)",
	"",
);

cpanminus_install_error() if (system('cpanm Module::Finder Module::Extract::VERSION'));
cpanminus_install_error() if (system('cpanm -n namespace::autoclean Moose'));
cpanminus_install_error() if (system('cpanm NANIS/Crypt-SSLeay-0.59_03.tar.gz'));
cpanminus_install_error() if (system('cpanm App::DuckPAN'));

print_text(
	"Installing DDG...",
	"[WARNING] This may take a while :-)",
	"",
);

cpanminus_install_error() if (system('duckpan DDG'));

print_text("Checking other requirements ...","");
if (system("duckpan check")) {
	print_text(
		"",
		"[ERROR] Failure on requirement check!",
		"Please fix the problem, or email us at open\@duckduckgo.com with the screen output attached",
		""
	);
	exit 1;
}

print_text(
	"============================================================",
	"Read our other tutorials for the next steps.",
	""
);


sub print_wait {
	my $no = shift;
	print "Please wait ".$no." sec.: ";
	for (1..$no) {
		print "."; sleep 1;
	}
	print "\n\n";
}

sub print_text {
	for (@_) {
		print "\n";
		my @words = split(/\s+/,$_);
		my $current_line = "";
		for (@words) {
			if ((length $current_line) + (length $_) < 79) {
				$current_line .= " " if length $current_line;
				$current_line .= $_;
			} else {
				print $current_line."\n";
				$current_line = $_;
			}
		}
		print $current_line."\n" if length $current_line;
	}
}

sub cpanminus {
	unless ($_cpanm) {
		my $cpanm_url = 'http://duckpan.org/cpanm';
		print "\nFetching cpanminus from ".$cpanm_url." ...\n";
		($_cpanm, $_cpanm_filename) = tempfile();
		my $http = HTTP::Tiny->new;
		my $response = $http->get($cpanm_url);

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

1;

__END__

my $github = prompt("Your GitHub username?");
print "\n";
unless (length $github) {
	print_text("This is not a valid GitHub username, please restart the installer.", "");
	exit 1;
}

if (<$ENV{HOME}/.ssh/id_*.pub>) {
	print_text("Found a public ssh key, I assume you know what you are doing.");
} else {
	print_text("Cant find a public ssh key, assuming you dont have one so far","");
	my $genkey = prompt("Do you want me to generate a key for you?","yes");
	if (lc($genkey) eq 'yes') {
		print_text(
			"",
			"Follow the instructions of the ssh key generation procedure. We suggest that you dont set a passphrase and dont change the suggestion filename for the generated key",
			""
		);
		if (system('ssh-keygen')) {
			print_text("There was a failure on generation of the ssh key, if you cant solve it please email us at open\@duckduckgo.com");
			exit 1;
		}
		print_text(
			"",
			"Now add the generated key to your GitHub account at the URL:",
			"https://github.com/settings/ssh",
			"Your key is:",
			`cat $ENV{HOME}/.ssh/id_rsa.pub`,
			""
		);
	}
}

print "\n";
my $zcig = prompt("Clone to which directory?",$ENV{HOME}.'/zeroclickinfo-goodies');
print "\n";
my $giturl = "git\@github.com:".$github."/zeroclickinfo-goodies.git";

if (-d $zcig) {
	print "\nDirectory already exist, assuming you have cloned already...\n";
} else {
	print "\nCloning zeroclickinfo-goodies...\n";

	if (system('git clone '.$giturl.' '.$zcig)) {
		print "\n\nFailure on cloning! Please fix the problem, or email us";
		print "\nat open\@duckduckgo.com with the screen output attached\n";
		exit 1;
	}
}

chdir($zcig);

print "\nInstalling Distribution requirements...\n";
print "\n[WARNING] This may take a while :-)\n\n";

cpanminus_install_error() if (system('dzil authordeps --missing | cpanm'));
cpanminus_install_error() if (system('dzil listdeps --missing | cpanm'));

