package main

import "core:bufio"
import "core:fmt"
import "core:log"
import "core:mem"
import vmem "core:mem/virtual"
import "core:os"
import "core:strings"
import "parser"
import "stack"

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
parse :: proc(path: string) {
	// read a file and parse it

	arena := vmem.Arena{}
	_err := vmem.arena_allocator(&arena)
	aalloc := vmem.arena_allocator(&arena)
	defer free_all(aalloc) // clean everything at the end

	f, ferr := os.open(path)
	defer os.close(f)

	r: bufio.Reader
	buffer: [1024]byte
	bufio.reader_init_with_buf(&r, os.stream_from_handle(f), buffer[:])
	defer bufio.reader_destroy(&r)

	call_stack := stack.make_stack(^Cons, aalloc)
	// defer stack.destroy_stack(call_stack, aalloc)

	// imagine representing the ast with cons cells...
	ast := new_clone(Cons{item = Syntax{type = Syn_Type.prog_start}}, aalloc)

	current_cell: ^Cons = ast
	current_buffer := new([dynamic]rune, aalloc)
	defer delete(current_buffer^)

	splitted := new([dynamic]string, aalloc)
	defer delete(splitted^)

	for {
		line, err := bufio.reader_read_string(&r, '\n', aalloc)
		if err != nil {
			break
		}
		defer delete(line, aalloc)
		line = strings.trim_right(line, "\r")

		current := parser.split_sexp(line, aalloc)
		defer delete(current^)

		for item in current {
			append(splitted, item)
		}

		log.debugf("current line: %s", line)
		log.debug(current)
	}

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

	log.info("===ast===")
	print_ast(ast)
	log.info("===end ast===")
}


print_tabs :: proc(nest_count: i8) {
	for _ in 0 ..< nest_count {
		fmt.print("\t")
	}
}


print_ast :: proc(ast: ^Cons, nest_level: i8 = 0) {
	// soon might have to use a trampoline at this rate 
	tree := [dynamic]Item{}
	defer delete(tree)

	buffer: ^Cons = ast

	// log.debug("printing ast called")
	// log.debug(buffer)

	for { 	// split everything and push into tree
		if buffer.next == nil {
			// log.debug("ast.next nil")
			append(&tree, buffer.item)
			break
		} else {
			// log.debug("item")
			// log.debug(buffer)
			// log.debug(ast.next)
			append(&tree, buffer.item)
			buffer = buffer.next
		}
	}
	// log.debug(tree)

	// now traverse it 
	for item in tree {
		// log.debug(item)
		switch i in item {
		case ^Cons:
			// log.debug("got cons")
			// print_tabs(nest_level)
			// log.debug(item)
			// log.debug(i.next)
			print_ast(i, nest_level + 1)
		case Syntax:
			// log.debug("got syntax")
			#partial switch i.type {
			case Syn_Type.cell_start:
				print_tabs(nest_level - 1)
				fmt.println("(")
			case Syn_Type.cell_end:
				print_tabs(nest_level - 1)
				fmt.println(")")
			case:
				print_tabs(nest_level)
				fmt.println(i)
			}
		}
	}

	// print_tabs(nest_level)
}

main :: proc() {
	// boilerplate
	when ODIN_DEBUG {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)

		defer {
			if len(track.allocation_map) > 0 {
				fmt.eprintf("=== %v allocations not freed: ===\n", len(track.allocation_map))
				for _, entry in track.allocation_map {
					fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
				}
			}
			if len(track.bad_free_array) > 0 {
				fmt.eprintf("=== %v incorrect frees: ===\n", len(track.bad_free_array))
				for entry in track.bad_free_array {
					fmt.eprintf("- %p @ %v\n", entry.memory, entry.location)
				}
			}
			mem.tracking_allocator_destroy(&track)
		}
	}

	logger := log.create_console_logger()
	context.logger = logger
	defer log.destroy_console_logger(logger)

	file := os.args[1]
	log.infof("parsing %s", file)
	parse(file)
}
