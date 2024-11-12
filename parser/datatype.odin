package parser

Data :: union {
	String,
	Auto_Num,
	Bool,
	Atom,
	Reference,
	Scope,
	Integer,
	Float,
	Prog,
}

Function :: struct {
	// type env
	namespace: string,
	name:      string,
}

String :: struct {
	data: string,
}

Auto_Num :: struct {
	data: i64,
}

Bool :: struct {
	data: bool,
}

// need closer consideration as atom might not even be needed
Atom :: struct {
	data: string,
}

Reference :: struct {
	name: string,
}

Integer :: struct {
	data: int,
}

Float :: struct {
	data: f64,
}

Scope_Type :: enum {
	Scope,
	Vector,
	Map,
}

Scope :: struct {
	type:      Scope_Type,
	is_ending: bool,
}


Prog :: struct {
	filename:  string,
	is_ending: bool,
}
