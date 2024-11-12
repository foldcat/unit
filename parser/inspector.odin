package parser

import "core:fmt"

print_tabs :: proc(nest_count: i8) {
	for _ in 0 ..< nest_count {
		fmt.print("\t")
	}
}

print_scope :: proc(scope: Scope) {
	switch scope.is_ending {
	case false:
		switch scope.type {
		case .Scope:
			fmt.println("(")
		case .Vector:
			fmt.println("[")
		case .Map:
			fmt.println("{")
		}
	case true:
		switch scope.type {
		case .Scope:
			fmt.println(")")
		case .Vector:
			fmt.println("]")
		case .Map:
			fmt.println("}")
		}
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
	for raw_item in tree {
		// log.debug(item)
		#partial switch item in raw_item {
		case ^Cons:
			print_ast(item, nest_level + 1)
		case Data:
			// log.debug("got syntax")
			#partial switch data in item {
			case Scope:
				print_tabs(nest_level - 1)
				print_scope(data)
			case Prog:
			// do nothing
			case:
				print_tabs(nest_level)
				fmt.println(item)
			}
		}
	}
	// print_tabs(nest_level)
}
