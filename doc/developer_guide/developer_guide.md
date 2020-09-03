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
```

Most of those packages are only required for testing. While `cjson` is needed at runtime, it is prepackaged with Exasol, so no need to install it at runtime.

### Bundling the Main Script and the Modules

As most non-trivial pieces of software, `row-level-security-lua` is modularized. While it is possible to install individual modules as Lua scripts in Exasol, this is also a lot of work. And the more modules you install individually, the higher the chances you forget to update one of them. A safer and more convenient way is to bundle everything into one script before the installation using [lua-amalg](https://github.com/siffiejoe/lua-amalg/).

To make this process easier, the [Maven POM file](../../pom.xml) contains an execution that automates this step. Still it is necessary to add new modules by hand in the list of modules to be bundled in the POM.

Note that the entry point `request_dispatcher.lua` is a regular Lua script that must be added to the bundle using the `-s` switch and its relative path. The remaining bundle elements are Lua modules and must be listed in dot-notation.
