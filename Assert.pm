=head1 NAME 

Devel::Assert - stating the obvious to let the computer know

=head1 SYNOPSIS

    BEGIN { $Devel::Assert::DEBUG = 1 }
    use Devel::Assert;
    assert(1 == 1);
    
    # Switch off assertations and inline them.
    BEGIN { $Devel::Assert::DEBUG = 0 }
    use Devel::Assert qw(:DEBUG);
    assert(1 == 1) if DEBUG;

=head1 DESCRIPTION

    "We are ready for any unforseen event that may or may not 
     occur."
        - Dan Quayle

Devel::Assert is intended for a purpose like the ANSI C library assert.h.
If you're already familiar with assert.h, then you can probably skip this and
go straight to the FUNCTIONS section.

Assertations are the explict expressions of your assumptions about the reality
your program is expected to deal with, and a declaration of those which it is
not.  They are used to prevent your program from blissfully processing garbage
inputs (garbage in, garbage out becomes garbage in, error out) and to tell you
when you've produced garbage output.  (If I was going to be a cynic about Perl
and the user nature, I'd say there are no user inputs but garbage, and Perl
produces nothing but...)

An assertation is used to prevent the impossible from being asked of your
code, or at least tell you when it does.  For example:
    
    # Take the square root of a number.
    sub my_sqrt {
        my($num) = shift;

        # the square root of a negative number is imaginary.
        assert($num >= 0);

        return sqrt $num;
    }

The assertation will warn you if a negative number was handed to your
subroutine, a reality the routine has no intention of dealing with.

An assertation should also be used a something of a reality check, to make
sure what your code just did really did happen:

    open(FILE, $filename) || die $!;
    @stuff = <FILE>;
    @stuff = do_something(@stuff);
    
    # I should have some stuff.
    assert(scalar(@stuff) > 0);
    
The assertation makes sure you have some @stuff at the end.  Maybe the file
was empty, maybe do_something() returned an empty list... either way, the
assert() will give you a clue as to where the problem lies, rather than 50
lines down when you print out @stuff and discover it to be empty.

Since assertations are designed for debugging and will remove themelves from
production code, your assertations should be carefully crafted so as to not
have any side-effects, change any variables or otherwise have any effect on
your program.  Here is an example of a bad assertation:

    assert($error = 1 if $king ne 'Henry');

It sets an error flag which may then be used somewhere else in your program. 
When you shut off your assertations with the $DEBUG flag, $error will no
longer be set.


=head1 FUNCTIONS

=head2 assert

    assert(1==1);

assert's functionality is effected by compile time value of
$Devel::Assert::DEBUG.  If $DEBUG is true, assert will function as below.  If
$DEBUG is false, assert will simply return undef.  See L<Debugging vs
Production> for details.  (Note:  Altering the value of $DEBUG after
Devel::Assert has been required will not change assert's behavior.)

Give assert an expression, assert will Carp::confess() if that expression is
false, return undef if it is true (DO NOT use the return value of assert for
anything).

assert() is intended to act like the function from ANSI C fame. 
Unfortunately, due to perl's lack of macros or strong inlining, it's not
nearly as unobtrusive.

=head1 Debugging vs Production

Because assertations are extra code and because it is sometimes necessary to
place them in 'hot' portions of your code where speed is paramount,
Devel::Assert provides the option to remove its assert() calls from your
program.

So, we provide a way to force Perl to inline the switched off assert()
routine, thereby removing almost all performance impact on your production
code.

    BEGIN { $Devel::Assert::DEBUG = 0; }
    use Devel::Assert qw(:DEBUG);  # assertations are off.
    assert(1==1) if DEBUG;

DEBUG is a constant set to 0.  Adding the 'if DEBUG' condition on your
assert() call gives perl the cue to go ahead and remove assert() call from
your program entirely, since the if conditional will always be false.

(This is the best I can do without requiring Filter::cpp) 

=head1 AUTHOR

Michael G Schwern <schwern@pobox.com>

=cut 

package Devel::Assert;

require 5;

use strict;
use Exporter;

use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION %EXPORT_TAGS);

BEGIN {
    $VERSION = 0.03;
    
    @ISA = qw(Exporter);

    @EXPORT = qw(assert);
    @EXPORT_OK = qw(DEBUG);
    %EXPORT_TAGS = (
            DEBUG => [qw(assert DEBUG)]
               );
}

use vars qw($DEBUG);

BEGIN {
    my $assert_sub;
    my $DEBUG_sub;
    if( !defined $DEBUG || $DEBUG ) {
        require Carp;
        $assert_sub = sub ($) { 
            $_[0] or
            &Carp::confess("Assert failed:  $_[0]");
            return undef; 
        };
        $DEBUG_sub = sub () {1};
    }
    else {
        $DEBUG_sub = sub () {0};
        $assert_sub = sub ($) {undef};
    }
    *assert = $assert_sub;
    *DEBUG  = $DEBUG_sub;
}


return q|You don't just EAT the largest turnip in the world!|;
