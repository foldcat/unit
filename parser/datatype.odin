package parser

Data :: union {
	String,
	Auto_Num,
	Function,
	Bool,
	Atom,
	Reference,
	Scope_Start,
	Scope_End,
	Prog_Start,
}

String :: struct {
	data: string,
}

Auto_Num :: struct {
	data: i64,
}

Function :: struct {
	name: string,
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

// these two are empty
Scope_Start :: struct {}
Scope_End :: struct {}

Prog_Start :: struct {}
