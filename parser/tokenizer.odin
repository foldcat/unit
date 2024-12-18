package parser

import "core:log"
import vmem "core:mem/virtual"
import "core:strconv"
import "core:strings"
import "core:unicode/utf8"

// i am truly baffled by the fact that the tokenizer is 
// harder to write than the parser

// tracking the start and end of nodes are 
// not easy

Split_State :: enum {
	in_str,
	in_atom,
}

// data is bundled with it's position
Value :: struct {
	data: Data,
	pos:  Locator,
}

// bundled state
Tokenizer_State :: struct {
	scanner_state:   ^Position,
	position_buffer: ^Position,
	buffer:          ^[dynamic]rune,
	result:          ^#soa[dynamic]Value,
	split_state:     Split_State,
	is_escaped:      bool,
}

last :: proc(arr: ^#soa[dynamic]$T) -> (last_item: T) {
	for i in arr {
		last_item = i
	}
	return
}

make_value_state :: proc(data: Data, state: Tokenizer_State) -> Value {
	using state

	length: u64
	#partial switch deref_data in data {
	case Scope:
		length = 1
	case String:
		length = cast(u64)len(state.buffer)
		length += 2 // account for the two quotation marks
	case:
		length = cast(u64)len(state.buffer)
	}

	if len(state.buffer) == 1 {
		position_buffer.x -= 1
	}

	return Value{data = data, pos = Locator{start = new_clone(position_buffer^)^, length = length}}

}

make_value_position :: proc(
	data: Data,
	state: Tokenizer_State,
	position_buffer: ^Position,
) -> Value {

	length: u64
	#partial switch deref_data in data {
	case Scope:
		length = 1
	case:
		length = cast(u64)len(state.buffer)
	}

	if len(state.buffer) == 1 {
		position_buffer.x -= 1
	}

	return Value{data = data, pos = Locator{start = new_clone(position_buffer^)^, length = length}}
}

make_value :: proc {
	make_value_state,
	make_value_position,
}

clear_and_append_string :: proc(state: Tokenizer_State) {
	using state
	if len(buffer^) != 0 {
		str := utf8.runes_to_string(buffer^[:]) // maybe cause use after free?
		append_soa(result, make_value(String{data = str}, state))
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

CAF_Caller_Loc :: enum {
	normal,
	space,
	new_line,
}

clear_and_append_reference :: proc(state: Tokenizer_State, loc: CAF_Caller_Loc) {
	using state

	// defer log.debug("result:", last(result))

	defer clear(buffer)
	defer position_buffer.x = scanner_state.x + 1

	start_pos := new_clone(position_buffer)^

	switch loc {
	case .normal:
	case .space:
		start_pos.x += 1
	case .new_line:
		start_pos.x += 1
	}

	// log.debug("pos buffer", start_pos)

	if len(buffer^) != 0 {

		str := utf8.runes_to_string(buffer^[:]) // gets freed, i hope

		res, ok := to_number(str)
		if ok { 	// if it is a number
			append_soa(result, make_value(res, state, start_pos))
			return
		}

		res, ok = to_atom(str)
		if ok {
			start_pos.x -= 1
			append_soa(result, make_value(res, state, start_pos))
			return
		}

		// boolean solution 
		switch str {
		case "true":
			append_soa(result, make_value(Bool{data = true}, state, start_pos))
		case "false":
			append_soa(result, make_value(Bool{data = false}, state, start_pos))
		case:
			append_soa(result, make_value(Reference{name = str}, state, start_pos))
		}
		// log.debug(result)
	}
}

split_sexp :: proc(s: string, scanner_state: ^Position) -> (result: #soa[dynamic]Value) {

	log.debug("tokenizing", s)

	scanner_state.x = 1
	pos_buf := Position{1, scanner_state.y}
	state := Tokenizer_State {
		scanner_state   = scanner_state,
		position_buffer = &pos_buf,
		split_state     = Split_State.in_atom,
		buffer          = new([dynamic]rune),
		result          = &result,
		is_escaped      = false,
	}


	for char, index in s {
		scanner_state.x = cast(u64)index + 1
		// log.debug("scanner state", scanner_state)

		switch state.split_state {
		case Split_State.in_atom:
			append_target: Scope

			switch char {
			case '"':
				state.split_state = Split_State.in_str
				continue
			case ';':
				// comment
				clear_and_append_reference(state, CAF_Caller_Loc.new_line)
				return
			case '\n':
				// end of line
				clear_and_append_reference(state, CAF_Caller_Loc.new_line)
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
			case ' ', ',':
				// clear and append if it is space
				// log.debug("the buffer", state.buffer)
				clear_and_append_reference(state, CAF_Caller_Loc.space)
				continue
			case:
				// build the buffer
				append(state.buffer, char)
				continue
			}

			clear_and_append_reference(state, CAF_Caller_Loc.normal)

			past_pos_buffer := new_clone(state.position_buffer^)
			past_pos_buffer.x -= 1
			// past_scanner_state := new_clone(state.scanner_state^)
			// past_scanner_state.x += 1

			append_soa(&result, make_value(append_target, state, past_pos_buffer))
		// log.debug("current", result)

		case Split_State.in_str:
			// append everything till next "
			if char == '\\' {
				if !state.is_escaped {
					state.is_escaped = true
					continue
				}
			}

			if state.is_escaped {
				if char == ' ' {
					state.is_escaped = false
					append(state.buffer, char)
				} else {
					append(state.buffer, char)
				}
			} else {
				if char == '\n' {
					panic("unclosed \"")
				} else if char != '"' {
					append(state.buffer, char)
				} else {
					clear_and_append_string(state)
					state.split_state = Split_State.in_atom
				}
			}
		}
	}
	return
}
