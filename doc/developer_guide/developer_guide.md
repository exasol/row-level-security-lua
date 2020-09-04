# Developer Guide

## Preparation

Before you can build and test the application, you need to install Lua packages on the build machine.

### Installing LuaRocks

First install the package manager LuaRocks.

```bash
apt install luarocks
```

Now update your `LUA_PATH`, so that it contains the packages (aka. "rocks"). You can auto-generate that path.

```bash
luarocks path
```

Of course generating it is not enough, you also need to make sure the export is actually executed &mdash; preferably automatically each time. Here is an example that appends the path to the `.bashrc`:

```bash
luarocks path >> ~/.bashrc
```

### Installing the Required Lua Packages

You need the packages for unit testing, mocking and JSON processing.

Execute as `root` or modify to install in your home directory:

```bash
sudo luarocks install LuaUnit
sudo luarocks install Mockagne
sudo luarocks install lua-cjson
sudo luarocks install remotelog
```

Most of those packages are only required for testing. While `cjson` is needed at runtime, it is prepackaged with Exasol, so no need to install it at runtime.

### Bundling the Main Script and the Modules

As most non-trivial pieces of software, `row-level-security-lua` is modularized. While it is possible to install individual modules as Lua scripts in Exasol, this is also a lot of work. And the more modules you install individually, the higher the chances you forget to update one of them. A safer and more convenient way is to bundle everything into one script before the installation using [lua-amalg](https://github.com/siffiejoe/lua-amalg/).

To make this process easier, the [Maven POM file](../../pom.xml) contains an execution that automates this step. Still it is necessary to add new modules by hand in the list of modules to be bundled in the POM.

Note that the entry point `request_dispatcher.lua` is a regular Lua script that must be added to the bundle using the `-s` switch and its relative path. The remaining bundle elements are Lua modules and must be listed in dot-notation.

## How to Run Lua Unit Tests

### Run Unit Tests From Terminal

To run unit tests from terminal, you first need to install lua:

```bash
sudo apt install lua5.1
```

Another important thing to do, you need to add the project's directories with lua files to LUA_PATH environment variable.
We add two absolute paths, one to the `main` and another to the `test` folder: 

```bash
export LUA_PATH='/home/<absolute>/<path>/row-level-security-lua/src/main/lua/?.lua;/home/<absolute>/<path>/row-level-security-lua/src/test/lua/?.lua;'"$LUA_PATH"
```

After that you can try to run any test file:

```bash
lua src/test/lua/exasolvs/test_query_renderer.lua 
```

### Run Unit Tests From Intellij IDEA

First, you need to install a plugin that handles lua code. We recommend to use `lua` plugin by `sylvanaar`.

In the next step we add a Lua interpreter. Fow that go to `File` -> `Project structure` -> `Modules`.
Here press `Add` button in the upper left corner and add a new lua framework.
You can use one of the default Lua interpreters suggested by Intellij or add your own in `SDKs` tab of the `Project structure`.
We recommend installing and using `lua5.1`.

Now we should add the LUA_PATH environment variable here too. Go to `Run` -> `Edit configurations` -> `Templates` -> `Lua Script`.
We assume that you have already run the tests via a terminal and you added an enviroment variable there. Now check it via a terminal command:

```bash
echo $LUA_PATH
```

Copy the output, in the `Enviroment variables` field press `Browse` -> `Add`.
Paste the lines you copied to the `Value` field and add `LUA_PATH` as a `Name`.
  
Now you can right-click any unit-test class and `Run...` or use hot keys `Ctrl+Shift+F10`.