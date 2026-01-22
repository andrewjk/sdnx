# Structured Data Notation

A format for specifying and validating data.

Useful for
- config files
- data transfer

Aiming to be
- human readable
- flexible

With inspiration from
- JSONC etc

## The data

Can be stored in `.sdn` files or strings.

For example:

```
@schema(./employee.sdnx)
{
	active: true,
	name: "Darren",
	age: 25,
	rating: 4.2,
	# strings can be multiline
	skills: "
		very good at
		  - reading
		  - writing
		  - selling",
	started_at: 2025-01-01,
	meeting_at: 2026-01-01T10:00,
	children: [{
		name: "Rocket",
		age: 5,
	}],
	# commenting out a field comments out the whole thing
	# commented_object: {
		whatever: 5,
	},
	has_license: true,
	license_num: "112",
}
```

## The schema

Can be stored in `.sdnx` files or strings, or pulled from a url.

For example:

```
{
	active: bool,
	# a comment
	name: string minlen(2),
	age: int min(16),
	rating: num max(5),
	## a description of this field
	skills: string,
	started_at: date,
	meeting_at: null | date,
	children: [{
		age: int,
		name: string,
	}],
	@mix({
		has_license: true,
		license_num: string minlen(1),
	} | {
		has_license: false,
	}),
}
```

## The specification

See the `SPEC.md` file for a detailed specification.
