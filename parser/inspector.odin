package parser
import "core:fmt"

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
