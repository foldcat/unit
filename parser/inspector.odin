package parser

import "core:fmt"
import "core:log"

print_tabs :: proc(nest_count: i8) {
	for _ in 0 ..< nest_count {
		fmt.print("\t")
	}
}

Cons_Value :: struct {
	data: Item,
	pos:  Position,
}

print_data :: proc(data: Cons_Value) {
	fmt.println(data.data, "at", data.pos)

}

print_pos :: proc(s: string, pos: Position) {
	fmt.println(s, "at", pos)
}

print_scope :: proc(scope: Scope, pos: Position) {
	switch scope.is_ending {
	case false:
		switch scope.type {
		case .Scope:
			print_pos("(", pos)
		case .Vector:
			print_pos("[", pos)
		case .Map:
			print_pos("{", pos)
		}
	case true:
		switch scope.type {
		case .Scope:
			print_pos(")", pos)
		case .Vector:
			print_pos("]", pos)
		case .Map:
			print_pos("}", pos)
		}
	}

}


print_ast :: proc(ast: ^Cons, nest_level: i8 = 0) {
	// need to rethink about this 
	// i am repacking data I just packed
	tree := #soa[dynamic]Cons_Value{}
	defer delete(tree)

	buffer: ^Cons = ast

	for { 	// split everything and push into tree
		if buffer.next == nil {
			append_soa(&tree, Cons_Value{data = buffer.item, pos = buffer.pos})
			break
		} else {
			append_soa(&tree, Cons_Value{data = buffer.item, pos = buffer.pos})
			buffer = buffer.next
		}
	}

	// now traverse it 
	for raw_item in tree {
		#partial switch item in raw_item.data {
		case ^Cons:
			print_ast(item, nest_level + 1)
		case Data:
			#partial switch data in item {
			case Scope:
				print_tabs(nest_level - 1)
				print_scope(data, raw_item.pos)
			case Prog:
			// do nothing
			case:
				print_tabs(nest_level)
				print_data(raw_item)
			}
		}
	}
}
