({
    appDir: '.',
    baseUrl: 'src',
    //Uncomment to turn off uglify minification.
    //optimize: 'none',
    dir: 'build',
    mainConfigFile: 'src/main.js',
    //Stub out the cs module after a build since it will not be needed.
    stubModules: ['text', 'cs'],
    paths: {
        'cs': '../coffeescript/cs',
        'coffee-script': '../coffeescript/coffee-script',
        // jquery: 'lib/jquery-1.7.2.min',
        jquery: 'lib/zepto',
        underscore: 'lib/underscore',
        backbone: 'lib/backbone',
        buzz: 'lib/buzz'
    },
    modules: [
        {
            name: 'main',
            //The optimization will load CoffeeScript to convert the CoffeeScript files to plain JS. Use the exclude
            //directive so that the CoffeeScript module is not included in the built file. 
            exclude: ['coffee-script']
        }
    ]
})