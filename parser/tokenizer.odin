package parser

import "core:log"
import vmem "core:mem/virtual"
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

clear_and_append_reference :: proc(
	buffer: ^[dynamic]rune,
	result: ^[dynamic]Data,
	alloc := context.allocator,
) {
	if len(buffer^) != 0 {
		str := utf8.runes_to_string(buffer^[:], alloc) // gets freed, i hope

		// boolean solution 
		switch str {
		case "true":
			append(result, Bool{data = true})
		case "false":
			append(result, Bool{data = false})
		case:
			append(result, Reference{name = str})
		}
		clear(buffer)
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
