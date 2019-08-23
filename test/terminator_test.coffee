chai = require 'chai'
sinon = require 'sinon'
chai.use require 'sinon-chai'

expect = chai.expect

Robot       = require 'hubot/src/robot'
TextMessage = require('hubot/src/message').TextMessage

describe 'definitions', ->
  robot = {}
  user = {}
  adapter = {}
  spies = {}

  beforeEach (done) ->
    # Create new robot, with http, using mock adapter
    robot = new Robot null, 'mock-adapter', false

    robot.adapter.on 'connected', =>
      spies.hear = sinon.spy(robot, 'hear')
      spies.respond = sinon.spy(robot, 'respond')

      require('../src/terminator-core')(robot)

      user = robot.brain.userForId '1', {
        name: 'user'
        room: '#test'
      }

      adapter = robot.adapter

    robot.run()

    done()

  afterEach ->
    robot.shutdown()

  describe 'listeners', ->
    it 'registered hear wtf is term', ->
      expect(spies.hear).to.have.been.calledWith(/^[!]([\w\s-]{2,}\w)( @.+)?/i)

    it 'registered respond learn', ->
      expect(spies.respond).to.have.been.calledWith(/learn (.{3,}) = ([^@].+)/i)

    it 'registered respond forget', ->
      expect(spies.respond).to.have.been.calledWith(/forget (.{3,})/i)

    it 'registered respond remember', ->
      expect(spies.respond).to.have.been.calledWith(/remember (.{3,})/i)

    it 'registered respond search', ->
      expect(spies.respond).to.have.been.calledWith(/search (.{3,})/i)

    it 'registered respond alias', ->
      expect(spies.respond).to.have.been.calledWith(/alias (.{3,}) = (.{3,})/i)

    it 'registered respond drop', ->
      expect(spies.respond).to.have.been.calledWith(/drop (.{3,})/i)

  describe 'new definitions', ->
    it 'responds to learn', (done) ->
      adapter.on 'reply', (envelope, strings) ->
        expect(strings[0]).to.match /OK, foo is now bar/
        done()

      adapter.receive(new TextMessage user, 'hubot: learn foo = bar')

  describe 'existing definitions', ->
    beforeEach ->
      robot.brain.data.definitions.foo = value: 'bar'
      robot.brain.data.definitions.foobar = value: 'baz'
      robot.brain.data.definitions.barbaz = value: 'foo'
      robot.brain.data.definitions.qix = value: 'bar'
      robot.brain.data.definitions.qux = value: 'baz'

    it 'responds to wtf is term', (done) ->
      adapter.on 'send', (envelope, strings) ->
        expect(strings[0]).to.match /user: bar/
        done()

      adapter.receive(new TextMessage user, '!foo')

    it 'responds to wtf is term @mention', (done) ->
      adapter.on 'send', (envelope, strings) ->
        expect(strings[0]).to.match /@user2: bar/
        done()

      adapter.receive(new TextMessage user, '!foo @user2')

    it 'responds to forget', (done) ->
      adapter.on 'reply', (envelope, strings) ->
        expect(strings[0]).to.match /OK, forgot foo/
        done()

      adapter.receive(new TextMessage user, 'hubot: forget foo')

    it 'responds to search', (done) ->
      adapter.on 'reply', (envelope, strings) ->
        expect(strings[0]).to.match /.* the following definitions: .*!foobar/
        expect(strings[0]).to.match /.* the following definitions: .*!barbaz/
        expect(strings[0]).to.match /.* the following definitions: .*!qix/
        expect(strings[0]).not.to.match /.* the following definitions: .*!qux/
        done()

      adapter.receive(new TextMessage user, 'hubot: search bar')

    it 'responds to alias', (done) ->
      adapter.on 'reply', (envelope, strings) ->
        expect(strings[0]).to.match /OK, aliased baz to foo/
        done()

      adapter.receive(new TextMessage user, 'hubot: alias baz = foo')

    it 'responds to drop', (done) ->
      adapter.on 'reply', (envelope, strings) ->
        expect(strings[0]).to.match /OK, foo has been dropped/
        done()

      adapter.receive(new TextMessage user, 'hubot: drop foo')

  describe 'forgotten definitions', ->
    beforeEach ->
      robot.brain.data.definitions.foo = value: 'bar', forgotten: true

    it 'responds to remember', (done) ->
      adapter.on 'reply', (envelope, strings) ->
        expect(strings[0]).to.match /OK, foo is bar/
        done()

      adapter.receive(new TextMessage user, 'hubot: remember foo')

  describe 'list all definitions', ->
    beforeEach ->
      robot.brain.data.definitions.foo = value: 'bar', forgotten: true
      robot.brain.data.definitions.bas = value: 'baz', forgotten: false

    it 'responds to list all definitions', (done) ->
      adapter.on 'reply', (envelope, strings) ->
        expect(strings[0]).to.match /All definitions: \nbas: baz\n/
        done()

      adapter.receive(new TextMessage user, 'hubot: list all definitions')

  it 'responds to list all definitions, empty list', (done) ->
    adapter.on 'reply', (envelope, strings) ->
      expect(strings[0]).to.match /No definitions defined/
      done()

    adapter.receive(new TextMessage user, 'hubot: list all definitions')

  it 'responds to invalid definition', (done) ->
    adapter.on 'reply', (envelope, strings) ->
      expect(strings[0]).to.match /Term not defined/
      done()

    adapter.receive(new TextMessage user, '!foo')

  it 'responds to invalid forget', (done) ->
    adapter.on 'reply', (envelope, strings) ->
      expect(strings[0]).to.match /Term not defined/
      done()

    adapter.receive(new TextMessage user, 'hubot: forget foo')

  it 'responds to invalid drop', (done) ->
    adapter.on 'reply', (envelope, strings) ->
      expect(strings[0]).to.match /Term not defined/
      done()

    adapter.receive(new TextMessage user, 'hubot: drop foo')

describe 'facts customization', ->
  robot = {}
  user = {}
  adapter = {}
  spies = {}

  beforeEach (done) ->
    # Create new robot, with http, using mock adapter
    robot = new Robot null, 'mock-adapter', false

    robot.adapter.on 'connected', =>
      spies.hear = sinon.spy(robot, 'hear')
      spies.respond = sinon.spy(robot, 'respond')

      require('../src/definitions')(robot)

      user = robot.brain.userForId '1', {
        name: 'user'
        room: '#test'
      }

      adapter = robot.adapter

    robot.run()

    done()

  afterEach ->
    robot.shutdown()