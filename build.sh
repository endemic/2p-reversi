#!/bin/sh

# Remove the previous build directory
rm -rf build

# Concatenate the project files
node tools/r.js -o build.js

# If you want to, download the Closure Compiler and put the .jar in the /tools directory
# java -jar tools/compiler.jar --js build/src/main.js --js_output_file build/src/main-compiled.js

# Remove .svn directories from the build directory, if using SVN
# echo "Removing .svn directories..."
# rm -rf `find ./build -type d -name .svn`