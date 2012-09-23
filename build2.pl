#!/usr/bin/env perl

use Cwd;
use File::Spec;
use File::Copy;
require App::FatPacker;

my ( undef, $dir, $file ) = File::Spec->splitpath(__FILE__);
my $builddir = File::Spec->catdir($dir,'.build');
mkdir($builddir) unless -d $builddir;
my $libdir = File::Spec->catdir($builddir,'lib');
mkdir($libdir) unless -d $libdir;
my $source = File::Spec->catfile($dir,'install2.pl');
my $target = File::Spec->catfile($builddir,'install.pl');
copy(scalar File::Spec->catfile($dir,'install.pl'),scalar File::Spec->catfile($builddir,'install.pl')) or die "$!";

print "\nChanging directory to ".$builddir."...\n";
chdir($builddir);

print "\nFatpacking...\n";
system('fatpack packlists-for HTTP/Tiny.pm >packlists');
system('fatpack tree `cat packlists`');
system('(echo "#!/usr/bin/env perl"; fatpack file; cat install.pl) >../duckpan-install.pl');

# do not release yet
if (0 && $ARGV[0] eq 'release') {
	print "\nReleasing to duckpan.org...\n";
	system('scp ../duckpan-install.pl ddgc@dukgo.com:~/ddgc/duckpan/install.pl');
}

print "\nDone...\n\n";
