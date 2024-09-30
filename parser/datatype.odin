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
	Vector_Start,
	Vector_End,
  Map_Start,
  Map_End,
	Integer,
	Float,
	Prog_Start,
  Prog_End,
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

Integer :: struct {
	data: int,
}

Float :: struct {
	data: f64,
}

// these are empty
Scope_Start :: struct {}
Scope_End :: struct {}

Vector_Start :: struct {}
Vector_End :: struct {}

Map_Start :: struct {}
Map_End :: struct {}

Prog_Start :: struct {
	filename: string,
}
Prog_End :: struct {}
