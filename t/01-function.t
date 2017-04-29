use Test;
use lib "lib";
use Functional;

my &add := function * + *;

is &add.WHAT, Function;
is add, &add;

my &incr := add 1;
is &incr.WHAT, Function;
is incr, &incr;
is incr(2), 3;

is add(add(1, 2), 4), add(1, add(2, 4));
is add(4, 1), add(1, 4);

for ^10 -> \n {
	is add(n, 0), add(0, n);
}

my &mult := function * × *;
is mult(2, add(3, 4)), add(mult(2, 3), mult(2, 4));

done-testing
