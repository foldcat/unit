package irgen

import llvm "../llvm"
import parser "../parser"
import "core:os"
import "core:strings"


// generate AST from IR
// should be similar to how the inspector is written
gen_ir :: proc(ast: parser.Cons, alloc := context.allocator) {
	name: cstring
	// i hate this
	#partial switch item in ast.item {
	case parser.Data:
		#partial switch prog_start in item {
		case parser.Prog_Start:
			nm, err := strings.clone_to_cstring(prog_start.filename, alloc)
			if err != os.ERROR_NONE {
				panic("module name cloning to cstring failed")
			}
			name = nm
		}
	}

	mod := llvm.ModuleCreateWithName(name)
}
