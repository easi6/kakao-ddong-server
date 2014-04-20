# image process
im = require 'imagemagick'
gm = require 'gm'
_path = require 'path'

edgeDetect = (path, cb) ->
  tmppath = "#{path}.tmp"
  gm(path)
    .edge(1)
    .colorspace('gray')
    .write tmppath, (err) ->
      if err
        console.error err
        return cb err, null
      console.log "done"
      return cb null, tmppath

findEdges = (path, cb) ->
  src = spawn "ruby", ["#{__dirname}/process.rb", path]
  positions = []
  src.stdout.on 'data', (data) ->
    lines = data.toString().split("\n")
    #console.log lines
    positions = lines.filter((x) -> x.length > 0).map((x) -> parseInt x.split(",")[0])
    #positions.push parseInt data.split(",")[0]
  src.on 'exit', (code) ->
    cb positions

spawn = require('child_process').spawn
crypto = require 'crypto'

  #findEdges path, (positions) ->

hideProfile = (gm, positions, icn_path) ->
  g = gm
  positions.forEach (y) ->
    g = g
    .out('-page', "+3+#{y-5}")
    .out(icn_path)
  g.flatten()

  #result_path = "/uploads/tmps/#{crypto.randomBytes(8).toString('hex')}_#{(new Date).getTime()}.jpg"
  #g.flatten().write "#{__dirname}/#{result_path}", (err) -> 
    #if err
      #console.error err
    #cb result_path
hideTitle = (gm) ->
  gm.fill('black').drawRectangle(120, 38, 560, 118)

hideNames = (gm, positions) ->
  g = gm.fill('black')
  positions.forEach (y) ->
    g = g.drawRectangle(85, y, 385, y+40)
  g

module.exports =
  edgeDetect: edgeDetect

  mosaic: (path, icn_path, hide_name, hide_title, hide_pic, cb) ->
    if hide_name or hide_pic
      path = "#{__dirname}/#{path}"
      ext = _path.extname path

      findEdges path, (positions) ->
        g = gm(path)
        if hide_name
          g = hideNames g, positions
        if hide_title
          g = hideTitle g
        tmp_path = "/uploads/tmps/#{crypto.randomBytes(8).toString('hex')}_#{(new Date).getTime()}#{ext}"
        g.write "#{__dirname}/#{tmp_path}", (err) -> 
          if not hide_pic
            if (err)
              console.error err
              return cb err
            cb null, tmp_path
          else
            g = hideProfile gm("#{__dirname}/#{tmp_path}"), positions, icn_path
            #base = _path.basename path
            result_path = "/uploads/tmps/#{crypto.randomBytes(8).toString('hex')}_#{(new Date).getTime()}#{ext}"
            g.write "#{__dirname}/#{result_path}", (err) ->
              if (err)
                console.error err
                return cb err
              cb null, result_path
    else
      if hide_title
        path = "#{__dirname}/#{path}"
        g = hideTitle gm(path)
        ext = _path.extname path
        result_path = "/uploads/tmps/#{crypto.randomBytes(8).toString('hex')}_#{(new Date).getTime()}#{ext}"
        g.write "#{__dirname}/#{result_path}", (err) ->
          if (err)
            console.error err
            return cb err
          cb null, result_path
      else
        cb null, path


  hello: () ->
    console.log "hi"
