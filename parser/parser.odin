package parser

import "../utility"
import "core:bufio"
import "core:fmt"
import "core:log"
import vmem "core:mem/virtual"
import "core:os"
import "core:strings"

// the plan 
// Cons {
//  item: Item union {
//    ^Cons, // nest
//    Data
//    }
// }
//  next: ^Cons
//  position: Position
// }

Position :: [2]i64

Locator :: struct {
	start: Position,
	end:   Position,
}


Item :: union {
	^Cons,
	Data,
}

Cons :: struct {
	item: Item, // car
	next: ^Cons, // cdr
	pos:  Locator,
}

// don't have a lot of idea what I am doing
// but im sure i will figure something out

// insert Prog_End at the end of the AST
insert_progend :: proc(ast: ^Cons) {
	current := ast
	for {
		if current.next != nil {
			current = current.next
		} else {
			break
		}
	}
	prog_end: Data = new_clone(Prog{is_ending = true})^
	end_node := new_clone(Cons{item = prog_end})
	current.next = end_node
}

// build a Cons carrying Data
make_cons :: proc($T: typeid) -> ^Cons {
	data: Data = new(T)^
	new_exp := new_clone(Cons{item = data})
	return new_clone(Cons{item = new_exp})
}

// parse a file into an AST
parse :: proc(path: string) -> ^Cons {
	f, ferr := os.open(path)
	if ferr != 0 {
		panic("failed to open file")
	}
	defer os.close(f)

	file_chunks, err := strings.split(path, "/")
	if err != os.ERROR_NONE {
		panic("split string allocation error")
	}
	// must be a better way to do it...
	file_name := file_chunks[len(file_chunks) - 1]

	call_stack, _ := utility.make_stack(^Cons)
	defer utility.destroy_stack(call_stack)

	// imagine representing the ast with cons cells...

	// when type inference is confused
	p_start: Data = Prog {
		filename = file_name,
	}
	ast := new_clone(Cons{item = p_start})

	current_cell: ^Cons = ast

	splitted: #soa[dynamic]Value
	defer delete(splitted)

	r: bufio.Reader
	buffer: [1024]byte
	bufio.reader_init_with_buf(&r, os.stream_from_handle(f), buffer[:])

	// i love how odin lets you array.x array.y
	scanner_state: Position

	for {
		line, err := bufio.reader_read_string(&r, '\n')

		scanner_state.y += 1

		if err != nil {
			break // either eof or something else
		}
		defer delete(line)

		line = strings.trim_right(line, "\r")

		log.debugf("current line: %s", line)

		current := split_sexp(line, &scanner_state)
		defer delete(current)

		log.debug("current splitted line", current)

		for item in current {
			log.debug("appending", item)
			append_soa(&splitted, item)
		}
	}

	log.debug("final parsed array:")
	log.debug(splitted)


	for raw_item in splitted {
		#partial switch item in raw_item.data {
		case Scope:
			// append to callstack
			if !item.is_ending {
				scope: Data = new_clone(item)^
				// need to rethink about this
				// log.debug("pos", raw_item.pos)
				new_exp := new_clone(Cons{item = scope, pos = raw_item.pos})
				res := new_clone(Cons{item = new_exp})
				utility.stack_push(call_stack, res)
				current_cell.next = res
				current_cell = new_exp
			} else {
				scope: Data = new_clone(item)^
				new_exp := new_clone(Cons{item = scope, pos = raw_item.pos})
				current_cell.next = new_exp
				res, ok := utility.stack_pop(call_stack)
				if !ok {
					panic("unmatched stuff")
				}
				current_cell = res
			}
		case:
			// log.debug(res)
			res := new_clone(Cons{item = item, pos = raw_item.pos})
			current_cell.next = res
			current_cell = res
		}
	}

	if _, ok := utility.stack_peek(call_stack); ok {
		panic("unmatched parenthesis")
	}

	insert_progend(ast)

	return ast
}
