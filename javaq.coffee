fs = require 'fs'
{spawn} = require 'child_process'
_ = require 'underscore'
mkdirp = require 'mkdirp'
{strftimeUTC} = require 'strftime'
{
    split_args, parse_our_args, paths_in, filter,
    load_java_files, spawn_exec, spawn_exec_write_on_err,
    classes_with_main
} = require './util'


DEFAULT_LIB = "#{process.env.HOME}/Library/jars"
DEFAULT_BUILDS_DIR = "#{process.env.HOME}/Library/Application Support/javaq/builds"


main = () ->
  
  fatal_error "process.env.HOME is required" if not (process.env.HOME and process.env.HOME.length > 0)
  
  # settings
  {our_args, java_file, child_args} = split_args process.argv.slice 2
  our_args_info = parse_our_args our_args
  lib = our_args_info['build-dir'] or DEFAULT_LIB
  builds_dir = our_args_info['build-dir'] or DEFAULT_BUILDS_DIR
  datecode = strftimeUTC "%Y-%m-%dT%H-%M-%S.%LZ"
  build_dir = "#{builds_dir}/v1/#{datecode}"
  
  # build
  find_lib_jars lib, (e, jar_paths) ->
    throw e if e
    load_java_files ".", (e, java_files) ->
      source_file_paths = _.keys java_files
      build {build_dir, jar_paths, source_file_paths}, (e) ->
        throw e if e
        
        # run
        classes = classes_with_main java_files
        fatal_error "No classes found with a main"        if classes.length < 0
        fatal_error "Multiple classes found with a main"  if classes.length > 1
        [main_fqn] = classes
        run {build_dir, jar_paths, main_fqn, child_args}


build = ({build_dir, jar_paths, source_file_paths}, c) ->
  classes_dir = "#{build_dir}/classes"
  mkdirp classes_dir, (e) ->
    return c e if e
    args = ['-d', classes_dir]
    if jar_paths.length > 0
      args.push '-classpath', jar_paths.join ':'
    args = _.flatten [args, source_file_paths]
    spawn_exec_write_on_err 'javac', args, {}, (e, out, err) ->
      return c e if e
      c null


run = ({build_dir, jar_paths, main_fqn, child_args}) ->
  classpath = _.flatten ["#{build_dir}/classes", jar_paths]
  args = _.flatten [
    '-classpath', classpath.join(':')
      main_fqn
    args
  ]
  p = spawn 'java', args, {stdio: 'inherit'}
  p.on 'exit', (code) ->
    process.exit code


find_lib_jars = (path, c) ->
  return c null, [] if not path
  fs.readdir path, (e, filenames) ->
    return c null, [] if e
    paths = ("#{path}/#{x}" for x in filter filenames, /^[^.].*\.jar$/)
    c null, paths


fatal_error = (msg) ->
  console.log msg
  process.exit 1


module.exports = {main}
