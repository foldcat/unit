package parser

import "core:fmt"
import "core:log"
import vmem "core:mem/virtual"

print_tabs :: proc(nest_count: i8) {
	for _ in 0 ..< nest_count {
		fmt.print("\t")
	}
}

Cons_Value :: struct {
	data: Item,
	pos:  Locator,
}

print_data :: proc(data: Cons_Value) {
	fmt.println(data.data, "from", data.pos.start, "to", data.pos.end)

}

print_pos :: proc(s: string, pos: Locator) {
	fmt.println(s, "from", pos.start, "to", pos.end)
}

print_scope :: proc(scope: Scope, pos: Locator) {
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
	arena := vmem.Arena{}
	_err := vmem.arena_allocator(&arena)
	aalloc := vmem.arena_allocator(&arena)
	defer vmem.arena_destroy(&arena)
	context.allocator = aalloc

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
