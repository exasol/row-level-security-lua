# Developer Guide

## Preparation

Before you can build and test the application, you need to install Lua packages on the build machine.

### Installing LuaRocks

```bash
apt install luarocks
```

### Installing the Required Lua Packages

```bash
luarocks install LuaUnit
sudo luarocks install Mockagne
luarocks install lua-cjson
```