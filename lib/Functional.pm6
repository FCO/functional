use MONKEY-SEE-NO-EVAL;
class Function is Callable {
	has 			&.func;
	has Capture 	$.capture = \();
	has 			%!cache;
	has Signature	$.signature = EVAL ":({
		&!func.signature.params.skip(+$!capture).map(*.perl).join(", ")
	} --> {&!func.signature.returns.perl})";

	method !complete-capture(|c) {
		\(|$!capture, |c)
	}

	method count {state $c //= $.signature.count}
	method arity {state $a //= $.signature.arity}

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

	multi method compose(&p, *@ps) {
		$.compose(&p.compose: |@ps.map: -> &func { &func ~~ Function ?? &func !! function &func })
	}

	multi method compose(&p) {
		unless
			$.signature.params.head.type ~~ &p.signature.returns
			and $.signature.params.head.constraints ~~ &p.signature.returns
		{
			die "Impossible to compose a func that returns {&p.signature.returns.perl} with a func receiving {$.signature.perl}"
		}
		self.new: :func(-> |c {self.(p(|c))}), :signature(&p.signature)
	}
}

sub function(&func)						is export	{ Function.new: :func(&func) }
multi int-compose(Function &func)					{ &func }
multi int-compose(&func)							{ function(&func) }
multi int-compose(Function &func, *@funcs)			{ &func.compose: |@funcs }
multi int-compose(&func, *@funcs)					{ function(&func).compose: |@funcs }
our &compose	is export = &int-compose;
sub mcompose(*@funcs)					is export	{ compose |@funcs.map: { fmap $_ } }
sub lift(&func)							is export	{
	Function.new: :func(Function.new: :func(-> *@args {
		do if @args.all.defined {
			func |@args
		} else {
			&func.signature.returns
		}
	}), :signature(&func.signature));
}
our &fmap		is export;
our &either 	is export;
&fmap = function -> &func, \maybe {
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
&either = function -> Any:D $left, $right {
	do with $right {
		$_
	} else { fail $left }
}

multi infix:<o>(Function $a, Function $b) is export {$a.compose($b)}
multi infix:<o>(Function $a, Callable $b) is export {$a.compose($b)}
multi infix:<o>(Callable $a, Function $b) is export {$a.compose($b)}
