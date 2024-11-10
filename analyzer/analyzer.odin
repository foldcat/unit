package analyzer

// analyzer type checks the AST, hopefully it works

import parser "../parser"
import stack "../utility"
import "core:fmt"

// shouldn't do it recursively anymore

walk :: proc(ast: ^parser.Cons) {
	// might just be trampolining
	call_stack, _ := stack.make_stack(^parser.Cons)
	defer stack.destroy_stack(call_stack)

	current := ast
	base := ast // root node, prob a function

	// we assume the ast isn't broken
	for {
		switch &data in current.item {
		case ^parser.Cons:
			stack.stack_push(call_stack, current)
			current = data
			base = data
		// do stuff here

		case parser.Data:
			// do stuff here

			if current.next == nil {
				res, ok := stack.stack_pop(call_stack)
				if !ok {
					return
				}
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
