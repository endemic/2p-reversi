#!/bin/sh

echo "Converting .less to .css"
lessc assets/stylesheets/main.less > assets/stylesheets/main.css

# Concatenate the project files
node tools/r.js -o build.js

echo "Optimizing .js source with Closure Compiler"
java -jar tools/compiler.jar --js build/src/main.js --js_output_file build/src/main-compiled.js

# Remove .svn directories from the build directory, if using SVN
# echo "Removing .svn directories..."
# rm -rf `find ./build -type d -name .svn`

echo "Removing .DS_Store files"
rm -rf `find ./build -type f -name .DS_Store`

echo "Copying to iOS app"
cp build/src/main-compiled.js targets/ios/www/src/main-compiled.js
cp -R build/assets targets/ios/www

echo "Removing build directory"
rm -rf build

echo 'Done!'