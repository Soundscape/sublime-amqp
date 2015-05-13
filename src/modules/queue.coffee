Core = require 'sublime-core'
Stomp = require 'stompjs'
shoe = require 'shoe'

states =
  disconnected:
    connect: (inst) ->
      sock = shoe("#{inst.protocol}://#{inst.host}:#{inst.port}/stomp").sock
      inst.client = if inst.node then Stomp.overTCP(inst.host, inst.port)
      else Stomp.over sock

      inst.client.connect inst.user, inst.password, () =>
        @setMachineState @connected
      , (error) ->
        console.log error
      , inst.vhost

      return
  connected:
    disconnect: (inst) ->
      inst.client.disconnect () =>
        inst.client = null
        @setMachineState @disconnected
      return

    subscribe: (inst, ch, fn) ->
      inst.channels[ch] = inst.channels[ch] or []

      sb =
        subscription: inst.client.subscribe ch, fn
        fn: fn

      inst.channels[ch].push sb

      return

    unsubscribe: (inst, ch, fn) ->
      if !inst.channels[ch] then return

      inst.channels[ch] = inst.channels[ch].filter (sb) ->
        if sb.fn == fn
          sb.subscription.unsubscribe()

        sb.fn != fn

      if inst.channels[ch].length == 0 then inst.channels[ch] = null

      return

    publish: (inst, ch, payload) ->
      if typeof payload == 'object' then payload = JSON.stringify payload
      inst.client.send ch, {}, payload

      return

class Queue extends Core.Stateful
  constructor: (user, password, host, port, protocol, vhost) ->
    super(states)

    @user = user
    @password = password
    @host = host
    @port = port
    @protocol = protocol or 'http'
    @vhost = vhost or '/'

    @channels = {}

  connect: () ->
    @.apply 'connect', @

  disconnect: () ->
    @.apply 'disconnect', @

  subscribe: (channel, fn) ->
    @.apply 'subscribe', @, channel, fn

  unsubscribe: (channel, fn) ->
    @.apply 'unsubscribe', @, channel, fn

  publish: (channel, payload) ->
    @.apply 'publish', @, channel, payload

module.exports = Queue
