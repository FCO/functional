use Test;
use lib "lib";
use Functional;

my &get-words  := compose either("no words"), |*.comb(/\w+/);
my &concat     := curry * ~ *;
my &show-count := compose concat("The count is: "), *.elems;

my &prog      := compose fmap(show-count), get-words;

is prog("bla"),                 "The count is: 1";
is prog("bla ble"),             "The count is: 2";
is prog("bla ble bli"),         "The count is: 3";
is prog("bla ble bli blo"),     "The count is: 4";
is prog("bla ble bli blo blu"), "The count is: 5";
dies-ok { prog(""),  "The count is: 5" }
dies-ok { prog(Str), "The count is: 5" }

done-testing;
