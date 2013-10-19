"use strict"

module = angular.module 'turtle', [
  'ngResource'
  'ngRoute'
  'ngSanitize'
]

# Config

module.config ($routeProvider, $locationProvider) ->
  $routeProvider.when "/",
    templateUrl: "/templates/turtle/edit.html"
    controller: "TurtleNewController"

  $locationProvider.html5Mode true

# Services

module.factory 'Turtle', ->
  class Command
    constructor: (@command, @args) ->
      @enabled = true

    draw: ->

  class TurnCommand extends Command
    draw: (sketch) ->
      amount = if @args.direction == 'right' then @args.amount else -@args.amount
      amount = amount / 360 * sketch.TWO_PI
      sketch.rotate amount

  class MoveCommand extends Command
    draw: (sketch) ->
      sketch.stroke 255
      sketch.noFill()
      switch @args.direction
        when 'left'
          x = -@args.amount
          y = 0

        when 'right'
          x = @args.amount
          y = 0

        when 'forward'
          x = 0
          y = -@args.amount

        when 'backward'
          x = 0
          y = @args.amount
          
      sketch.line 0, 0, x, y
      sketch.translate x, y

  class ShowCommand extends Command
    draw: (sketch) -> sketch.showTurtle = true

  class HideCommand extends Command
    draw: (sketch) -> sketch.showTurtle = false

  class Turtle
    constructor: ->
      @commands = []
      @newCommand = ''
      @rotation = 0
      @error = null

    addCommand: ->
      parsed = @newCommand.split /\s+/
      @error = null
      
      if @knownCommands[parsed[0]]
        try
          command = @knownCommands[parsed[0]].apply @, parsed[1..]
          @commands.push command
          @newCommand = ''
        catch e
          @error = e
      else
        @error = "I don't understand that command."

    knownCommands:
      turn: (direction, amount) ->
        if isNaN amount
          throw "I can't turn that amount. Try a number."
        
        amount = parseInt amount, 10
        
        switch direction
          when 'left' then new TurnCommand @newCommand, direction: 'left', amount: amount
          when 'right' then new TurnCommand @newCommand, direction: 'right', amount: amount
          else throw "I can only turn 'left' and 'right'"

      move: (direction, amount) ->
        if isNaN amount
          throw "I can't move by that amount. Try a number."

        amount = parseInt amount, 10

        if direction in ['forward', 'backward', 'left', 'right']
          new MoveCommand @newCommand, direction: direction, amount: amount
        else
          throw "I can't move in that direction. Try forward, backward, left, or right."

      show: -> new ShowCommand @newCommand

      hide: -> new HideCommand @newCommand

# Directives

module.directive 'turtleProcessing', ->
  (scope, element, attrs) ->
    scope.$processing = new Processing element[0], scope[attrs.turtleProcessing]

# Usage: <div virgen-disqus shortname="'my_shortname'" identifier="'my_identifier'"></div>
module.directive 'virgenDisqus', ($location, $window, $document) ->
  scope:
    identifier: '='
    shortname: '='
  link: (scope, element, attr) ->
    # Loads Disqus comments
    load = ->
      # Disqus requires these global variables to be set
      $window.disqus_shortname = scope.shortname
      $window.disqus_identifier = scope.identifier
      dsq = document.createElement 'script'
      dsq.type = 'text/javascript'
      dsq.async = true
      dsq.src = "//#{scope.shortname}.disqus.com/embed.js"
      $document.find('head').append dsq

    # Resets Disqus comments for page navigation
    reset = ->
      $window.DISQUS.reset
        reload: true
        config: -> @page.identifier = scope.identifier

    element.attr 'id', 'disqus_thread'
    $window.disqus_element = element
    if $window.DISQUS? then reset() else load()

# Controllers

module.controller 'TurtleNewController', ($scope, Turtle) ->
  width = 720
  height = width * 9 / 16
  
  $scope.turtle = new Turtle

  $scope.remove = (command) ->
    index = $scope.turtle.commands.indexOf command
    $scope.turtle.commands.splice index, 1 if -1 != index

  $scope.sketch = (sketch) ->
    rotation = 0

    sketch.setup = ->
      sketch.smooth()
      sketch.colorMode sketch.HSB, 255
      sketch.strokeCap sketch.ROUND
      sketch.strokeJoin sketch.ROUND
      sketch.size width, height
      sketch.frameRate 15

    sketch.draw = ->
      sketch.showTurtle = true
      sketch.translate width / 2, height / 2
      sketch.background 0
      for command in $scope.turtle.commands
        command.draw sketch if command.enabled

      # draw turtle
      if sketch.showTurtle
        sketch.noStroke()
        sketch.fill 255
        sketch.triangle -8, 0, 0, -20, 8, 0
        sketch.triangle -4, 0, 0, 5, 4, 0
