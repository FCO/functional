use Test;
use lib "lib";
use Functional;

my &add		:= function * + *;
my &incr	:= add 1;
my &mult	:= function * × *;

is compose(incr, mult).WHAT, Function;
is compose(compose(add(1), incr, mult(3))).($_), compose(add(1), compose(incr, mult(3))).($_) for ^10;

done-testing
