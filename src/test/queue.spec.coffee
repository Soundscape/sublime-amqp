lib = require '../'
node = require 'detect-node'

describe 'Queue test suite', ()  ->
  create = () ->
    if node then new lib.Queue 'guest', 'guest', '192.168.1.100', 61613
    else new lib.Queue 'guest', 'guest', 'localhost', 15674

  it 'should construct an instance', () ->
    instance = create()
    expect instance
      .not.toBeNull()

  it 'should be able to connect and disconnect', (done) ->
    instance = create()
    expect instance
      .not.toBeNull()

    instance.on 'connected', () ->
      expect instance.state()
        .toBe 'connected'

      instance.disconnect()
      done()

    instance.connect()

  describe 'Queue functionality test suite', ()  ->

    instance = null
    subscription = () -> return

    beforeEach () ->
      instance = create()

    afterEach () ->
      instance = null

    it 'should be able to subscribe', (done) ->
      instance.on 'connected', () ->
        instance.subscribe 'test', subscription
        expect instance.channels.test
          .not.toBeNull()

        instance.disconnect()

      instance.on 'disconnected', () ->
        done()

      instance.connect()

    it 'should be able to unsubscribe', (done) ->
      instance.on 'connected', () ->
        instance.subscribe 'test', subscription
        expect instance.channels.test
          .not.toBeNull()

        instance.unsubscribe 'test', subscription
        expect instance.channels.test
          .toBeNull()

        instance.disconnect()

      instance.on 'disconnected', () ->
        done()

      instance.connect()

    it 'should be able to publish', (done) ->
      sb = (res) ->
        instance.unsubscribe 'test', sb
        expect instance.channels.test
          .toBeNull()

        instance.disconnect()

      instance.on 'connected', () ->
        instance.subscribe 'test', sb
        expect instance.channels.test
          .not.toBeNull()

        instance.publish 'test',
          hello: 'world'

      instance.on 'disconnected', () ->
        done()

      instance.connect()
