import Testing
@testable import sdnx
import Foundation
import Collections

@Suite("Stringify tests") struct StringifyTests {
    @Test func basicObject() throws {
        let input: OrderedDictionary<String, Any> = [
            "name": "Alice",
            "age": 25,
            "active": true,
            "rating": 4.5,
            "balance": -100,
            "tags": ["developer", "writer"]
        ]

        let result = stringify(input)
        let expected = """
		{
			name: "Alice",
			age: 25,
			active: true,
			rating: 4.5,
			balance: -100,
			tags: [
				"developer",
				"writer"
			]
		}
		"""

        #expect(result == expected)

        let _ = try unwrapParseResult(parse(result))
    }

    @Test func emptyObject() throws {
        let input: OrderedDictionary<String, Any> = [:]
        let result = stringify(input)
        let expected = "{\n}"
        #expect(result == expected)

        let _ = try unwrapParseResult(parse(result))
    }

    @Test func emptyArray() throws {
        let input: OrderedDictionary<String, Any> = ["items": []]
        let result = stringify(input)
        let expected = """
		{
			items: [
			]
		}
		"""

        #expect(result == expected)

        let _ = try unwrapParseResult(parse(result))
    }

    @Test func nestedObjects() throws {
        // HACK: SWIFT
        let address: OrderedDictionary<String, Any> = [
            "city": "New York",
            "country": "USA"
        ]
        let user: OrderedDictionary<String, Any> = [
            "name": "Bob",
            "age": 30,
            "address": address
        ]
        let input: OrderedDictionary<String, Any> = [
            "user": user
        ]

        let result = stringify(input)
        let expected = """
		{
			user: {
				name: "Bob",
				age: 30,
				address: {
					city: "New York",
					country: "USA"
				}
			}
		}
		"""

        #expect(result == expected)

        let _ = try unwrapParseResult(parse(result))
    }

    @Test func nestedArrays() throws {
        let input: OrderedDictionary<String, Any> = [
            "matrix": [[1, 2, 3], [4, 5, 6], [7, 8, 9]]
        ]

        let result = stringify(input)
        let expected = """
		{
			matrix: [
				[
					1,
					2,
					3
				],
				[
					4,
					5,
					6
				],
				[
					7,
					8,
					9
				]
			]
		}
		"""

        #expect(result == expected)

        let _ = try unwrapParseResult(parse(result))
    }

    @Test func dateWithoutTime() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let components = DateComponents(year: 2025, month: 1, day: 15)
        let date = calendar.date(from: components)!

        let input: OrderedDictionary<String, Any> = ["created_at": date]

