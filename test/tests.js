/*jslint devel: true, sloppy: true */
/*global require, test, ok, equal, deepEqual */
var config = require.config({
    baseUrl: "../src",
    paths: {
        cs: '../coffeescript/cs',
        'coffee-script': '../coffeescript/coffee-script',
        // jquery: 'lib/jquery-1.9.1.min',
        jquery: 'lib/zepto',
        underscore: 'lib/underscore',
        backbone: 'lib/backbone',
        buzz: 'lib/buzz'
    },
    shim: {
        // Only necessary when substituting Zepto for jQuery
        'jquery': {
            exports: '$'
        },
        'underscore': {
            exports: '_'
        },
        'backbone': {
            //These script dependencies should be loaded before loading backbone.js
            deps: ['underscore', 'jquery'],
            //Once loaded, use the global 'Backbone' as the module value.
            exports: 'Backbone'
        },
        'buzz': {
            exports: 'buzz'
        }
    }
});

config([
    'jquery',
    'cs!views/game'
], function ($, GameView) {

    // Helper function to quickly place pieces in order to test move validation
    var placePiece = function (index, color) {
        var square,
            piece;

        square = $('#game .board > div').eq(index);
        piece = $('<div class="piece"><div class="white"></div><div class="black"></div>').data('color', color);

        square.append(piece);
    };

    test("Game board setup and piece placement", function () {
        var game,
            square;

        game = new GameView({ 'el': $('#qunit-fixture') });

        ok(typeof game === "object", "GameView was instantiated");

        // Initializes teh game board
        game.reset();

        ok(game.currentPlayer === 'black', 'Black always moves first');
        deepEqual(game.canPlay('black'), [27, 28, 35, 36], "Initial squares for piece placement are valid.");

        // Simulate user interaction
        square = $('#game .board > div').eq(27);
        square.trigger('click');

        ok(square.children('.piece').length === 1, "A piece was created on the game board.");
        ok(square.children('.piece').data('color') === 'black', 'Piece was black.');

        ok(game.currentPlayer === 'white', 'Turn passed to other player');
        deepEqual(game.canPlay('white'), [28, 35, 36], "White's available moves are correct.");

        // Simulate user interaction
        square = $('#game .board > div').eq(28);
        square.trigger('click');

        ok(square.children('.piece').length === 1, "A piece was created on the game board.");
        ok(square.children('.piece').data('color') === 'white', 'Piece was white.');

        // Can't play on an already used spot
        square.trigger('click');

        ok(square.children('.piece').length === 1, "Only one game piece per square.");
        ok(square.children('.piece').data('color') === 'white', 'Piece played first still occupies square.');
    });

    test("Piece placement validation", function () {
        ok(true, "True!");
    });
});