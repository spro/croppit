http = require 'http'
os = require 'os'
url = require 'url'
util = require 'util'
sharp = require 'sharp'
request = require('request').defaults({ encoding: null })

DEFAULT_CROP_WIDTH = 640
DEFAULT_CROP_HEIGHT = 200

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
        crop_width = url_parts.query.w or DEFAULT_CROP_WIDTH
        crop_height = url_parts.query.h or DEFAULT_CROP_HEIGHT
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
                    sharp.resize image_body, sharp.buffer.jpeg, crop_width, crop_height, (err, buffer) ->
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
