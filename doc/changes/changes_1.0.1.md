# Exasol Row Level Security (Lua) 1.0.1, released 2021-10-08

Code name: Unified error reporting

## Summary

As a preparation for contributing to Exasol's error catalog, all error messages in Lua RLS have been updated to use
[Uniform error reporting](https://github.com/exasol/error-reporting-lua).

Please note that this so far only covers errors raised in the RLS Virtual Schema adapter, the software that implement RLS. Administration scripts are not yet covered.

We also improved the test coverage in bad-weather scenarios (i.e. test that evaluate how the software handles error cases).

## Features

* #88: Added unified error reporting.

## Dependency Updates
