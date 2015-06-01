http = require 'http'
os = require 'os'
url = require 'url'
util = require 'util'
sharp = require 'sharp'
request = require('request').defaults({ encoding: null })

DEFAULT_CROP_WIDTH = 250
DEFAULT_CROP_HEIGHT = null
DEFAULT_CROP_GRAVITY = 'north'

config =
    PORT: 2450

n_reqs = 0
n_reqs_failed = 0

server = http.createServer (req, res) ->

    if req.url == '/status'
        res.end JSON.stringify
            n_reqs: n_reqs
            failure_rate: n_reqs_failed / n_reqs
            memory: process.memoryUsage()
            loads: os.loadavg()
            uptime: process.uptime()

    else
        url_parts = url.parse req.url, true
        crop_width = Number(url_parts.query.width) or DEFAULT_CROP_WIDTH
        crop_height = Number(url_parts.query.height) or DEFAULT_CROP_HEIGHT
        crop_gravity = url_parts.query.gravity or DEFAULT_CROP_GRAVITY
        image_url = url_parts.query.url

        # Make sure the URL seems like an image
        if image_url and image_url.slice(-3) in ['jpg', 'jpeg', 'png', 'gif']

            n_reqs++

            request image_url, (err, response, image_body) ->

                if err
                    console.log "[ERROR loading]" #{ err }"
                    n_reqs_failed++
                    response = null # Clear!
                    image_body = null # Clear!
                    res.end ''

                else
                    sharp(image_body)
                    .resize(crop_width, crop_height)
                    .crop(sharp.gravity[crop_gravity])
                    .toBuffer (err, buffer) ->
                        response = null # Clear!
                        image_body = null # Clear!
                        if err
                            console.log "[ERROR resizing]" # #{ err }"
                            n_reqs_failed++
                            res.end ''
                        else
                            res.end buffer

        # Blank response for bad requests
        else
            res.end ''

server.listen config.PORT, -> console.log "Listening on #{ config.PORT }"
