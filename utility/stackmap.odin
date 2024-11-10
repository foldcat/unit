package utility

// stackmap is a combination of a stack 

// it is used to traverse the AST

import "core:fmt"

Node :: struct {
	value: [dynamic]string,
	next:  ^Node,
}

Stack_Map :: struct($T: typeid) {
	kvs:   map[string]T,
	stack: ^Node,
}

// create a stackmap to simulate a scope
make_stackmap :: proc($T: typeid, alloc := context.allocator) -> ^Stack_Map(T) {
	kvs := make(map[string]T)
	arr := make([dynamic]string)
	node := new_clone(Node{value = arr}, alloc)
	return new_clone(Stack_Map(T){stack = node, kvs = kvs}, context.allocator)
}

// add a key value pair to the current stackmap page
sm_add :: proc(sm: ^Stack_Map($T), name: string, value: T) {
	sm.kvs[name] = value
	append(&sm.stack.value, name)
}

// create a new stackmap page
sm_newpage :: proc(sm: ^Stack_Map($T), alloc := context.allocator) {
	arr := make([dynamic]string, alloc)
	sm.stack = new_clone(Node{next = sm.stack, value = arr}, alloc)
}

// delete every item on the current stackmap page and go back 
// to the last page
sm_droppage :: proc(sm: ^Stack_Map($T), alloc := context.allocator) -> (ok: bool) {
	if sm.stack.value == nil || sm.stack == nil {
		return false
	}
	target_node := sm.stack
	for item in sm.stack.value {
		delete_key(&sm.kvs, item)
	}
	sm.stack = target_node.next
	delete(target_node.value)
	free(target_node, alloc)
	return true
}

// lookup a value on the stackmap
sm_lookup :: proc(sm: ^Stack_Map($T), key: string) -> (result: T, ok: bool) {
	return sm.kvs[key]
}

// free the entire stackmap
sm_delete :: proc(sm: ^Stack_Map($T), alloc := context.allocator) {
	current_node := sm.stack
	for current_node != nil {
		temp := current_node
		current_node = current_node.next
		delete(temp.value)
		free(temp, alloc)
	}
	delete(sm.kvs)
	free(sm, alloc)
}
