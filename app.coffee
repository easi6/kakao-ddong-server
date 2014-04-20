crypto = require 'crypto'

mongoose = require 'mongoose'
mongoose.connect 'mongodb://localhost/katalk_capture'

mosaic = require './mosaic.coffee'

Capture = null

db = mongoose.connection
db.on 'error', () ->
  console.error 'db connection error'
db.once 'open', () ->
  # schema definitions
  captureSchema = mongoose.Schema image_path: String
  # model definitions
  Capture = mongoose.model 'Capture', captureSchema

fs = require 'fs'
_path = require 'path'

express = require 'express'
app = express()

app.use express.bodyParser()
app.use express.json()
app.use express.urlencoded()
app.use express.multipart()
app.use express.static __dirname

app.get '/hello.txt', (req, res) ->
  res.send "Hello, World!"

app.post '/upload', (req, res) ->
  #console.log req.files
  #console.log req.body

  hide_name = parseInt(req.body.name) == 1
  hide_title = parseInt(req.body.title) == 1
  hide_picture = parseInt(req.body.picture) == 1

  icon_path = if req.body.icon_path? then "#{__dirname}/#{req.body.icon_path}" else "#{__dirname}/assets/smiley.png"

  doProcess = (original_path) ->
    mosaic.mosaic original_path, icon_path, 
      hide_name, hide_title, hide_picture, (err, res_path) ->
        console.log "res_path = #{res_path}"
        res.send {path: res_path, original_path: original_path}

  if req.body.original_path?
    doProcess req.body.original_path
  else
    filepath = req.files.capture_image.path
    fs.readFile filepath, (err, data) ->
      #flags
      console.log "name = #{hide_name}"
      console.log "title = #{hide_title}"
      console.log "picture = #{hide_picture}"

      # save (Assume it is converted into jpg)
      newpath = "/uploads/tmps/#{crypto.randomBytes(8).toString('hex')}_#{(new Date).getTime()}#{_path.extname filepath}"
      fs.writeFile "#{__dirname}/#{newpath}", data, (err) ->
        doProcess newpath

app.get "/show/:id", (req, res) ->
  console.log "id = #{req.params.id}"
  Capture.findOne _id: req.params.id, (err, capture) ->
    res.send capture

app.post '/confirm', (req, res) ->
  # get tmp file from uploads directory
  tmppath = "#{__dirname}/#{req.body.path}"
  newpath = "/uploads/captures/#{crypto.randomBytes(8).toString('hex')}_#{(new Date).getTime()}.jpg"
  fs.rename tmppath, "#{__dirname}/#{newpath}", (err) ->
    # write to db
    capture = new Capture image_path: newpath
    capture.save (err, capture) ->
      if err
        console.error err
        return res.send error: "internal server error", 500
      res.send capture

app.get '/', (req, res) ->
  prev_id = req.query.prev_id
  console.log "prev_id = #{prev_id}"
  query = null
  if prev_id?
    query = Capture.find({_id: {$lt: mongoose.Types.ObjectId(prev_id)}}).limit(8).sort({_id: -1})
  else
    query = Capture.find().limit(8).sort({_id: -1})
  query.exec (err, captures) ->
    if err
      console.error err
      return res.send error: "internal server error", 500
    res.send captures

server = app.listen 3000, () ->
  console.log "Listening on port %d", server.address().port
