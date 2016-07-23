Core = require 'sublime-core'
Stomp = require 'stompjs'
shoe = require 'shoe'

states =
  disconnected:
    connect: (inst) ->
      sock = shoe("#{inst.protocol}://#{inst.host}:#{inst.port}/stomp").sock
      inst.client = if inst.node and typeof window == 'undefined' then Stomp.overTCP(inst.host, inst.port)
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

# Provides a STOMP enabled RabbitMQ interface for publish and subscribe
class Queue extends Core.Stateful
  # Construct a new Queue
  #
  # @param [String] user The username
  # @param [String] password The password
  # @param [String] host The hostname
  # @param [Integer] port The port
  # @param [String] protocol The protocol to use ws/http
  # @param [String] vhost The vhost
  constructor: (user, password, host, port, protocol, vhost) ->
    super(states)

    @user = user
    @password = password
    @host = host
    @port = port
    @protocol = protocol or 'http'
    @vhost = vhost or '/'

    @channels = {}

  # Connect to the server
  connect: () ->
    @.apply 'connect', @

  # Disconnect from the server
  disconnect: () ->
    @.apply 'disconnect', @

  # Subscribe to a channel
  #
  # @param [String] channel The name of the channel
  # @param [Function] fn The function to handle inbound messages
  subscribe: (channel, fn) ->
    @.apply 'subscribe', @, channel, fn

  # Unsubscribe from a channel
  #
  # @param [String] channel The name of the channel
  # @param [Function] fn The specific handler to unsubscribe
  unsubscribe: (channel, fn) ->
    @.apply 'unsubscribe', @, channel, fn

  # Publish a message to a channel
  #
  # @param [String] channel The name of the channel
  # @param [Object] payload The message payload
  publish: (channel, payload) ->
    @.apply 'publish', @, channel, payload

module.exports = Queue
