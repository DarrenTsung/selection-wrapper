WrapperSnippetsManager = require './wrapper-snippets-manager.coffee'
{CompositeDisposable} = require 'atom'

module.exports = 
  subscriptions: null
  wrapperSnippetsManager: null

  activate: (state) ->
    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable
    @wrapperSnippetsManager = new WrapperSnippetsManager

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 
      'selection-wrapper:display-wrapper-snippets-for-selection': => @createWrapperSnippetsView(@wrapperSnippetsManager).showWrapperSnippets()

  deactivate: ->
    @subscriptions.dispose()
    if @wrapperSnippetsView?
      @wrapperSnippetsView.destroy()
      @wrapperSnippetsView = null
    
  createWrapperSnippetsView: (wrapperSnippetsManager) ->
    unless @wrapperSnippetsView?
      WrapperSnippetsView = require './wrapper-snippets-view.coffee'
      @wrapperSnippetsView = new WrapperSnippetsView(wrapperSnippetsManager)
    @wrapperSnippetsView

