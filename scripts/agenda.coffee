
crypto = require('crypto')

# Get KEY and SECRET from heroku env
API_KEY = process.env.INDICO_API_KEY
API_SECRET = process.env.INDICO_API_SECRET
CAT = '6734'
BASE_URL = 'https://indico.cern.ch'
REQUEST_URL = "/export/categ/#{CAT}.json?"

showAgenda = (robot, res, from, to) ->
    ts = Math.round(+new Date()/1000)

    # Build signed request
    request = REQUEST_URL
    request += 'apikey=' + encodeURIComponent(API_KEY) + '&'
    request += 'detail=contributions&'
    request += "from=#{from}&"
    request += 'occ=yes&'
    request += 'onlypublic=no&'
    request += "timestamp=#{ts}&"
    request += "to=#{to}"
    signature = crypto.createHmac('sha1', API_SECRET).update(request).digest('hex')
    request += "&signature=#{signature}"

    robot.http(BASE_URL + request)
        .get() (err, resp, body) ->
            if err
                res.send "Encountered and error!"
                return
            output = JSON.parse body
            evts = output["results"]

            if to == from
                if evts.length == 0
                    res.send "There is nothing happening #{from}!"
                    return
                output = "This is the LHCb agenda for #{from}:\n"
            else
                if evts.length == 0
                    res.send "There is nothing happening from #{from} to #{to}!"
                    return
                output = "This is the LHCb agenda from #{from} to #{to}:\n"

            evts = evts.sort (a_, b_) ->
                a = a_["startDate"]["time"]
                b = b_["startDate"]["time"]
                if a < b
                    -1
                else if a > b
                    1
                else
                    0

            for evt, i in evts
                title = evt["title"]
                # Get rid of *, or they will interfere with markup
                title = title.replace(/\*/g, " ⃰ ")
                beginning = evt["startDate"]["time"][..-4]
                end = evt["endDate"]["time"][..-4]
                if evt["room"]
                    room_string = "in #{evt["room"]}"
                else
                    room_string = ""
                output += "[#{beginning} - #{end}] *#{title}* #{room_string}\n"

            res.reply output

module.exports = (robot) ->
    robot.respond /what's on ((?!from).*)/i, (res) ->
        showAgenda(robot, res, res.match[1], res.match[1])
        return

    robot.respond /what's on from (.*) to (.*)/i, (res) ->
        showAgenda(robot, res, res.match[1], res.match[2])
        return

