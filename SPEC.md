# Structured Data Notation

This file contains the spec for Structured Data Notation. It is used in the test suite for each implementation to ensure that they conform.

Each code block contains a specification, some data, and the expected output (whether an object or some errors) separated with `---`.

## Booleans

Boolean fields can be `true` or `false`.

```
{ is_active: boolean }
---
{ is_active: true }
---
{ is_active: true }
```

Any other type of value causes an error:

```
{ is_active: boolean }
---
{ is_active: 0 }
---
ERROR: `is_active` must be a boolean value.
```

```
{ is_active: boolean }
---
{ is_active: yes }
---
ERROR: `is_active` must be a boolean value.
```
