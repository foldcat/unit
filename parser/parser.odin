package parser

import "../utility"
import "core:bufio"
import "core:fmt"
import "core:log"
import vmem "core:mem/virtual"
import "core:os"
import "core:strings"

Item :: union {
	^Cons,
	Data,
}


Cons :: struct {
	item: Item, // car
	next: ^Cons, // cdr
}


// don't have a lot of idea what I am doing
// but im sure i will figure something out

// insert Prog_End at the end of the AST
insert_progend :: proc(ast: ^Cons, aalloc := context.allocator) {
	current := ast
	for {
		if current.next != nil {
			current = current.next
		} else {
			break
		}
	}
	prog_end: Data = new(Prog_End, aalloc)^
	end_node := new_clone(Cons{item = prog_end}, aalloc)
	current.next = end_node
}

// parse a file into an AST
parse :: proc(path: string, aalloc := context.allocator) -> ^Cons {
	f, ferr := os.open(path)
	if ferr != 0 {
		panic("failed to open file")
	}
	defer os.close(f)

	file_chunks, err := strings.split(path, "/", aalloc)
	if err != os.ERROR_NONE {
		panic("split string allocation error")
	}
	// must be a better way to do it...
	file_name := file_chunks[len(file_chunks) - 1]

	call_stack, _ := utility.make_stack(^Cons, aalloc)
	defer utility.destroy_stack(call_stack, aalloc)

	// imagine representing the ast with cons cells...

	// when type inference is confused
	p_start: Data = new_clone(Prog_Start{filename = file_name}, aalloc)^
	ast := new_clone(Cons{item = p_start}, aalloc)

	current_cell: ^Cons = ast
	current_buffer := new([dynamic]rune, aalloc)
	defer delete(current_buffer^)

	splitted := new([dynamic]Data, aalloc)
	defer delete(splitted^)

	r: bufio.Reader
	buffer: [1024]byte
	bufio.reader_init_with_buf(&r, os.stream_from_handle(f), buffer[:])

	for {
		line, err := bufio.reader_read_string(&r, '\n', aalloc)
		if err != nil {
			break
		}
		defer delete(line, aalloc)
		line = strings.trim_right(line, "\r")

		current := split_sexp(line, aalloc)
		defer delete(current^)

		for item in current {
			append(splitted, item)
		}

		log.debugf("current line: %s", line)
		log.debug(current)
	}

	log.debug(splitted)


	for raw_item in splitted {
		#partial switch item in raw_item {
		// dry enjoyers im shambles now
		case Scope_Start:
			// append to callstack
			scope: Data = new(Scope_Start, aalloc)^
			new_exp := new_clone(Cons{item = scope}, aalloc)
			res := new_clone(Cons{item = new_exp}, aalloc)
			utility.stack_push(call_stack, res)
			current_cell.next = res
			current_cell = new_exp
		case Vector_Start:
			// append to callstack
			scope: Data = new(Vector_Start, aalloc)^
			new_exp := new_clone(Cons{item = scope}, aalloc)
			res := new_clone(Cons{item = new_exp}, aalloc)
			utility.stack_push(call_stack, res)
			current_cell.next = res
			current_cell = new_exp
		case Map_Start:
			scope: Data = new(Map_Start, aalloc)^
			new_exp := new_clone(Cons{item = scope}, aalloc)
			res := new_clone(Cons{item = new_exp}, aalloc)
			utility.stack_push(call_stack, res)
			current_cell.next = res
			current_cell = new_exp
		case Map_End:
			scope: Data = new(Map_End, aalloc)^
			new_exp := new_clone(Cons{item = scope}, aalloc)
			current_cell.next = new_exp
			res, ok := utility.stack_pop(call_stack)
			if !ok {
				panic("unmatched map")
			}
			current_cell = res
		case Scope_End:
			scope: Data = new(Scope_End, aalloc)^
			new_exp := new_clone(Cons{item = scope}, aalloc)
			current_cell.next = new_exp
			res, ok := utility.stack_pop(call_stack)
			if !ok {
				panic("unmatched parenthesis")
			}
			current_cell = res
		case Vector_End:
			scope: Data = new(Vector_End, aalloc)^
			new_exp := new_clone(Cons{item = scope}, aalloc)
			current_cell.next = new_exp
			res, ok := utility.stack_pop(call_stack)
			if !ok {
				panic("unmatched vector")
			}
			current_cell = res
		case:
			// log.debug(res)
			res := new_clone(Cons{item = item}, aalloc)
			current_cell.next = res
			current_cell = res
		}
	}

	if _, ok := utility.stack_peek(call_stack); ok {
		panic("unmatched parenthesis")
	}

	insert_progend(ast, aalloc)

	return ast
}
