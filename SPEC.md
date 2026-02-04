# Structured Data Notation

This file contains the spec for Structured Data Notation. It is used in the test suite for each implementation to ensure that they conform.

Each code block in this file contains a schema, some data, and the optional expected result (whether an object or errors), separated with `.`.

## Introduction

Data is structured within objects (sets of fields) or arrays (collections of data).

Objects are delimited with `{` and `}` and arrays are delimited with `[` and `]`.

Objects consist of sets of fields:

```
{
    field: "data"
}
```

Arrays consist of collections of data:

```
[
    "apple", "banana", "orange"
]
```

Both object fields and arrays can contain data, objects or arrays.

There must be exactly one root object.

Field names must start with an alphabetic character or an underscore, and can contain alphabetic characters, underscores and numbers.

## The data

### Booleans

Boolean fields can be `true` or `false`.

```````````````````````````````` example
{ is_active: bool }
.
{ is_active: true }
````````````````````````````````

Any other type of value causes an error:

```````````````````````````````` example
{ is_active: bool }
.
{ is_active: 0 }
.
Error: 'is_active' must be a boolean value
````````````````````````````````

```````````````````````````````` example
{ is_active: bool }
.
{ is_active: Y }
.
Error: Unsupported value type 'Y'
````````````````````````````````

### Integers

Integer fields can only contain whole numbers.

```````````````````````````````` example
{ age: int }
.
{ age: 55 }
````````````````````````````````

Any other type of value causes an error:

```````````````````````````````` example
{ age: int }
.
{ age: "middle" }
.
Error: 'age' must be an integer value
````````````````````````````````

```````````````````````````````` example
{ age: int }
.
{ age: 25.3 }
.
Error: 'age' must be an integer value
````````````````````````````````

Integers can be positive:

```````````````````````````````` example
{ count: int }
.
{ count: +42 }
````````````````````````````````

Integers can be negative:

```````````````````````````````` example
{ offset: int }
.
{ offset: -10 }
````````````````````````````````

Integers can be hexadecimal:

```````````````````````````````` example
{ color: int }
.
{ color: 0xFF00FF }
````````````````````````````````

Integers can use underscores as separators for readability:

```````````````````````````````` example
{ population: int }
.
{ population: 1_000_000 }
````````````````````````````````

### Numbers

Number fields can contain floating point values (as well as integers).

```````````````````````````````` example
{ rating: num }
.
{ rating: 4.5 }
````````````````````````````````

```````````````````````````````` example
{ score: num }
.
{ score: 100 }
````````````````````````````````

Any other type of value causes an error:

```````````````````````````````` example
{ rating: num }
.
{ rating: "excellent" }
.
Error: 'rating' must be a number value
````````````````````````````````

Numbers support scientific notation:

```````````````````````````````` example
{ distance: num }
.
{ distance: 1.5e10 }
````````````````````````````````

Numbers can be positive and negative:

```````````````````````````````` example
{ balance: num, equity: num }
.
{ balance: -1250.75, equity: +5000.50 }
````````````````````````````````

Numbers can use underscores as separators for readability:

```````````````````````````````` example
{ big_number: num }
.
{ big_number: 1_000_000.123 }
````````````````````````````````

### Dates

Date fields can contain dates, times, or datetimes.

Dates are in `YYYY-MM-DD` format:

```````````````````````````````` example
{ birthday: date }
.
{ birthday: 2025-01-15 }
````````````````````````````````

Times are in `HH:MM` or `HH:MM:SS` format:

```````````````````````````````` example
{ meeting_time: date }
.
{ meeting_time: 14:30 }
````````````````````````````````

Times can include seconds:

```````````````````````````````` example
{ alarm_time: date }
.
{ alarm_time: 07:15:30 }
````````````````````````````````

Datetimes combine date and time with `T`:

```````````````````````````````` example
{ created_at: date }
.
{ created_at: 2025-01-15T14:30 }
````````````````````````````````

Times can have UTC offset (`U` for UTC, `L` for local):

```````````````````````````````` example
{ timestamp: date }
.
{ timestamp: 2025-01-15T14:30U }
````````````````````````````````

```````````````````````````````` example
{ local_time: date }
.
{ local_time: 2025-01-15T14:30L }
````````````````````````````````

Times can have specific timezone offsets:

```````````````````````````````` example
{ event_time: date }
.
{ event_time: 2025-01-15T14:30+02:00 }
````````````````````````````````

```````````````````````````````` example
{ event_time: date }
.
{ event_time: 2025-01-15T14:30-05:00 }
````````````````````````````````

### Strings

String fields are delimited with double quotes:

```````````````````````````````` example
{ name: string }
.
{ name: "Alice" }
````````````````````````````````

Strings can contain escaped double quotes:

```````````````````````````````` example
{ quote: string }
.
{ quote: "She said \"Hello\"" }
````````````````````````````````

