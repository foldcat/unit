package parser

import "core:log"
import vmem "core:mem/virtual"
import "core:strconv"
import "core:unicode/utf8"

Split_State :: enum {
	in_str,
	in_atom,
}

// could use some parapoly

clear_and_append_string :: proc(
	buffer: ^[dynamic]rune,
	result: ^[dynamic]Data,
	alloc := context.allocator,
) {
	if len(buffer^) != 0 {
		str := utf8.runes_to_string(buffer^[:], alloc) // maybe cause use after free?
		append(result, String{data = str})
		clear(buffer)
	}
}

nums: bit_set['0' ..= '9'] : {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9'}

// cast a string token to a correctly formatted
// number, float or integer
to_number :: proc(
	target: string,
	alloc := context.allocator,
) -> (
	result: Data,
	is_valid := false, // ugh
) {
	is_float := false

	first_time := true // is the first character number

	for char in target {
		if char not_in nums && char != '.' {
			if !first_time {
				panic("non number ref cannot start with number")
			}
			// invalid
			return
		} else if char == '.' && is_float == false {
			is_float = true
		} else if char == '.' && is_float == true {
			// somehow 2 periods in the thing 
			// compain immeidately
			panic("more than 2 periods in a floating number")
		}
		if first_time {
			first_time = false
		}
	}

	if is_float {
		n := strconv.parse_f64(target) or_return
		result = new_clone(Float{data = n}, alloc)^
		is_valid = true
	} else {
		n := strconv.parse_int(target) or_return
		result = new_clone(Integer{data = n}, alloc)^
		is_valid = true
	}

	return
}

// TODO: consider if atoms are even needed
to_atom :: proc(target: string) -> (result: Data, is_valid := false) {
	for char in target { 	// this is quite handful for getting some runes from a string
		if char != ':' { 	// it is not an atom
			return
		} else {
			is_valid = true
			break
		}
	}

	result = Atom {
		data = target,
	} // the : is kept there
	return
}

// i want to be a never nester but
// not every solution are elegant

clear_and_append_reference :: proc(
	buffer: ^[dynamic]rune,
	result: ^[dynamic]Data,
	alloc := context.allocator,
) {
	defer clear(buffer)

	if len(buffer^) != 0 {
		str := utf8.runes_to_string(buffer^[:], alloc) // gets freed, i hope

		res, ok := to_number(str, alloc)
		if ok { 	// if it is a number
			append(result, res)
			return
		}

		res, ok = to_atom(str)
		if ok {
			append(result, res)
			return
		}

		// boolean solution 
		switch str {
		case "true":
			append(result, Bool{data = true})
		case "false":
			append(result, Bool{data = false})
		case:
			append(result, Reference{name = str})
		}
	}
}

// TODO: handle escape sequences
split_sexp :: proc(s: string, alloc := context.allocator) -> (result: ^[dynamic]Data) {
	// literally everything is on the heap now
	// tis surely won't bite me in the back
	result = new([dynamic]Data, alloc)
	buffer := new([dynamic]rune, alloc)
	defer delete(buffer^) // cleanup


	state: Split_State = Split_State.in_atom

	// parses a single line

	for char in s {
		switch state {
		case Split_State.in_atom:
			switch char {
			case '"':
				clear_and_append_reference(buffer, result, alloc)
				state = Split_State.in_str
			case ';':
				// got comment
				clear_and_append_reference(buffer, result, alloc)
				return
			case '\n':
				// end of line
				clear_and_append_reference(buffer, result, alloc)
				break
			case '(':
				clear_and_append_reference(buffer, result, alloc)
				append(result, Scope_Start{})
			case ')':
				clear_and_append_reference(buffer, result, alloc)
				append(result, Scope_End{})
			case '[':
				clear_and_append_reference(buffer, result, alloc)
				append(result, Vector_Start{})
			case ']':
				clear_and_append_reference(buffer, result, alloc)
				append(result, Vector_End{})
			case '{':
				clear_and_append_reference(buffer, result, alloc)
				append(result, Map_Start{})
			case '}':
				clear_and_append_reference(buffer, result, alloc)
				append(result, Map_End{})
			case ' ':
				clear_and_append_reference(buffer, result, alloc)

			case ',':
			// ignore unless 
			case:
				append(buffer, char)
			}
		case Split_State.in_str:
			// append everything till next "
			if char == '\n' {
				panic("unclosed \"")
			} else if char != '"' {
				append(buffer, char)
			} else {
				clear_and_append_string(buffer, result, alloc)
				state = Split_State.in_atom
			}

		}

	}
	return
}
