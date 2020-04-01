# Qt Webassembly Setup tool
A setup tool to automate the download, configuration, installation and compilation of a Qt project with webassembly.

This tool is developed originaly for macOs (Darwin) systems, but minimal changes should make it work in linux operating systems.

## Installation
Typically

```bash
git clone https://github.com/juangpc/qt_wasm_setup.git

cd qt_wasm_setup
chmod +x setup.sh
./setup.sh
```


## Usage

### List of options [default value]

- -ev | --emscriptenVersion <version> Define emscripten compiler version [latest].
- -QtV | --QtVersion <version>        Define Qt version to compile.
- -QtMods | --QtModules <module1,module2,...> 
                                     List (comma separated) of Qt modules to install.
- -NCores| --NumCores <n>           Define the number of cores to be dedicated to the compilation process. [1]
- --QtProjectName                   Define the name of the project to be compiled as wasm.

- -h | --help                       Show help [false]
- -s| --silent                      Decrease the number of messages shown.
- -elist | --listEmscriptenVersions Show a list of possible versions.




```bash
./setup.sh -ev 1.39.11 -Qtv 5.15 -QtModules qtbase,qtcharts,qtsvg
```

