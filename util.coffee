fs = require 'fs'
{spawn} = require 'child_process'
_ = require 'underscore'
async = require 'async'


filter = (arr, pattern) ->
  f = if pattern instanceof RegExp
    (x) -> x.match pattern
  else
    pattern
  _.filter arr, f


classes_with_main = (files) ->
  classes = []
  for own k, java of files
    m_main      = java.match /public static void main\(String/
    m_package   = java.match /package ([^ ;\r\n]+);/
    m_classname = java.match /public class ([^ ]+)/
    if m_main and m_package and m_classname
      classes.push "#{m_package[1]}.#{m_classname[1]}"
  classes


load_java_files = (dir, c) ->
  files = {}
  _load_file = (path, c) ->
    fs.readFile path, (e, data) ->
      return c e if e
      files[path.substr(dir.length + 1)] = data.toString 'utf-8'
      c null
  paths_in dir, (e, paths) ->
    return c e if e
    paths = filter paths, /\.java$/
    async.forEach paths, _load_file, (e) ->
      return c e if e
      c null, files


split_args = (args) ->
  [java_args, our_args, java_file, child_args] = [[], [], null, []]
  for arg in args
    if java_file
      child_args.push arg
    else if arg.match /\.java$/
      java_file = arg
    else
      # pre-(java_file)
      if arg.match /^-/
        java_args.push arg
      else
        our_args.push arg
  if not java_file
    child_args = our_args
    our_args = []
  {java_args, our_args, java_file, child_args}


parse_our_args = (args) ->
  info = {}
  for arg in args
    m = arg.match /^--(.+)=(.*)/
    if m
      info[m[1]] = m[2]
  info


spawn_exec_write_on_err = (command, args, opt, callback) ->
  spawn_exec command, args, opt, (e, out, err) ->
    if e
      process.stderr.write '*****************\n'
      process.stderr.write out + '\n'
      process.stderr.write err + '\n'
    callback e, out, err


spawn_exec = (command, args, opt, callback) ->
  out = []
  err = []
  p = spawn command, args, opt
  p.stdout.on 'data', (data) -> out.push data.toString 'utf-8'
  p.stderr.on 'data', (data) -> err.push data.toString 'utf-8'
  p.on 'exit', (code) ->
    e = (if code == 0 then null else code)
    callback e, out.join(''), err.join('')


paths_in = (dir, callback) ->
  paths = []
  _paths_in dir, paths, (e) ->
    return callback e if e
    callback null, paths


_paths_in = (path, paths, callback) ->
  fs.readdir path, (e, filenames) ->
    
    # path is a file
    if e and e?.code == 'ENOTDIR'
      paths.push path
      return callback null
    
    # error
    return callback e if e
    
    # path is a dir
    async.forEach(
      filenames,
      ((filename, cb) -> _paths_in "#{path}/#{filename}", paths, cb),
      callback)


module.exports = {
  split_args, parse_our_args, paths_in, filter,
  load_java_files, spawn_exec, spawn_exec_write_on_err,
  classes_with_main
}
