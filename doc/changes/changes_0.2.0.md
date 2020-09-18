# row-level-security-lua, released 2020-09-18

Code name: Role- and group-security

## Summary

This release brings role-based and group-based row-level security.

One important difference compared to the Java version is that in the combination of role and tenant security the criteria are combined with a logical `OR` rather than an `AND`. From the use case perspective this makes more sense, but you have to keep that in mind when switching and migrate the settings if necessary.

## Features / Enhancements

* #6: Added role security
* #8: Added group security