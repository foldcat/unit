package main

import "analyzer"
import "core:bufio"
import "core:fmt"
import "core:log"
import "core:mem"
import vmem "core:mem/virtual"
import "core:os"
import "core:strings"
import "irgen"
import "llvm"
import "parser"
import "utility"

compile_job :: proc() {
	file := os.args[1]
	log.infof("parsing %s", file)

	arena := vmem.Arena{}
	_err := vmem.arena_allocator(&arena)
	aalloc := vmem.arena_allocator(&arena)
	defer vmem.arena_destroy(&arena) // won't need it more than once

	context.allocator = aalloc // just in case

	ast := parser.parse(file)
	log.info("===begin AST===")
	parser.print_ast(ast)
	log.info("===end AST===")
}


main :: proc() {
	logger := log.create_console_logger(log.Level.Info)

	// boilerplate
	when ODIN_DEBUG {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)

		logger = log.create_console_logger(log.Level.Debug)

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

	context.logger = logger
	defer log.destroy_console_logger(logger)

	if len(os.args) == 1 {
		log.info("unit compiler")
		log.infof("usage: %s file.unit", os.args[0])
		os.exit(0)
	}

	compile_job()
}
