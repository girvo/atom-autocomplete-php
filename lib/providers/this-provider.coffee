fuzzaldrin = require 'fuzzaldrin'
minimatch = require 'minimatch'
exec = require "child_process"

proxy = require "../services/php-proxy.coffee"
parser = require "../services/php-file-parser.coffee"
AbstractProvider = require "./abstract-provider"

module.exports =
# Autocomplete for methods in the current class
# (keyword $this->)
class ThisProvider extends AbstractProvider
  methods: []
  functionOnly: true

  ###*
   * Get suggestions from the provider (@see provider-api)
   * @return array
  ###
  fetchSuggestions: ({editor, bufferPosition, scopeDescriptor, prefix}) ->
    # "new" keyword or word starting with capital letter
    @regex = /((?:\$this->)[a-zA-Z_]*)/g

    prefix = @getPrefix(editor, bufferPosition)
    return unless prefix.length

    className = parser.getCurrentClass(editor, bufferPosition)
    @methods = proxy.methods(className)
    return unless @methods.names?

    suggestions = @findSuggestionsForPrefix(prefix.trim())
    return unless suggestions.length
    return suggestions

  ###*
   * Returns suggestions available matching the given prefix
   * @param {string} prefix Prefix to match
   * @return array
  ###
  findSuggestionsForPrefix: (prefix) ->
    method = prefix.substring("$this->".length, prefix.length)

    # Filter the words using fuzzaldrin
    words = fuzzaldrin.filter @methods.names, method
    console.log words
    # Builds suggestions for the words
    suggestions = []
    for word in words
      for element in @methods.values[word]
        # Methods
        if element.isMethod
          suggestions.push
            text: word,
            type: 'method',
            snippet: @getFunctionSnippet(word, element.args)

        # Constants and public properties
        else
          suggestions.push
            text: word,
            type: 'property'

    return suggestions
