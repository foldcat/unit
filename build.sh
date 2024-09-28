#!/bin/sh

# this is so ugly

logo="     _________________________/\/\______/\/\_____
    _/\/\__/\/\__/\/\/\/\____________/\/\/\/\/\_
   _/\/\__/\/\__/\/\__/\/\__/\/\______/\/\_____
  _/\/\__/\/\__/\/\__/\/\__/\/\______/\/\_____
 ___/\/\/\/\__/\/\__/\/\__/\/\/\____/\/\/\___
____________________________________________"

echo "$logo"

echo "building unit..."

echo 

echo "updating submodule..."
git submodule update --init --recursive

echo 

echo "checking for the existance of llvm-config..."

echo 

if ! command -v llvm-config &> /dev/null; then
  echo "error: llvm-config command not found. exiting..."
  exit 1
fi

llvm_config_path=$(which llvm-config)

echo "llvm-config is found: $llvm_config_path"

echo 

echo "checking for the existance of odin..."

echo

if ! command -v odin &> /dev/null; then
  echo "error: odin command not found. exiting..."
  exit 1
fi

odin_path=$(which odin)

echo "odin is found: $odin_path"

echo

llvm_obj_file=$($llvm_config_path --libfiles)

if [ ! -f "libLLVM.so" ]; then
  echo "libLLVM.so not found in current directory..."
  echo "creating a symlink..."
  ln -s "$llvm_obj_file" "libLLVM.so"
fi

echo "building unit..."
$odin_path build .

echo

echo "done building"

echo

echo "unit should be ready!"
