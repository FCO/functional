use Test;
use lib "lib";
use Functional;

my &add     := curry * + *;
my &incr    := add 1;
my &mult    := curry * × *;

is compose(incr, mult).WHAT, Composed;
is compose(compose(add(1), incr), mult(3)).WHICH, compose(add(1), compose(incr, mult(3))).WHICH;
is compose(compose(add(1), incr), mult(3)).WHICH, compose(add(1), incr, mult(3)).WHICH;

done-testing