Strings can be multiline:

```````````````````````````````` example
{ description: string }
.
{
    description: "This is a
multiline
string"
}
````````````````````````````````

If a multiline string starts with some spacing, that spacing will be removed from the start of all lines:

```````````````````````````````` example
{ description: string }
.
{
    description: "
        This is a
        multiline
        string"
}
.{
→description: "This is a
multiline
string"
}
````````````````````````````````

### Null

Null fields can contain the `null` value:

```````````````````````````````` example
{ middle_name: null | string }
.
{ middle_name: null }
````````````````````````````````

```````````````````````````````` example
{ middle_name: null | string }
.
{ middle_name: "Jane" }
````````````````````````````````

### Undef

Undef represents an undefined or missing value, useful for optional fields:

```````````````````````````````` example
{ middle_name: undef | string }
.
{ middle_name: "Jane" }
````````````````````````````````

```````````````````````````````` example
{ middle_name: undef | string }
.
{}
````````````````````````````````

### Arrays

Arrays are collections of values of a specified type. The type is specified with square brackets after the value type:

```````````````````````````````` example
{ tags: [string] }
.
{ tags: ["tag1", "tag2", "tag3"] }
````````````````````````````````

Arrays can contain numbers:

```````````````````````````````` example
{ scores: [int] }
.
{ scores: [85, 92, 78] }
````````````````````````````````

Arrays can be nested:

```````````````````````````````` example
{ matrix: [[int]] }
.
{ matrix: [[1, 2], [3, 4], [5, 6]] }
````````````````````````````````

Arrays can contain mixed types using unions:

```````````````````````````````` example
{ values: [int | string] }
.
{ values: [1, "two", 3, "four"] }
````````````````````````````````

Arrays can contain objects:

```````````````````````````````` example
{ people: [{ name: string, age: int }] }
.
{ people: [{ name: "Alice", age: 30 }, { name: "Bob", age: 25 }] }
````````````````````````````````

Empty arrays are allowed:

```````````````````````````````` example
{ tags: [string] }
.
{ tags: [] }
````````````````````````````````

Empty objects are allowed:

```````````````````````````````` example
{ metadata: {} }
.
{ metadata: {} }
````````````````````````````````

### Comments

Comments start with a `#` and extend to the end of the line:

```````````````````````````````` example
{ name: string }
.
# This is a comment
{ name: "Alice" }
````````````````````````````````

Comments can appear anywhere:

```````````````````````````````` example
{ name: string, age: int }
.
{
    name: "Bob", # inline comment
    age: 30
}
````````````````````````````````

Comments are ignored during parsing.

### Description comments

Description comments start with ## and provide a description of a field in a schema file. This can be shown when editing the file in an IDE:

```````````````````````````````` example
{
    ## The user's full name
    name: string
}
.
{ name: "Alice" }
````````````````````````````````

## The schema

A schema file specifies a schema that input data must match.

It supports setting types (`bool`, `int`, `num`, `date` and `string`) as well as simple validation.

```````````````````````````````` example
{
    active: bool,
    age: int min(18),
    score: num,
    dob: date,
    name: string,
}
.
{
    active: true,
    age: 16,
    score: 4.6,
    dob: 2010-01-01,
    name: "Miguel",
}
.
Error: 'age' must be at least 18
````````````````````````````````

### Bool validation

Require a specific value:

```````````````````````````````` example
{ accepted: true }
.
{ accepted: false }
.
Error: 'accepted' must be 'true'
````````````````````````````````

### Int validation

```````````````````````````````` example
{ age: int min(18) }
.
{ age: 15 }
.
Error: 'age' must be at least 18
````````````````````````````````

```````````````````````````````` example
{ age: int max(65) }
.
{ age: 70 }
.
Error: 'age' cannot be more than 65
````````````````````````````````

```````````````````````````````` example
{ age: int min(18) max(65) }
.
{ age: 15 }
.
Error: 'age' must be at least 18
````````````````````````````````

```````````````````````````````` example
{ age: int min(18) max(65) }
.
{ age: 70 }
.
Error: 'age' cannot be more than 65
````````````````````````````````

### Num validation

```````````````````````````````` example
{ rating: num min(0) }
.
{ rating: -0.5 }
.
Error: 'rating' must be at least 0
````````````````````````````````

```````````````````````````````` example
{ rating: num max(5) }
.
{ rating: 5.5 }
.
Error: 'rating' cannot be more than 5
````````````````````````````````

```````````````````````````````` example
{ rating: num min(0) max(5) }
.
{ rating: 4.5 }
````````````````````````````````

### String validation

```````````````````````````````` example
{ username: string minlen(3) }
.
{ username: "ab" }
.
Error: 'username' must be at least 3 characters
````````````````````````````````

