Ember.Rails ?= Ember.Namespace.create()

Ember.Rails.FlashMessage = Ember.Object.extend
  severity: null
  message: ''

Ember.Rails.MessageCache = Ember.Object.extend
  supportsLocalStorage: false

  init: ->
    @set('supportsLocalStorage', @_supportsLocalStorage())
    @clear() if @get('supportsLocalStorage')

  clear: ->
    return true unless @get('supportsLocalStorage')
    localStorage['flashMessages'] = []

  add: (message) ->
    return true unless @includes(message) && @get('supportsLocalStorage')
    localStorage['flashMessages'].push message

  includes: (message) ->
    return true unless @get('supportsLocalStorage')
    localStorage['flashMessages'].indexOf(message) is not -1

  _supportsLocalStorage: ->
    try
      window? and window['localStorage']?
    catch error
      false

Ember.Rails.FlashItemView = Ember.View.extend
  basicClassName: 'flash'
  template: Ember.Handlebars.compile """
  {{#with view.content}}
    <div {{bindAttr class="view.basicClassName severity"}}>{{message}}</div>
  {{/with}}
  """

Ember.Rails.FlashMessagesController = Ember.ArrayController.extend
  init: ->
    @_super()
    @set 'messageCache', Ember.Rails.MessageCache.create()
    jQuery(document).ajaxComplete (event, request, settings) => @extractFlashFromHeaders request

  extractFlashFromHeaders: (request) ->
    headers = request.getAllResponseHeaders()
    for header in headers.split(/\n/)
      m = header.match /^X-Flash-([^:]+)/
      if m? and not @get('messageCache').includes(m[1])
        @createMessage severity: m[1].underscore(), message: request.getResponseHeader("X-Flash-#{m[1]}")

  createMessage: (args) ->
    message = Ember.Rails.FlashMessage.create args
    @get('messageCache').add(message)
    @get('content').pushObject(message)

Ember.Rails.flashMessages = Ember.Rails.FlashMessagesController.create
  content: Ember.A()

Ember.Rails.FlashListView = Ember.CollectionView.extend
  tagName: 'div'
  itemViewClass: Ember.Rails.FlashItemView
  contentBinding: 'Ember.Rails.flashMessages'
