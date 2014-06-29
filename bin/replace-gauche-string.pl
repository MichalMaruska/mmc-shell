#! /usr/bin/perl


# process the debian/control to fix the API version:

use strict;
use feature qw(switch);

use Dpkg::Control::Info;
use Dpkg::Control;

use Getopt::Mixed "nextOption";
my @options=("help verbose debug>verbose  arch=s d>verbose h>help v>verbose");
Getopt::Mixed::init( @options);



# given a pkg name,
# convert the debian/*.install and  debian/control
# to change the pkg name to an ABI-bound one.

sub add_abstract_package {
    my ($name,$abi)=(@_);# ,$info  ,$3 @_; $1,$2

    # print "called " . $name . "\n";
# Add:
    my $new_abstract= Dpkg::Control->new(type => CTRL_INFO_PKG);

#my $fields=$new_abstract->{fields};
#$fields->{'Package'}= "newp";

#my %hash=('Package', "new2");
#$new_abstract->set_options(%hash);

# print "xxxx" . $new_abstract->{'Package'} . "\n";
#= "new";
#$new_abstract{'Architecture'} ="any";
    $new_abstract->{'Package'}=$name;
    $new_abstract->{'Depends'}=$abi;
    $new_abstract->{'Architecture'}="all";
    #$new_abstract->{'Provides'}=$name;
    $new_abstract->{'Description'}="Package to provide one candidate of multi-api-version package.";
    # if $debug $new_abstract->output(\*STDOUT);
    return $new_abstract;
}


my @new=();
# todo: pass the @new array:
sub bind_package_to_version {
    my ($pkg, $newpkg) = (@_);

    # rename
    $_->{Package} = $newpkg;

    # rename the debian/$pkg.install
    my $install_file="debian/" . $pkg . ".install";
    if (-f $install_file) {
	rename($install_file,
	       "debian/" . $newpkg . ".install");
    }

    # add a wrapper:
    push @new, add_abstract_package($pkg, $newpkg);
}


#### CMD line processsing:
my ($option, $value, $pretty);
while (($option, $value, $pretty) = nextOption()) {

    given($option){
	when ("help") {
	    print "Help!\n";
	}
	when ("verbose") {
	    print "I'll be verbose!\n";
	}
	default {}
    }
}
Getopt::Mixed::cleanup();


my $file=shift;
#    . "/debian/control";
my $abi_version=shift;

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
	my $pkg=$_->{Package};

	my $newpkg= $pkg;
	$newpkg =~ s/gauche-/gauche-$abi_version-/g;
	bind_package_to_version($pkg, $newpkg);
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
