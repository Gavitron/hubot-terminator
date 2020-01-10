# Description:
#   Am implementation of a glossary capability for your hubot.
#    really just a heavily modified version of hubot-factoid by therealklanni
#   Supports history (in case you need to revert a change), as
#   well as popularity, aliases, searches, and multiline!
#
# Dependencies:
#   None
#
# Commands:
#   hubot learn <term> = <definition> - learn a new term
#   hubot alias <term> = <term>
#   hubot wtf is <term> - lookup the definition of <term>

#   hubot forget <term> - forget a definition
#   hubot remember <term> - remember a definition that was forgotten previously
#   hubot drop <term> - permanently forget a definition

#   hubot list all definitions - list all definitions
#   hubot search <substring> - list any definitions which match (by key or result)
#
# Authors:
#   gavitron (2019)
#   therealklanni (2013-2017)

Definitions = require './definitions'

module.exports = (robot) ->
  @definitions = new Definitions robot
  robot.router.get "/#{robot.name}/definitions", (req, res) =>
    res.end JSON.stringify @definitions.data, null, 2

  robot.hear new RegExp("^wtf is ([\\w\\s-]{2,}\\w)( @.+)?", 'i'), (msg) =>
    definition = @definitions.get msg.match[1]
    to = msg.match[2]
    if not definition? or definition.forgotten
      msg.reply "Term not defined"
    else
      definition.popularity++
      to ?= msg.message.user.name
      msg.send "#{to.trim()}: *#{msg.match[1]}*\n> #{definition.value.replace(/\n/g,"\n> ")}"

  robot.respond new RegExp("wtf is ([\\w\\s-]{2,}\\w)", 'i'), (msg) =>
    definition = @definitions.get msg.match[1]
    if not definition? or definition.forgotten
      msg.reply "Term not defined"
    else
      definition.popularity++
      msg.send "*#{msg.match[1]}*\n> #{definition.value.replace(/\n/g,"\n> ")}"

  robot.respond /learn (.{3,}) = ([^@].+)/i, (msg) =>
    user = msg.envelope.user
    [key, value] = [msg.match[1], msg.match[2]]
    definition = @definitions.set key, value, msg.message.user.name

    if definition.value?
      msg.reply "OK, I know what #{key} means"

  robot.respond /forget (.{3,})/i, (msg) =>
    user = msg.envelope.user
    if @definitions.forget msg.match[1]
      msg.reply "OK, forgot #{msg.match[1]}"
    else
      msg.reply 'Term not defined'

  robot.respond /remember (.{3,})/i, (msg) =>
    definition = @definitions.remember msg.match[1]
    if definition? and not definition.forgotten
      msg.reply "OK, #{msg.match[1]} is #{definition.value}"
    else
      msg.reply 'Term not defined'

  robot.respond /list all definitions/i, (msg) =>
    all = @definitions.getAll()
    out = ''

    if not all? or Object.keys(all).length is 0
      msg.reply "Nothing defined"
    else
      for f of all
        out += f + ': ' + all[f] + "\n"
      msg.reply "All definitions: \n" + out

  robot.respond /search (.{3,})/i, (msg) =>
    definitions = @definitions.search msg.match[1]

    if definitions.length > 0
      found = definitions.join("*, *") 
      msg.reply "Matched the following definitions: *#{found}*"
    else
      msg.reply 'No definitions matched'

  robot.respond /alias (.{3,}) = (.{3,})/i, (msg) =>
    user = msg.envelope.user
    who = msg.message.user.name
    alias = msg.match[1]
    target = msg.match[2]
    msg.reply "OK, aliased #{alias} to #{target}" if @definitions.set msg.match[1], "@#{msg.match[2]}", msg.message.user.name, false

  robot.respond /drop (.{3,})/i, (msg) =>
    user = msg.envelope.user
    definition = msg.match[1]
    if @definitions.drop definition
      msg.reply "OK, #{definition} has been dropped"
    else msg.reply "Term not defined"

  robot.respond /save terms/i, (msg) =>
    Path = require 'path'
    fs = require('fs');
    path = Path.resolve('data')
    filename = Path.join path, 'terminator_gestalt.json'
    robot.logger.info("saving to file #{filename}")

    def_json = @definitions.save()
    fs.writeFile filename, def_json, (error) ->
      console.log("Error writing file", error) if error
    console.log def_json  
    if def_json
      msg.reply "OK, definitions are saved"
    else msg.reply "ERROR: Save failed"

  robot.respond /load terms/i, (msg) =>
    Path = require 'path'
    fs = require('fs');
    path = Path.resolve('data')
    filename = Path.join path, 'terminator_gestalt.json'
    robot.logger.info("loading from file #{filename}")

    def_json = fs.readFileSync filename, (error) ->
      robot.logging.error("Error reading file", error) if error;

    if @definitions.load(def_json)
      msg.reply "OK, definitions have been loaded"
    else msg.reply "ERROR: Load failed"
