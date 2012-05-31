nib = require 'nib'
stylus = require 'stylus'
sysPath = require 'path'
fs = require 'fs'

module.exports = class StylusCompiler
  brunchPlugin: yes
  type: 'stylesheet'
  extension: 'styl'
  generators:
    backbone:
      style: "@import 'nib'\n"
  _dependencyRegExp: /@import ['"](.*)['"]/g

  constructor: (@config) ->
    null

  compile: (data, path, callback) =>
    compiler = stylus(data)
      .set('compress', no)
      .set('firebug', !!@config.stylus?.firebug)
      .include(sysPath.join @config.paths.root)
      .include(sysPath.dirname path)
      .use(nib())
    @config.stylus?.paths?.forEach (path)-> compiler.include(path)
    compiler.render(callback)

  getDependencies: (data, path, callback) =>
    paths = data.match(@_dependencyRegExp) or []
    parent = sysPath.dirname path
    stylusPaths = @config.stylus?.paths || false
    dependencies = paths
      .map (path) =>
        res = @_dependencyRegExp.exec(path)
        @_dependencyRegExp.lastIndex = 0
        (res or [])[1]
      .filter((path) => !!path and path isnt 'nib')
      .map (path) =>
        if sysPath.extname(path) isnt ".#{@extension}"
          path + ".#{@extension}"
        else
          path
      .map (path) =>
        result = null
        if stylusPaths
          stylusPaths.forEach (includePath) ->
            resolvedPath = sysPath.resolve( includePath, path )
            try
              fs.openSync(resolvedPath, 'r')
            catch error
              return
            result = resolvedPath 
        if not result
          return sysPath.join.bind(null, parent)(path)
          
        return sysPath.relative @config.paths.root, result
    process.nextTick =>
      callback null, dependencies
