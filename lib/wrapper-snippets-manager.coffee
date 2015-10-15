{Emitter} = require 'atom'
CSON = require 'season'
fs = require 'fs'
path = require 'path'
_ = require 'underscore-plus'
WrapperSnippet = require './wrapper-snippet.coffee'

module.exports =
class WrapperSnippetsManager 
  filepath: null

  constructor: (@searchKey, @searchValue) ->
    @emitter = new Emitter

    fs.exists @file(), (exists) =>
      unless exists
        @writeFile({})
      else
        @subscribeToWrapperFile()
        
    @loadAllWrapperSnippets()
        
  getWrapperSnippetsForCurrentScope: ->
    editor = atom.workspace.getActiveTextEditor()
    wrapperSnippets = atom.config.get('wrapper-snippets', scope: editor.getLastCursor().getScopeDescriptor()) ? {}
    wrapperSnippets = {} if Array.isArray(wrapperSnippets) or typeof wrapperSnippets isnt 'object'
    wrapperSnippets  
        
  loadAllWrapperSnippets: =>
    @readFile (results) ->
      found = false
      wrapperSnippets = {}

      for selector, snippets of results
        snippetsByName = {}
        for name, attributes of snippets
          {body} = attributes
          
          snippet = new WrapperSnippet({name, body})
          snippetsByName[snippet.name] = snippet;

        atom.config.set('wrapper-snippets', snippetsByName, scopeSelector: selector)

  onUpdate: (callback) ->
    @emitter.on 'wrapper-snippets-updated', () =>
      @find callback

  subscribeToWrapperFile: =>
    @fileWatcher.close() if @fileWatcher?

    try
      @fileWatcher = fs.watch @file(), (event, filename) =>
        @emitter.emit 'wrapper-snippets-updated'
    catch error
      watchErrorUrl = 'https://github.com/atom/atom/blob/master/docs/build-instructions/linux.md#typeerror-unable-to-watch-path'
      atom.notifications?.addError """
        <b>Wrapper Snippets Manager</b><br>
        Could not watch for changes to `#{path.basename(@file())}`.
        Make sure you have permissions to `#{@file()}`. On linux there
        can be problems with watch sizes. See <a href='#{watchErrorUrl}'>
        this document</a> for more info.""",
        dismissable: true

  updateFile: ->
    fs.exists @file(true), (exists) =>
      unless exists
        fs.writeFile @file(), '{}', (error) ->
          if error
            atom.notifications?.addError "Wrapper Snippets", options =
              details: "Could not create the file for storing wrapper snippets"

  file: (update=false) ->
    @filepath = null if update

    unless @filepath?
      filename = 'wrapper-snippets.cson'
      filedir = atom.getConfigDirPath()
      @filepath = "#{filedir}/#{filename}"
      
    @filepath

  readFile: (callback) ->
    fs.exists @file(), (exists) =>
      if exists
        try
          wrapperSnippets = CSON.readFileSync(@file()) || {}
          callback?(wrapperSnippets)
        catch error
          atom.notifications.addError("Failed to load #{path.basename(this.file())}", {dismissable: true})
      else
        fs.writeFile @file(), '{}', (error) ->
          callback?({})

  writeFile: (wrapperSnippets, callback) ->
    CSON.writeFileSync @file(), wrapperSnippets 
    callback?()
