exec = require "child_process"
config = require "../config.coffee"

data =
  statics: [],
  methods: []

execute = (command, async) ->
  return [] if data.error?

  for directory in atom.project.getDirectories()
    if not async
      try
        stdout = exec.execSync(config.config.php + " " + __dirname + "/../../php/parser.php " + directory.path + " " + command)
        res = JSON.parse(stdout)
      catch err
        console.log err
        res =
          error: err

      if res.error?
        printError(res.error)

      return res
    else
      exec.exec(config.config.php + " " + __dirname + "/../../php/parser.php " + directory.path + " " + command, (error, stdout, stderr) ->
        try
          res = JSON.parse(stdout)
        catch err
          res =
            error:
              message: err

        if res.error?
          printError(res.error)

        return res
      )

printError = (error) ->
  data.error = true
  message = error.message

  if error.file? and error.line?
    message = message + ' [from file ' + error.file + ' - Line ' + error.line + ']'

  throw new Error(message)

module.exports =
  clearCache: () ->
    data =
      error: false,
      statics: [],
      methods: []

    #execute("--refresh", true)

  classes: () ->
    if not data.classes?
      res = execute("--classes", false)
      data.classes = res

    return data.classes

  functions: () ->
    if not data.functions?
      res = execute("--functions", false)
      data.functions = res

    return data.functions

  statics: (className) ->
    if not data.statics[className]?
      res = execute("--statics '" + className + "'")
      data.statics[className] = res

    return data.statics[className]

  methods: (className) ->
    if not data.methods[className]?
      res = execute("--methods '" + className + "'")
      data.methods[className] = res

    return data.methods[className]

  init: () ->
    atom.workspace.observeTextEditors (editor) =>
      editor.onDidSave =>
        @clearCache()

    atom.config.onDidChange 'atom-autocomplete-php.binPhp', () =>
      @clearCache()

    atom.config.onDidChange 'atom-autocomplete-php.binComposer', () =>
      @clearCache()

    atom.config.onDidChange 'atom-autocomplete-php.autoloadPaths', () =>
      @clearCache()
