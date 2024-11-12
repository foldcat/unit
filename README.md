```
     _________________________/\/\______/\/\_____
    _/\/\__/\/\__/\/\/\/\____________/\/\/\/\/\_
   _/\/\__/\/\__/\/\__/\/\__/\/\______/\/\_____
  _/\/\__/\/\__/\/\__/\/\__/\/\______/\/\_____
 ___/\/\/\/\__/\/\__/\/\__/\/\/\____/\/\/\___
____________________________________________
```

Unit is a high level imperative lisp dialect that aims to 
target real time applications such as cli and gui utilities.
It is written in Odin and aims to target the LLVM platform.

Unit is far from finished and is currently a prototype, which 
only the parser is partially implemented.

# building and running
```bash
odin build . -debug # debug build 
odin build . # release build

# now execute it
./unit file.unit
```
