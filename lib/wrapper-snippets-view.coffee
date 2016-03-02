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

    startCheckpoint = editor.createCheckpoint()

    wrapperSnippets = @wrapperSnippetsManager.getWrapperSnippetsForCurrentScope()
    snippet = wrapperSnippets[name]

    if !snippet?
      atom.notifications.addError("Failed to get snippet of name: #{name}", {dismissable: true})
      return

    selections = editor.getSelections()
    for selection in selections
      [startRow, endRow] = selection.getBufferRowRange()

      indentationLevels = (editor.indentationForBufferRow(rowNumber) for rowNumber in [startRow..endRow])

      # BUG in Math.min(indentationLevels) returning NaN? Not sure why.
      minIndentationLevel = Infinity
      for level in indentationLevels
        minIndentationLevel = Math.min(minIndentationLevel, level)

      selectionTextPattern = /\${selection, ([^}]*)}/im
      selectionTextPatternWithAnchoredSpaces = /^\s*\${selection, [^}]*}/im

      # parse config key value pairs for the selection
      [_, configText] = (snippet.body).match(selectionTextPattern)

      configMapping = {}
      if configText?
        configPairArray = (configPair.trim() for configPair in configText.split(','))
        for configPair in configPairArray
          [key, value] = (string.trim() for string in configPair.split(':')[0..1])
          configMapping[key] = value

      # rtrim
      selectedText = selection.getText().replace(/\s*$/gm, '')
      if configMapping['indent']
        selectedText = selectedText.replace(/^/gm, editor.getTabText().repeat(configMapping['indent']))

      snippetText = (snippet.body).replace(/^/gm, editor.getTabText().repeat(minIndentationLevel))
      textToInsert = (snippetText).replace(selectionTextPatternWithAnchoredSpaces, selectedText)
      textToInsert += "\n"

      selection.insertText(textToInsert, select: true);

      editor.scanInBufferRange /\${cursor}/, selection.getBufferRange(), ({range, stop}) ->
        editor.setCursorBufferPosition(range.start)
        atom.commands.dispatch(atom.views.getView(editor), "vim-mode:activate-insert-mode")
        atom.commands.dispatch(atom.views.getView(editor), "vim-mode-plus:activate-insert-mode")
        editor.setSelectedBufferRange(range)
        stop()

      editor.groupChangesSinceCheckpoint(startCheckpoint)

  confirmed: (obj) ->
    @insertWrapperSnippetByName(obj.simpleText)
    super(obj)

  #endregion

