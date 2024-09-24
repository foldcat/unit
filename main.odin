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

	arena := vmem.Arena{}
	_err := vmem.arena_allocator(&arena)
	aalloc := vmem.arena_allocator(&arena)
	defer vmem.arena_destroy(&arena) // won't need it more than once

	ast := parser.parse(file, aalloc)
	log.info("===begin AST===")
	parser.print_ast(ast)
	log.info("===end AST===")
}
