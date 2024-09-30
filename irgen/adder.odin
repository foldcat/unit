package irgen

// this is strictly for testing if libLLVM works

import llvm "../llvm"

gen_sum :: proc() {
	mod := llvm.ModuleCreateWithName("sum")
	param_types := [?]llvm.TypeRef{llvm.Int32Type(), llvm.Int32Type()}
	ret_type := llvm.FunctionType(llvm.Int32Type(), &param_types, 2, 0)
	sum := llvm.AddFunction(mod, "sum", ret_type)

	entry := llvm.AppendBasicBlock(sum, "entry")

	builder := llvm.CreateBuilder()
	llvm.PositionBuilderAtEnd(builder, entry)
	tmp := llvm.BuildAdd(builder, llvm.GetParam(sum, 0), llvm.GetParam(sum, 1), "tmp")
	llvm.BuildRet(builder, tmp)
  llvm.DumpModule(mod)
}
