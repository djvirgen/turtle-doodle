express = require 'express'
connectCoffeeScript = require 'connect-coffee-script'
stylus = require 'stylus'
deepExtend = require 'deep-extend'
app = express()
port = process.env.PORT or 3000

app.set 'views', "#{__dirname}/views"
app.set 'view engine', 'jade'
app.use express.bodyParser()
app.use stylus.middleware
  src: "#{__dirname}/../assets"
  dest: "#{__dirname}/../public"
  compile: (str, path, fn) ->
    stylus(str)
    .set('filename', path)
    .set('compress', true)
app.use connectCoffeeScript
    src: "#{__dirname}/../assets"
    dest: "#{__dirname}/../public"
app.use express.static "#{__dirname}/../public"

app.get '/', (req, res) ->
  res.render 'app'

app.get '*', (req, res) ->
  res.redirect "/##{req.path}"

app.listen port, -> console.log port, __dirname
