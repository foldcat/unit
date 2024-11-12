package parser

import "core:log"
import vmem "core:mem/virtual"
import "core:strconv"
import "core:strings"
import "core:unicode/utf8"

Split_State :: enum {
	in_str,
	in_atom,
}

// data is bundled with it's position
Value :: struct {
	data: Data,
	pos:  Position,
}

// could use some parapoly

clear_and_append_string :: proc(buffer: ^[dynamic]rune, result: ^[dynamic]Data) {
	if len(buffer^) != 0 {
		str := utf8.runes_to_string(buffer^[:]) // maybe cause use after free?
		append(result, String{data = str})
		clear(buffer)
	}
}

nums: bit_set['0' ..= '9'] : {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9'}

// cast a string token to a correctly formatted
// number, float or integer
to_number :: proc(
	target: string,
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
		result = new_clone(Float{data = n})^
		is_valid = true
	} else {
		n := strconv.parse_int(target) or_return
		result = new_clone(Integer{data = n})^
		is_valid = true
	}

	return
}

// TODO: consider if atoms are even needed
to_atom :: proc(target: string) -> (result: Data, is_valid := false) {
	for char in target { 	// this is quite handful for getting some runes from a string
		if char != ':' { 	// it is not an atom
			log.debug(target)
			return
		} else {
			is_valid = true
			break
		}
	}

	result = Atom { 	// discard the :
		data = strings.trim_left(target, ":"),
	}
	return
}

// i want to be a never nester but
// not every solution are elegant

clear_and_append_reference :: proc(buffer: ^[dynamic]rune, result: ^[dynamic]Data) {
	defer clear(buffer)

	if len(buffer^) != 0 {
		str := utf8.runes_to_string(buffer^[:]) // gets freed, i hope

		res, ok := to_number(str)
		if ok { 	// if it is a number
			append(result, res)
			return
		}

		res, ok = to_atom(str)
		log.debug("is atom")
		log.debug(res, ok)
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

split_sexp :: proc(s: string, scanner_state: ^Position) -> (result: ^[dynamic]Data) {
	// literally everything is on the heap now
	// this surely won't bite me in the back
	result = new([dynamic]Data)
	buffer := new([dynamic]rune)
	defer delete(buffer^) // cleanup

	// something is in the buffer but new line is reached 
	defer clear_and_append_reference(buffer, result)

	state: Split_State = Split_State.in_atom
	is_escaped := false

	// parses a single line

	for char in s {
		scanner_state.x += 1

		switch state {
		case Split_State.in_atom:
			if char == ',' {
				// comma is ignored
				continue
			}

			append_target: Scope

			switch char {
			case '"':
				state = Split_State.in_str
			case ';':
				// comment
				return
			case '\n':
				// end of line
				return
			case '(':
				append_target = Scope {
					type      = Scope_Type.Scope,
					is_ending = false,
				}
			case ')':
				append_target = Scope {
					type      = Scope_Type.Scope,
					is_ending = true,
				}
			case '[':
				append_target = Scope {
					type      = Scope_Type.Vector,
					is_ending = false,
				}
			case ']':
				append_target = Scope {
					type      = Scope_Type.Vector,
					is_ending = true,
				}
			case '{':
				append_target = Scope {
					type      = Scope_Type.Map,
					is_ending = false,
				}
			case '}':
				append_target = Scope {
					type      = Scope_Type.Map,
					is_ending = true,
				}
			case ' ':
				// clear and append if it is space
				clear_and_append_reference(buffer, result)
				continue
			case:
				// build the buffer
				append(buffer, char)
				continue
			}

			clear_and_append_reference(buffer, result)
			append(result, append_target)

		case Split_State.in_str:
			// append everything till next "
			if char == '\\' {
				if !is_escaped {
					is_escaped = true
					continue
				}
			}

			if is_escaped {
				if char == ' ' {
					is_escaped = false
					append(buffer, char)
				} else {
					append(buffer, char)
				}
			} else {
				if char == '\n' {
					panic("unclosed \"")
				} else if char != '"' {
					append(buffer, char)
				} else {
					clear_and_append_string(buffer, result)
					state = Split_State.in_atom
				}
			}
		}
	}
	return
}
