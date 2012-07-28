
You know how simple it is to run

    ... | python  foo.py          arg, arg | ...
    ... | ruby    foo.rb          arg, arg | ...
    ... | node    foo.js          arg, arg | ...
    ... | coffee  foo.coffee      arg, arg | ...

You've wished you could run

    ... | j       Foo.java        arg, arg | ...

Now you can.

- Get [NodeJS](http://nodejs.org) >= 0.8.0
- `npm install -g javaq`
- Add `alias j='javaq'` to your profile


## What if I'm lazy and don't want to specify which `.java` to run?

Then don't. If exactly one of the `.java` files in `ls -lR .` contains a `main`, `javaq` will run that one.


## Is it as slow as `javac ... && java ...`?

Currently, yes.

Soon, `.class`s will be cached.

I want to eventually shave off every possible millisecond.


## Which `.java` files get compiled?

Everything in `ls -lR .`. Later, this will be limited to those needed to run the main class.


## Settings

These must be specified before the first argument that matches `/\.java$/`. Otherwise they will be passed on to the program you're running.

### `--builds-dir=...`

Optional. Defaults to <code>~/Library/Application Support/javaq/builds</code>. <code>javaq</code> will use this folder as it sees fit.

### `--lib=...`

Optional. A folder containing JARs. Defaults to <code>~/Library/jars</code> if that exists. Those JARs will be on the <code>-classpath</code> when running `javac` and `java`.
