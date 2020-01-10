chai = require 'chai'
sinon = require 'sinon'
chai.use require 'sinon-chai'
chaiFiles = require 'chai-files'
chai.use chaiFiles

expect = chai.expect
file = chaiFiles.file

Robot       = require 'hubot/src/robot'
TextMessage = require('hubot/src/message').TextMessage

describe 'definitions', ->
  robot = {}
  user = {}
  adapter = {}
  spies = {}

  beforeEach (done) ->
    # Create new robot, with http, using mock adapter
    robot = new Robot null, 'mock-adapter', true

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
      expect(spies.hear).to.have.been.calledWith(/^wtf is ([\w\s-]{2,}\w)( @.+)?/i)

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
        expect(strings[0]).to.match /OK, I know what foo means/
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
        expect(strings[0]).to.match /\*foo\*\n> bar/
        done()

      adapter.receive(new TextMessage user, 'wtf is foo')

    it 'responds to wtf is term @mention', (done) ->
      adapter.on 'send', (envelope, strings) ->
        expect(strings[0]).to.match /@user2: \*foo\*\n> bar/
        done()

      adapter.receive(new TextMessage user, 'wtf is foo @user2')

    it 'responds to forget', (done) ->
      adapter.on 'reply', (envelope, strings) ->
        expect(strings[0]).to.match /OK, forgot foo/
        done()

      adapter.receive(new TextMessage user, 'hubot: forget foo')

    it 'responds to search', (done) ->
      adapter.on 'reply', (envelope, strings) ->
        expect(strings[0]).to.match /.* the following definitions: .*foo/
        expect(strings[0]).to.match /.* the following definitions: .*foobar/
        expect(strings[0]).to.match /.* the following definitions: .*barbaz/
        expect(strings[0]).to.match /.* the following definitions: .*qix/
        expect(strings[0]).not.to.match /.* the following definitions: .*qux/
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
      expect(strings[0]).to.match /Nothing defined/
      done()

    adapter.receive(new TextMessage user, 'hubot: list all definitions')

  it 'responds to invalid definition', (done) ->
    adapter.on 'reply', (envelope, strings) ->
      expect(strings[0]).to.match /Term not defined/
      done()

    adapter.receive(new TextMessage user, 'wtf is foo')

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

describe 'definition persistence', ->
  robot = {}
  user = {}
  adapter = {}
  spies = {}

  beforeEach (done) ->
    # Create new robot, with http, using mock adapter
    robot = new Robot null, 'mock-adapter', true

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
    it 'registered respond load', ->
      expect(spies.respond).to.have.been.calledWith(/load terms/i)

    it 'registered respond save', ->
      expect(spies.respond).to.have.been.calledWith(/save terms/i)

  describe 'serializers', ->

#    it 'saves definitions to file', (done) ->
#
#      adapter.on 'reply', (envelope, strings) ->
#        expect(strings[0]).to.match /OK, definitions are saved/
#        expect(file('data/terminator_gestalt.json')).to.exist
#        expect(file('data/terminator_gestalt.json')).to.contain('sampledata');
#        #expect(file('data/terminator_gestalt.json')).to.equal(file('data/terminator_gestalt_test.json'));
#        done()
#
#      robot.brain.data.definitions.sampledata = value: "sample values", popularity: 42, forgotten: false
#      adapter.receive(new TextMessage user, 'hubot: save terms')

    it 'loads definitions from file', (done) ->
      adapter.on 'reply', (envelope, strings) ->
        expect(strings[0]).to.match /OK, definitions have been loaded/
        expect(robot.brain.data.definitions).to.include.keys('sampledata');
        expect(file('data/terminator_gestalt.json')).to.exist
        expect(file('data/terminator_gestalt.json')).to.contain('sampledata');
        done()

      adapter.receive(new TextMessage user, 'hubot: load terms')

