fs = require 'fs'
assert = require 'assert'
_ = require 'underscore'
async = require 'async'
{
    split_args, parse_our_args, paths_in, filter,
    load_java_files, spawn_exec, spawn_exec_write_on_err,
    classes_with_main
} = require '../util'

tests = []
test = (args...) -> tests.push args
pending = (name) -> process.stderr.write "PENDING: #{name}\n"


test 'paths_in', (c) ->
  async.forEachSeries([
        ["examples/hai", [
            "examples/hai/Hai.java"]]
        ["examples/nested", [
            "examples/nested/asdf/Bar.java"
            "examples/nested/asdf/Foo.java"
            "examples/nested/Nested.java"]]
      ],
      (([reldir, relpaths], c) ->
        expected_paths = _.map relpaths, (relpath) -> "#{__dirname}/#{relpath}"
        paths_in "#{__dirname}/#{reldir}", (e, paths) ->
          throw e if e
          paths.sort()
          expected_paths.sort()
          assert.deepEqual paths, expected_paths
          c null),
      c)

pending 'spawn_exec', (c) ->
  spawn_exec 'echo', ['foo'], {}, (e, out, err) ->
    assert.equal e, null
    assert.equal out, "foo\n"
    assert.equal err, ""
    c null


pending 'spawn_exec_write_on_err', (c) ->
  spawn_exec_write_on_err 'echo', ['foo'], {}, (e, out, err) ->
    assert.equal e, null
    assert.equal out, "foo\n"
    assert.equal err, ""
    c null


test 'load_java_files error', (c) ->
  load_java_files '404lakjbsdkjs', (e) ->
    assert.ok e
    c()


test 'load_java_files', (c) ->
  load_java_files "#{__dirname}/examples/hai", (e, files) ->
    assert.ok not e
    assert.deepEqual _.keys(files), ['Hai.java']
    c()


test 'classes_with_main', () ->
  files = {
    '...path1...': """
      package com.example.asdf;
      public class Foo {
        public static void main(String[] args) {
    """
    '...path2...': "asdf"
  }
  assert.deepEqual classes_with_main(files), ['com.example.asdf.Foo']


test 'filter', () ->
  for [arr, f, expected] in [
          [
            [0, 1, 2, 3],
            ((x) -> (x % 2) == 0)
            [0, 2]]
          [
            ['moof', 'clarus', 'dogcow', 'mooof']
            /mo+f/
            ['moof', 'mooof']]]
    assert.deepEqual filter(arr, f), expected


test 'split_args', () ->
  for [args, [e1, e2, e3, e4]] in [
        [['-Xmx1024m', 'X.java'], [['-Xmx1024m'], [], 'X.java', []]]
        [[],                      [[], [], null, []]]
        [['x', 'y'],              [[], [], null, ['x', 'y']]]
        [['Foo.java'],            [[], [], 'Foo.java', []]]
        [['x/y/Foo.java'],        [[], [], 'x/y/Foo.java', []]]
        [['Foo.java', 'x', 'y'],  [[], [], 'Foo.java', ['x', 'y']]]
        [
          ['a', 'b', 'Foo.java', 'x', 'y'],
          [[], ['a', 'b'], 'Foo.java', ['x', 'y']]]
        [
          ['a', 'b', 'Foo.java', 'Bar.java', 'y'],
          [[], ['a', 'b'], 'Foo.java', ['Bar.java', 'y']]]]
    {java_args, our_args, java_file, child_args} = split_args args
    assert.deepEqual java_args,   e1
    assert.deepEqual our_args,    e2
    assert.deepEqual java_file,   e3
    assert.deepEqual child_args,  e4


test 'parse_our_args', () ->
  assert.equal '123', parse_our_args(['--foo=123'])['foo']
  assert.equal 2, _.keys(parse_our_args(['--foo=1', '--bar=2'])).length


test 'cd hai; javaq', (c) ->
  test_javaq example:"hai", expected_out:"HAI\n", c


test 'cd nested; javaq', (c) ->
  test_javaq example:"nested", expected_out:"foo bar\n", c


test 'cd using-stdin; javaq', (c) ->
  test_javaq example:"using-stdin", expected_out:"HAI #{0x30}\n", stdin_text:"0", c


test_javaq = ({example, expected_out, stdin_text}, c) ->
  f = (e, out, err) ->
    if err != ""
      process.stderr.write err
    assert.equal err, ""
    assert.equal out, expected_out
    c null
  
  bin_path = fs.realpathSync "#{__dirname}/../bin/javaq"
  if stdin_text
    throw 'not implemented' if stdin_text.match /'/
    spawn_exec 'bash', ['-c', "echo '#{stdin_text}' | '#{bin_path}'"], {cwd:"#{__dirname}/examples/#{example}"}, f
  else
    spawn_exec bin_path, [], {cwd:"#{__dirname}/examples/#{example}"}, f


main = () ->
  t0 = new Date().getTime()
  async.forEachSeries(
    tests,
    (([name, f], cb) ->
      t1 = new Date().getTime()
      process.stderr.write ljust "testing: #{name}", 45
      async_call f, () ->
        ms = new Date().getTime() - t1
        process.stderr.write "[#{ms} ms]\n"
        cb null),
    ((e) ->
      ms = new Date().getTime() - t0
      process.stderr.write "\n"
      process.stderr.write "Total time: #{ms} ms\n"
      process.stderr.write "OK\n"))


ljust = (s, n, char=" ") ->
  while s.length < n
    s += char
  s


async_call = (f, c) ->
  if f.length == 0
    f()
    c null
  else
    f c


module.exports = {main}
if not module.parent
  main()
