#!/bin/sh

echo "building unit..."

echo "updating submodule..."
git submodule update --init --recursive

echo "checking for the existance of llvm-config..."

if ! command -v llvm-config &> /dev/null; then
  echo "error: llvm-config command not found. exiting..."
  exit 1
fi

llvm_config_path=$(which llvm-config)

echo "llvm-config is found: $llvm_config_path"

llvm_obj_file=$($llvm_config_path --libfiles)

if [ ! -f "libLLVM.so" ]; then
  echo "libLLVM.so not found in current directory..."
  echo "creating a symlink..."
  ln -s "$llvm_obj_file" "libLLVM.so"
fi

echo "building unit..."
odin build .

echo "done building"
