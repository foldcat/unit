package parser

import "../stack"
import "core:bufio"
import "core:fmt"
import "core:log"
import vmem "core:mem/virtual"
import "core:os"
import "core:strings"

Syn_Type :: enum {
	cell_start, // (
	cell_end, // )
	prog_start, // default
	function, // (this)
	string, // "a"
	int, // 1
	true,
	false,
}

Syntax :: struct {
	type: Syn_Type,
	name: string,
}

Item :: union {
	^Cons,
	Syntax,
}


Cons :: struct {
	item: Item, // car
	next: ^Cons, // cdr
}


// don't have a lot of idea what I am doing
// but im sure i will figure something out

// parse a file into an AST
parse :: proc(path: string, aalloc := context.allocator) -> ^Cons {
	file, ok := os.read_entire_file(path, aalloc)
	defer delete(file, aalloc)

	call_stack := stack.make_stack(^Cons, aalloc)
	defer stack.destroy_stack(call_stack, aalloc)

	// imagine representing the ast with cons cells...
	ast := new_clone(Cons{item = Syntax{type = Syn_Type.prog_start}}, aalloc)

	current_cell: ^Cons = ast
	current_buffer := new([dynamic]rune, aalloc)
	defer delete(current_buffer^)

	splitted := split_sexp(string(file), aalloc)

	log.debug(splitted)


	for item in splitted {
		switch item {
		case "(":
			// append to callstack 
			new_exp := new_clone(
				Cons{item = Syntax{type = Syn_Type.cell_start, name = "("}},
				aalloc,
			)
			stack.stack_push(call_stack, current_cell)
			current_cell.item = new_exp
			// log.debug("new exp")
			// log.debug(new_exp)
			// stack.print_stack(call_stack)
			current_cell = new_exp
		// log.info("new nest")
		// log.info(new_exp)
		case ")":
			// pop and peek
			// log.info("got )")
			new_exp := new_clone(Cons{item = Syntax{type = Syn_Type.cell_end, name = ")"}}, aalloc)
			current_cell.next = new_exp
			// stack.print_stack(call_stack)
			res, ok := stack.stack_pop(call_stack)
			// stack.print_stack(call_stack)
			// log.info(res)
			if !ok {
				log.error("unmatched parenthesis")
				panic("unmatched parenthesis")
			}
			current_cell = res
		case:
			res := new_clone(Cons{item = Syntax{type = Syn_Type.string, name = item}}, aalloc)
			// log.debug(res)
			current_cell.next = res
			current_cell = res
		}
	}

	// log.info("===ast===")
	// print_ast(ast)
	// log.info("===end ast===")
	return ast
}