        let result = stringify(input)
        let _ = try unwrapParseResult(parse(result))
    }

    @Test func dateWithTime() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let components = DateComponents(year: 2025, month: 1, day: 15, hour: 10, minute: 30)
        let date = calendar.date(from: components)!

        let input: OrderedDictionary<String, Any> = ["meeting_at": date]

        let result = stringify(input)
        let _ = try unwrapParseResult(parse(result))
    }

    @Test func dateWithTimeIncludingSeconds() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let components = DateComponents(year: 2025, month: 1, day: 15, hour: 10, minute: 30, second: 45)
        let date = calendar.date(from: components)!

        let input: OrderedDictionary<String, Any> = ["event_at": date]

        let result = stringify(input)
        let _ = try unwrapParseResult(parse(result))
    }

    @Test func booleanValues() throws {
        let input: OrderedDictionary<String, Any> = [
            "is_active": true,
            "is_deleted": false
        ]

        let result = stringify(input)
        let expected = """
		{
			is_active: true,
			is_deleted: false
		}
		"""

        #expect(result == expected)

        let _ = try unwrapParseResult(parse(result))
    }

    @Test func numbers() throws {
        let input: OrderedDictionary<String, Any> = [
            "integer": 42,
            "float": 3.14,
            "negative": -10,
            "zero": 0,
            "scientific": 1.5e10,
            "hex": 0xff
        ]

        let result = stringify(input)
        let expected = """
		{
			integer: 42,
			float: 3.14,
			negative: -10,
			zero: 0,
			scientific: 15000000000,
			hex: 255
		}
		"""

        #expect(result == expected)

        let _ = try unwrapParseResult(parse(result))
    }

    @Test func stringsWithSpecialCharacters() throws {
        let input: OrderedDictionary<String, Any> = [
            "quote": "She said \"Hello\"",
            "path": "/usr/local/bin",
            "regex": "^test.*pattern$"
        ]

        let result = stringify(input)
        let expected = """
		{
			quote: "She said "Hello"",
			path: "/usr/local/bin",
			regex: "^test.*pattern$"
		}
		"""

        #expect(result == expected)

        let parsed = parse(result)
        switch parsed {
        case .success:
            #expect(Bool(false), "Expected failure but got success")
        case .failure:
            break
        }
    }

    @Test func largeDataset() throws {
        // HACK: wtf swift
        let alice: OrderedDictionary<String, Any> = ["id": 1, "name": "Alice", "active": true]
        let bob: OrderedDictionary<String, Any> = ["id": 2, "name": "Bob", "active": false]
        let charlie: OrderedDictionary<String, Any> = ["id": 3, "name": "Charlie", "active": true]
        let stats: OrderedDictionary<String, Any> = [
                "total": 3,
                "active": 2,
                "inactive": 1,
                "rating": 4.5
            ]

        let input: OrderedDictionary<String, Any> = [
            "users": [
                alice,
                bob,
                charlie
            ],
            "stats": stats
        ]

        let result = stringify(input)
        let expected = """
		{
			users: [
				{
					id: 1,
					name: "Alice",
					active: true
				},
				{
					id: 2,
					name: "Bob",
					active: false
				},
				{
					id: 3,
					name: "Charlie",
					active: true
				}
			],
			stats: {
				total: 3,
				active: 2,
				inactive: 1,
				rating: 4.5
			}
		}
		"""

        #expect(result == expected)

        let _ = try unwrapParseResult(parse(result))
    }

    @Test func ansiColorModeEnabled() throws {
        let input: OrderedDictionary<String, Any> = [
            "name": "Alice",
            "age": 25,
            "active": true
        ]

        let result = stringify(input, options: StringifyOptions(ansi: true, indent: nil))
        let stripped = result.replacingOccurrences(of: "\\x1b\\[[0-9]+m", with: "", options: .regularExpression)

        let expected = """
		{
			name: "Alice",
			age: 25,
			active: true
		}
		"""

        #expect(stripped == expected)

        #expect(result.contains("\u{001B}[32m"))
        #expect(result.contains("\u{001B}[33m"))
        #expect(result.contains("\u{001B}[34m"))
        #expect(result.contains("\u{001B}[0m"))
    }

    @Test func ansiColorModeDisabled() throws {
        let input: OrderedDictionary<String, Any> = [
            "name": "Alice",
            "age": 25,
            "active": true
        ]

        let result = stringify(input, options: StringifyOptions(ansi: false, indent: nil))
        let expected = """
		{
			name: "Alice",
			age: 25,
			active: true
		}
		"""

        #expect(result == expected)
        #expect(!result.contains("\u{001B}["))
    }

    @Test func ansiColorsForDates() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let components = DateComponents(year: 2025, month: 1, day: 15)
        let date = calendar.date(from: components)!

        let input: OrderedDictionary<String, Any> = ["date": date]

        let result = stringify(input, options: StringifyOptions(ansi: true, indent: nil))
        let stripped = result.replacingOccurrences(of: "\\x1b\\[[0-9]+m", with: "", options: .regularExpression)

        let _ = try unwrapParseResult(parse(stripped))
        #expect(result.contains("\u{001B}[35m"))
    }

    @Test func arrayOfObjects() throws {
        // HACK: swift...
        let item1: OrderedDictionary<String, Any> = [ "name": "Item 1", "count": 5 ]
        let item2: OrderedDictionary<String, Any> = [ "name": "Item 2", "count": 10 ]
        let item3: OrderedDictionary<String, Any> = [ "name": "Item 3", "count": 15 ]
        let input: OrderedDictionary<String, Any> = [
            "items": [
                item1,
                item2,
                item3
            ]
        ]

        let result = stringify(input)
        let expected = """
		{
			items: [
				{
					name: "Item 1",
					count: 5
				},
				{
					name: "Item 2",
					count: 10
				},
				{
					name: "Item 3",
					count: 15
				}
			]
		}
		"""

print(result)
        #expect(result == expected)

        let _ = try unwrapParseResult(parse(result))
    }

    @Test func customIndentText() throws {
        let input: OrderedDictionary<String, Any> = [
            "name": "Alice",
            "children": ["Jez", "Bez"],
            "active": true
        ]

        let result = stringify(input, options: StringifyOptions(ansi: false, indent: "  "))
        let expected = """
{
  name: "Alice",
  children: [
    "Jez",
    "Bez"
  ],
  active: true
}
"""

        #expect(result == expected)
    }

    @Test func deeplyNestedStructures() throws {
        let input: OrderedDictionary<String, Any> = [
            "level1": [
                "level2": [
                    "level3": [
                        "deep": "value"
                    ]
                ]
            ],
            "nested_array": [
                [[1, 2], [3, 4]],
                [[5, 6], [7, 8]]
            ]
        ]

        let result = stringify(input)
        let expected = """
		{
			level1: {
				level2: {
					level3: {
						deep: "value"
					}
				}
			},
			nested_array: [
				[
					[
						1,
						2
					],
					[
						3,
						4
					]
				],
				[
					[
						5,
						6
					],
					[
						7,
						8
					]
				]
			]
		}
		"""

        #expect(result == expected)

        let _ = try unwrapParseResult(parse(result))
    }
}
