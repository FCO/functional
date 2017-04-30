use MONKEY-SEE-NO-EVAL;
class Composed {...}
class Curry is Callable {
	has 			&.func;
	has Capture 	$.capture = \();
	has 			%!cache;
	has Signature	$.signature = self!build-signature;

	method !build-signature {
		EVAL ":({
			&!func.?signature.params.skip(+$!capture).map(*.perl).join(", ")
		} --> {&!func.?signature.returns.perl})";
	}

	method !complete-capture(|c) {
		\(|$!capture, |c)
	}

	method count {state $c //= $!signature.count}
	method arity {state $a //= $!signature.arity}

	proto method CALL-ME(|c) is hidden-from-backtrace {
		do if %!cache{c.perl}:exists {
			%!cache{c.perl}
		} else {
			%!cache{c.perl} = {*};
		}
	}

	multi method CALL-ME() {
		self
	}

	multi method CALL-ME(|c where $!signature) {
		my Capture $complete = self!complete-capture: |c;
		&!func.(|$complete)
	}

	multi method CALL-ME(|c) is default {
		my @cparams = c.Array;
		for $!signature.params.head(+@cparams) -> $p {
			my $cp = @cparams.shift;
			die "Value { $cp.perl } doesn't fit into ({$p.perl})" unless $cp ~~ $p.type and $cp ~~ $p.constraints
		}
		self.new: :func(&!func), :capture(self!complete-capture: |c);
	}

	method assuming(|c) { $.CALL-ME(|c) }

	multi method compose(&p, *@ps --> Composed) {
		$.compose(&p).compose: |@ps>>.&curry
	}

	multi method compose(&p --> Composed) {
		unless
			$.signature.params.head.type ~~ &p.signature.returns
			and $.signature.params.head.constraints ~~ &p.signature.returns
		{
			die "Impossible to compose a func that returns {&p.signature.returns.perl} with a func receiving {$.signature.perl}"
		}
		Composed.new: :funcs[self, |Composed.compose-to-curry-arr(&p)]
	}
}

class Composed is Curry {
	my %cache;
	has @.funcs where *.elems >= 1;
	has Str $.key;

	sub build-signature(@funcs) { @funcs.tail.signature }

	sub build-func(@funcs) {
		-> |c {
			sub rec-run([&f, *@fs], Capture \cap) {
				do if not @fs {
					f |cap;
				} else {
					f rec-run @fs, cap;
				}
			}
			rec-run @funcs, c
		}
	}

	method BUILDALL(%pars) {
		%pars<func>			//= build-func(%pars<funcs> // []);
		%pars<signature>	//= build-signature(%pars<funcs>);

		my $key = "{%pars<funcs>.map(*.WHICH).join: ", "} -> {%pars<capture>.WHICH}";

		do with %cache{$key} {
			$_
		} else {
			%pars<key> = $key;
			%cache{$key} := callwith %pars;
		}
	}

	multi method compose-to-curry-arr(Composed:U: $c) {
		[$c]
	}
	multi method compose-to-curry-arr(Composed:U: Composed $c) {
		[|$c.funcs.head(*-1).flatmap({Composed.compose-to-curry-arr: $_}), curry($c.funcs.tail).(|$c.capture)]
	}

	method compose(*@f --> Composed) {
		self.new: :funcs[|Composed.compose-to-curry-arr(self), |@f.flatmap({Composed.compose-to-curry-arr: $_})]
	}
}

multi curry(Curry \func) is default     is export	{ func }
multi curry(&func)                      is export	{ Curry.new: :func(&func) }
sub compose(&f, *@funcs)                is export	{ curry(&f).compose: |@funcs>>.&curry }
sub mcompose(*@funcs)                   is export	{ compose |@funcs.map: { fmap $_ } }
sub lift(&func)                         is export	{
	Curry.new: :func(Curry.new: :func(-> *@args {
		do if @args.all.defined {
			func |@args
		} else {
			&func.signature.returns
		}
	}), :signature(&func.signature));
}
our &fmap		is export;
our &either 	is export;
&fmap = curry -> &func, \maybe {
	given maybe {
		when Failure {
			maybe
		}
		when *.defined {
			func maybe
		}
		default {
			&func.signature.returns
		}
	}
}
&either = curry -> Any:D $left, $right {
	do with $right {
		$_
	} else { fail $left }
}

multi infix:<o>(Curry $a, Curry $b)     is export {compose $a, $b}
multi infix:<o>(Curry $a, Callable $b)  is export {compose $a, $b}
multi infix:<o>(Callable $a, Curry $b)  is export {compose $a, $b}
