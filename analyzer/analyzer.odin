package analyzer

// analyzer type checks the AST, hopefully it works

import parser "../parser"
import stack "../stack"
import "core:fmt"

// shouldn't do it recursively anymore

walk :: proc(ast: ^parser.Cons) {
	// might just be trampolining
	call_stack := stack.make_stack(^parser.Cons)
	defer stack.destroy_stack(call_stack)

	nest_level := 0
	current := ast

	// we assume the ast isn't broken
	for {
		switch &data in current.item {
		case ^parser.Cons:
			nest_level += 1
			stack.stack_push(call_stack, current)
			current = data
		case parser.Data:
			parser.print_tabs(i8(nest_level))
			fmt.println(data)
			if current.next == nil {
				res, ok := stack.stack_pop(call_stack)
				if !ok {
					return
				}
				nest_level -= 1
				current = res.next
			} else {
				current = current.next
			}
		}
	}
}

is_valid :: proc(ast: parser.Cons) -> (validity := true) {
	return
}
