package parser

import vmem "core:mem/virtual"
import "core:unicode/utf8"

Split_State :: enum {
	in_str,
	in_atom,
}

clear_and_append :: proc(
	buffer: ^[dynamic]rune,
	result: ^[dynamic]string,
	alloc := context.allocator,
) {
	if len(buffer^) != 0 {
		str := utf8.runes_to_string(buffer^[:], alloc) // maybe cause use after free?
		append(result, str)
		clear(buffer)
	}
}

// TODO: handle escape sequences
split_sexp :: proc(s: string, alloc := context.allocator) -> ^[dynamic]string {
	// literally everything is on the heap now
	// tis surely won't bite me in the back
	result := new([dynamic]string, alloc)
	buffer := new([dynamic]rune, alloc)
	defer delete(buffer^) // cleanup


	state: Split_State = Split_State.in_atom

	// parses a single line

	for char in s {
		switch state {
		case Split_State.in_atom:
			switch char {
			case '"':
				clear_and_append(buffer, result, alloc)
				append(buffer, '"')
				state = Split_State.in_str
			case ';':
				// got comment
				if len(buffer^) != 0 {
					clear_and_append(buffer, result, alloc)
				}
				break
			case '\n':
				// end of line
				break
			case '(':
				clear_and_append(buffer, result, alloc)
				append(result, "(")
			case ')':
				clear_and_append(buffer, result, alloc)
				append(result, ")")
			case ' ':
				clear_and_append(buffer, result, alloc)

			case ',':
			// ignore unless 
			case:
				append(buffer, char)
			}
		case Split_State.in_str:
			// append everything till next "
			if char != '"' {
				append(buffer, char)
			} else {
				append(buffer, '"')
				clear_and_append(buffer, result, alloc)
				state = Split_State.in_atom
			}

		}

	}
	return result
}
