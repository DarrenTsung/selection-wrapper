path = require 'path'
{File} = require 'atom'
WrapperSnippetsManager = require './wrapper-snippets-manager.coffee'
SelectListViewHelper = require './select-list-view-helper.coffee'

module.exports =
class WrapperSnippetsView extends SelectListViewHelper
  constructor: (@wrapperSnippetsManager) ->
    super()
    
  #region mark - LOGIC
  
  showWrapperSnippets: ->
    editor = atom.workspace.getActiveTextEditor()
    selectedBufferRange = editor.getSelectedBufferRange()
    if selectedBufferRange.isEmpty()
      # do nothing if nothing is selected
      return
    
    wrapperSnippets = @wrapperSnippetsManager.getWrapperSnippetsForCurrentScope()
    
    items = []
    for name, wrapperSnippet of wrapperSnippets
      items.push({
        simpleText: wrapperSnippet.name
        detailText: wrapperSnippet.body
      })
      
    @setItems(items)
    @show()
    
  insertWrapperSnippetByName: (name) ->
    editor = atom.workspace.getActiveTextEditor()
    wrapperSnippets = @wrapperSnippetsManager.getWrapperSnippetsForCurrentScope()
    snippet = wrapperSnippets[name]
    
    if !snippet?
      atom.notifications.addError("Failed to get snippet of name: #{name}", {dismissable: true})
      return
      
    selections = editor.getSelections()
    for selection in selections
      [startRow, endRow] = selection.getBufferRowRange()
      indentationLevel = editor.indentationForBufferRow(startRow)
      tabText = editor.getTabText()
      indentationReplacePattern = ///
        ^                                       # anchor to beginning of text
        #{tabText}{#{indentationLevel}}         # tab text exactly indentationLevel times
        \s?                                     # a single space character if it exists (???)
        ///gm
        
      selectedText = selection.getText().trimRight().replace(indentationReplacePattern, tabText)
      textToInsert = (snippet.body).replace(/\${selection}/, selectedText)
      
      selection.insertText(textToInsert + "\n", autoIndent: true, select: true);
      atom.commands.dispatch(atom.views.getView(editor), "vim-mode:activate-insert-mode")
      
      editor.scanInBufferRange /\${cursor}/, selection.getBufferRange(), ({range, stop, replace}) -> 
        editor.setCursorBufferPosition(range.start)
        replace("")
        stop()
    
  confirmed: (obj) ->
    @insertWrapperSnippetByName(obj.simpleText)
    super(obj)
    
  #endregion
  
