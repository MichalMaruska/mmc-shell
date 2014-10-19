#! /usr/bin/perl

# Rewrite the debian/control to _bind_ all the _binary_ packages to
# certain API version.
# And add it as a provider for virtual package.

# Usage:
# replace-gauche-string.pl debian/control.in $GAUCHE_VERSION > debian/control

# todo:
# replace the dependency on gauche with  gauche-API!


# todo: if only 1, we need *.install file. Might provide one.
# but then  debian/rules  need the option to dh-install.
# fixme!  should NOT


use strict;
use feature qw(switch);

use Dpkg::Control::Info;
use Dpkg::Control;

use Getopt::Mixed "nextOption";
my @options=("help verbose debug>verbose d>verbose h>help v>verbose");
Getopt::Mixed::init( @options);

my $debug = 0;

# Given a pkg name, convert the debian/*.install and  debian/control
# to change the pkg name to an ABI-bound one.

sub create_virtual_package {
    my ($pgk_name,$abi)=(@_);
    # print "called " . $name . "\n";

    my $new_package= Dpkg::Control->new(type => CTRL_INFO_PKG);

    $new_package->{'Package'}=$pgk_name;
    $new_package->{'Depends'}=$abi;
    $new_package->{'Architecture'}="all";
    $new_package->{'Description'}=
	"Package to provide one candidate of multi-api-version package.";
    if ($debug) {
	print STDERR "new virtual package\n";
	$new_package->output(\*STDERR);
	print STDERR "\n";
    }
    return $new_package;
}


# this assumes the CWD is debian/..
sub rename_install_file{
    my ($pkg, $newpkg) = (@_);

    # rename the debian/$pkg.install
    my $install_file="debian/" . $pkg . ".install";
    if (-f $install_file) {
	rename($install_file,
	       "debian/" . $newpkg . ".install");
    }
}

my @new=();

# todo: pass the @new array:
sub bind_package_to_version {
    my ($pkg, $name, $new_name) = (@_);

    # rename
    $pkg->{Package} = $new_name;
    # mmc: necessary?
    # $_->{Provides} = $pkg

    rename_install_file($name, $new_name);
    # add a wrapper:
    push @new, create_virtual_package($name, $new_name);
}




# return true iff the package is Architecture NOT all.
sub package_is_binary{
    my ($name) = (@_);

    #optimization
    if ($name eq '${shlibs:Depends}' || $name eq '${misc:Depends}') {
	return;
    }

    # pkg -> source_pkg  how to? no way?
    # just a hint. otherwise some pre-indexing.
    my @debian_dirs = glob '~/repo/gauche/*/debian/';
    print STDERR "looking for package $name\n" if ($debug);
    #if (-f "~/repo/gauche/$name/debian/control.in") {
    # "~/repo/gauche/$name/debian/control.in"
    my $d;
    foreach $d (@debian_dirs) {
	my $control_file;

	if (-f "$d/control.in") {
	    $control_file="$d/control.in";
	} elsif (-f "$d/control") {
	    $control_file="$d/control";
	} else {
	    break;
	}


	# Parse:
	# print STDERR "testing $control_file\n";

	my $info=Dpkg::Control::Info->new($control_file);
	my $pkg;
	if ($pkg = $info->get_pkg_by_name($name)) {
	    print STDERR "found $pkg->{Package}", "\n" if ($debug);
	    if ($pkg) {
		return ($pkg->{Architecture} ne "all");
	    }
	}
	# todo:
	# Build-dep:  fix the ABI of any binary package:
	#   this is because I can describe what is needed.
	#   think:  gauche-dev  & gauche-gtk ... they have to be
	#   the SAME ABI version. i.e. gauche-gtk must be that of
	#   ABI specified by gauche-dev.


	    # scan the packages & create new ones.

	    # look in
	    # find the package's architecture.
	    # or just ask dpkg?
	    }
}


# in $pkg, replace the dependencies on $name with $name-$abi:
# similar for other...  if the dependency is another api-bound
# we need the _same_ version.
# Example: gauche-pg-gtk
# needs    gauche-ABI-gtk
# and      gauche-ABI-pg
sub bind_pkg_deps {
    my ($pkg, $name, $abi) = (@_);
    my @deps = split(', *', $pkg->{Depends});
    my @newdeps = ();

    foreach $_ (@deps) {
	# print STDERR "Examining the dependency on $_\n";

	if ($_ eq $name) {
	    # Gauche itself.
	    my $new="$_-$abi";
	    print STDERR "changing dependency: $_ -> $new\n" if ($debug);
	    push (@newdeps, $new);
	} elsif (package_is_binary($_)){
	    # fixme: this should invoke recursion!  bug?
	    my $new="$_-$abi";
	    print STDERR "changing dependency: $_ -> $new\n" if ($debug);
	    push (@newdeps, $new);
	} else {
	    push (@newdeps, $_);
	}
    }
    # rewrite:
    $pkg->{Depends}= join (", ", @newdeps);
}



#### CMD line processsing:
my ($option, $value, $pretty);
while (($option, $value, $pretty) = nextOption()) {

    if ($option eq "help") {
	print STDERR "Help!\n";
    } elsif ($option eq "verbose") {
	# print STDERR "I'll be verbose!\n";
	$debug=1;
    };
}
Getopt::Mixed::cleanup();


# the rest is the debian/control filename:
my $file=shift;
#    . "/debian/control";
my $abi_version=shift;
my $name = "gauche";


unless  (-f $file) {
    $file=$file . ".in";
    unless (-f $file) {
	die("non-existent file");
    }
}


# Parse:
my $info=Dpkg::Control::Info->new($file);


# todo:
# Build-dep:  fix the ABI of any binary package:
#   this is because I can describe what is needed.
#   think:  gauche-dev  & gauche-gtk ... they have to be
#   the SAME ABI version. i.e. gauche-gtk must be that of
#   ABI specified by gauche-dev.


# scan the packages & create new ones.
foreach $_ ($info->get_packages())
{
    if ($_->{Architecture} ne "all") {
	# any, i386, amd64, arm ...
	my $pkg_name=$_->{Package};

	# gauche-pg will be  gauche-API-pg
	# replace `name' with `name_api'
	my $new_pkg_name = $pkg_name =~ s/\Q$name-/$name-$abi_version-/r;
	bind_package_to_version($_, $pkg_name, $new_pkg_name);
	bind_pkg_deps($_, $name, $abi_version);
	# exchange & add
	# print $_->{Package}, "\n";
    }
}

foreach $_ (@new) {
    push @{$info->{packages}}, $_;
}



# print out the debian/control
$info->output(\*STDOUT);

exit 0;
