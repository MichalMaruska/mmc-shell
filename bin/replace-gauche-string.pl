#! /usr/bin/perl

# Rewrite the debian/control to _bind_ all the _binary_ packages to
# certain API version(s) of dependencies.
# And add it as a provider for `virtual' package.

# implementation: pkg. name gauche-pg will be  gauche-API-pg-API


# Usage:
# replace-gauche-string.pl debian/control.in > debian/control

# todo:
# replace the dependency on gauche with  gauche-API!

use strict;
use feature qw(switch);

use Dpkg::Control::Info;
use Dpkg::Control;

use Getopt::Mixed "nextOption";

my $debug = 0;



# this assumes the CWD is debian/.. I could have a $dir parameter!
sub rename_install_file{
    my ($pkg, $newpkg) = (@_);

    # rename the debian/$pkg.install
    my $install_file="debian/" . $pkg . ".install";
    if (-f $install_file) {
        rename($install_file,
               "debian/" . $newpkg . ".install");
    }
}

# this updates the data & filename
sub rename_binary_package {
    my ($pkg, $original_name, $versioned_name) = (@_);

    $pkg->{Package} = $versioned_name;
    rename_install_file($original_name, $versioned_name);

    $_->{Provides} = $original_name;
}


# return this modification: ....xxx....  -> ....xxx-ver....
# xxx is separated by non-alphanumeric ?
sub insert_version_string {
    my ($pkg_name, $api, $version) = @_;
    my $quoted_api= quotemeta $api;
    #$pkg_name =~ s/\Q$api-/$api-$version-/r;
    $pkg_name =~ s/\b$quoted_api\b/$api-$version/; # r
    if ($debug) { print STDERR "replacing $api with $api-$version -> $pkg_name\n";}
    return $pkg_name;
}


# todo: in a separate file: this consults all of my packages in Git.
# return true iff the package is architecture-dependent, i.e. not All.
sub package_is_versioned{
    my ($name) = (@_);

    # fixme: this comes from Depends, and contains these subst. variables:
    # optimization
    if ($name eq '${shlibs:Depends}' || $name eq '${misc:Depends}') {
        return;
    }
    print STDERR "looking for package $name\n" if ($debug);

    # how to find the source pkg. name, and the directory?
    # just a hint. otherwise some pre-indexing.
    my @debian_dirs = glob '~/repo/gauche/*/debian';

    my $dir;
    foreach $dir (@debian_dirs) {
        my $control_file;
        # check that it's a directory indeed.
        # if ! -d $dir; {break;}
        if (-f "$dir/control.in") {
            # todo: generate control? I will need a rule ...
            $control_file="$dir/control.in";
        } elsif (-f "$dir/control") {
            $control_file="$dir/control";
        } else {
            break;
        }

        print STDERR "testing $control_file\n" if ($debug);

        my $info=Dpkg::Control::Info->new($control_file);
        my $pkg;
        if ($pkg = $info->get_pkg_by_name($name)) {
            print STDERR "found $pkg->{Package}", "\n" if ($debug);
            if ($pkg) {
                return ($pkg->{Architecture} ne "all");
            }
        }
    }
}


# In $pkg, replace the `dependencies' on $name with $name-$abi:
# similar for other...  if the dependency is another api-bound
# note: invoke recursively?
# we need the _same_ version.
# Example: gauche-pg-gtk
# needs    gauche-ABI-gtk
# and      gauche-ABI-pg
# this is inverse of how it should be done.
# So instead of building this mapping when a pkg is built,
# we *guess* it.
sub adjust_pkg_dependencies {
    my ($pkg, %versioned_apis) = (@_);

    my @deps = split(', *', $pkg->{Depends});
    # this will contain the new list:
    my @newdeps = ();

    foreach $_ (@deps) {
        # print STDERR "Examining the dependency on $_\n";
        # todo: parse dep to get pkg_name
        if (package_is_versioned($_)) {
            my $new_pkg_name;
            $new_pkg_name=$_;
            while (my ($key, $version) = each(%versioned_apis) ) {
                $new_pkg_name = insert_version_string($new_pkg_name, $key, $version);
            }
            push (@newdeps, $new_pkg_name);
        } else {
            push (@newdeps, $_);
        }
    }
        # rewrite:
        $pkg->{Depends} = join (", ", @newdeps);
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



# todo:
# Build-dep:  fix the ABI of any binary package:
#   this is because I can describe what is needed.
#   think:  gauche-dev  & gauche-gtk ... they have to be
#   the SAME ABI version. i.e. gauche-gtk must be that of
#   ABI specified by gauche-dev.

my %versioned_apis = (
    "gauche" => "0",
        "pg" => "13",
);

#### CMD line processsing:
my @options=("help verbose api=s version=s debug>verbose d>verbose h>help v>verbose a>api v>version");
Getopt::Mixed::init( @options);

my ($option, $value, $pretty);
my $api;
while (($option, $value, $pretty) = nextOption()) {
    if ($option eq "api") {
    ## --api gauche-0.9.5-b
        $api = $value;
    }
    elsif ($option eq "version") {
        $versioned_apis{$api} = $value;
    }
    elsif ($option eq "help") {
        print STDERR "Help!\n";
    } elsif ($option eq "verbose") {
        # print STDERR "I'll be verbose!\n";
        $debug=1;
    };
}
Getopt::Mixed::cleanup();


# the rest is the debian/control filename:
my $file=shift;
# I could default to "./debian/control";

# default values:
if ($versioned_apis{gauche} eq 0) {
    # Could accept as a param:
    my $abi_version=`gauche-config -V|sed -e 's/_/-/'`;
    chomp $abi_version;
    # print STDERR $abi_version;
    $versioned_apis{gauche} = $abi_version;
}
my $name = "gauche";


unless  (-f $file) {
    $file=$file . ".in";
    unless (-f $file) {
        die("non-existent file");
    }
}


# Parse:
my $info=Dpkg::Control::Info->new($file);



# scan the packages & create new ones.
foreach $_ ($info->get_packages())
{
    if ($_->{Architecture} ne "all") {
        # Assumption: The api version applies only to native code.
        my $pkg_name = $_->{Package};

        # replace `name' with `name_api'
        my $new_pkg_name = $pkg_name;

        while (my ($key, $version) = each(%versioned_apis) ) {
            $new_pkg_name = insert_version_string($new_pkg_name, $key, $version);
        }
        print STDERR "fixed-api package: $new_pkg_name\n";
        rename_binary_package($_, $pkg_name, $new_pkg_name);
        adjust_pkg_dependencies($_, %versioned_apis);
        # exchange & add
        # print $_->{Package}, "\n";
    }
}


# print out the debian/control
$info->output(\*STDOUT);

exit 0;

# todo:
# every dependency on A, B .. i.e. more than 1
# I need to require a virtual package.
# which will have to be provided by A-B-api Provides A-B.
#
# so  given A, B api -> emit such a fake package!
# A,B,....C & api -> Depends on A-api, B-api ....

# I want to scan all those packages & (re) build them!
# order?
# by build deps!

# A -> B