```````````````````````````````` example
{ username: string maxlen(20) }
.
{ username: "this_username_is_way_too_long" }
.
Error: 'username' cannot be more than 20 characters
````````````````````````````````

```````````````````````````````` example
{ username: string minlen(3) maxlen(20) }
.
{ username: "john" }
````````````````````````````````

```````````````````````````````` example
{ email: string pattern(/^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$/i) }
.
{ email: "invalid-email" }
.
Error: 'email' doesn't match pattern '/^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$/i'
````````````````````````````````

```````````````````````````````` example
{ email: string pattern(/^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$/i) }
.
{ email: "user@example.com" }
````````````````````````````````

### Multiple types

Types can be unions if the field needs to accept multiple types. The types in a union are separated with a `|`:

```````````````````````````````` example
{ dob: int | date }
.
{ dob: 2000-01-01 }
````````````````````````````````

```````````````````````````````` example
{ dob: int | date }
.
{ dob: "last century" }
.
Error: 'dob' must be an integer value | 'dob' must be a date value
````````````````````````````````

### Nested objects

Objects can be nested within other objects:

```````````````````````````````` example
{
    name: string,
    address: {
        street: string,
        city: string,
        zip: int
    }
}
.
{
    name: "John Doe",
    address: {
        street: "123 Main St",
        city: "Springfield",
        zip: 12345
    }
}
````````````````````````````````

Arrays can be nested within objects:

```````````````````````````````` example
{
    name: string,
    tags: [string]
}
.
{
    name: "Alice",
    tags: ["developer", "engineer"]
}
````````````````````````````````

Objects can be nested within arrays:

```````````````````````````````` example
{
    items: [{
        name: string,
        price: num
    }]
}
.
{
    items: [
        { name: "Apple", price: 0.99 },
        { name: "Banana", price: 0.59 }
    ]
}
````````````````````````````````

## Macros

There are some helper macros available for advanced functionality. Macros start with an `@`.

### @spec

Use the `@spec` macro to link to a spec file, either as a local file, or from a URL.

### @mix

Use the `@mix` macro in a spec file to mix fields into your schema.

```````````````````````````````` example
{ dob: int | date }
.
{ dob: 2000-01-01 }
````````````````````````````````

You can use the `@mix` macro to build conditional checks:

```````````````````````````````` example
{
    @mix({
        minor: false
    } | {
        minor: true,
        guardian: string
    })
}
.
{ minor: false }
````````````````````````````````

```````````````````````````````` example
{
    @mix({
        minor: false
    } | {
        minor: true,
        guardian: string
    })
}
.
{ minor: true }
.
Error: 'minor' must be 'false' | Field not found: guardian
````````````````````````````````

Mix can have more than two alternatives:

```````````````````````````````` example
{
    @mix({
        type: "user",
        name: string
    } | {
        type: "admin",
        name: string,
        permissions: [string]
    } | {
        type: "system"
    })
}
.
{
    type: "admin",
    name: "Alice",
    permissions: ["read", "write"]
}
````````````````````````````````

### @props

Use the `@props` macro in a spec file to allow multiple fields with arbitrary names. Pass a regex to restrict the format of the names.

```````````````````````````````` example
{ @props(): string }
.
{ greeting: "hi!" }
````````````````````````````````

```````````````````````````````` example
{ @props(/v\d(_\d)*/): string }
.
{
    v1: "version 1",
    v1_1: "version 1.1",
}
````````````````````````````````

```````````````````````````````` example
{ @props(/^data_/): int }
.
{
    data_count: 42,
    data_total: 100
}
````````````````````````````````

```````````````````````````````` example
{ @props(/metadata_.*/): string }
.
{
    metadata_author: "John",
    metadata_version: "1.0",
    metadata_created: "2025-01-15"
}
````````````````````````````````

### Comprehensive example

A complex schema demonstrating multiple features together:

```````````````````````````````` example
{
    ## User information
    name: string minlen(2) maxlen(50),
    email: string pattern(/^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$/i),
    
    ## User can be minor or adult
    @mix({
        is_minor: false,
        age: int min(18)
    } | {
        is_minor: true,
        age: int,
        guardian: string
    }),
    
    ## Contact information (optional)
    phone: null | string,
    
    ## User tags
    tags: [string],
    
    ## User ratings
    ratings: [num min(0) max(5)],
    
    ## Account creation date
    created_at: date,
    
    ## Account settings
    settings: {
        notifications: bool,
        newsletter: bool
    }
}
.
{
    name: "Alice Johnson",
    email: "alice@example.com",
    is_minor: false,
    age: 28,
    phone: "+1-555-0123",
    tags: ["developer", "engineer"],
    ratings: [4.5, 5.0, 4.2],
    created_at: 2023-06-15T09:30U,
    settings: {
        notifications: true,
        newsletter: false
    }
}
````````````````````````````````
