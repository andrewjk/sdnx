import Testing
@testable import sdnx
import Foundation
import Collections

@Test func basicTest() throws {
	let input = """
	{
		active: true,
		name: "Darren",
		age: 25,
		rating: 4.2,
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
		has_license: true,
		license_num: "112",
	}
	"""

	let result = try parse(input)
	
	#expect(result["active"] as? Bool == true)
	#expect(result["name"] as? String == "Darren")
	#expect(result["age"] as? Int == 25)
	#expect(result["rating"] as? Double == 4.2)
	
	// The parser trims leading whitespace from multiline strings
	// based on the indentation of the second line
	let expectedSkills = "very good at\n  - reading\n  - writing\n  - selling"
	#expect(result["skills"] as? String == expectedSkills)
	
	// Check dates
	if let startedAt = result["started_at"] as? Date {
		let formatter = ISO8601DateFormatter()
		formatter.formatOptions = [.withFullDate]
		let expectedStartedAt = formatter.date(from: "2025-01-01T00:00:00Z")!
		#expect(startedAt == expectedStartedAt)
	} else {
		#expect(Bool(false), "started_at should be a Date")
	}
	
	if let meetingAt = result["meeting_at"] as? Date {
		let formatter = ISO8601DateFormatter()
		formatter.formatOptions = [.withFullDate, .withFullTime, .withTimeZone]
		let expectedMeetingAt = formatter.date(from: "2026-01-01T10:00:00Z")!
		#expect(meetingAt == expectedMeetingAt)
	} else {
		#expect(Bool(false), "meeting_at should be a Date")
	}
	
	// Check children array
	if let children = result["children"] as? [OrderedDictionary<String, Any>] {
		#expect(children.count == 1)
		#expect(children[0]["name"] as? String == "Rocket")
		#expect(children[0]["age"] as? Int == 5)
	} else {
		#expect(Bool(false), "children should be an array of dictionaries")
	}
	
	#expect(result["has_license"] as? Bool == true)
	#expect(result["license_num"] as? String == "112")
	
	// Test with spaced input (fix time format that gets broken by spacing)
	let spacedInput = space(input).replacingOccurrences(of: "10 : 00", with: "10:00")
	let spacedResult = try parse(spacedInput)
	
	#expect(spacedResult["active"] as? Bool == true)
	#expect(spacedResult["name"] as? String == "Darren")
	#expect(spacedResult["age"] as? Int == 25)
	#expect(spacedResult["rating"] as? Double == 4.2)
	#expect(spacedResult["skills"] as? String == expectedSkills)
	
	// Check dates for spaced result
	if let startedAt = spacedResult["started_at"] as? Date {
		let formatter = ISO8601DateFormatter()
		formatter.formatOptions = [.withFullDate]
		let expectedStartedAt = formatter.date(from: "2025-01-01T00:00:00Z")!
		#expect(startedAt == expectedStartedAt)
	} else {
		#expect(Bool(false), "started_at should be a Date")
	}
	
	if let meetingAt = spacedResult["meeting_at"] as? Date {
		let formatter = ISO8601DateFormatter()
		formatter.formatOptions = [.withFullDate, .withFullTime, .withTimeZone]
		let expectedMeetingAt = formatter.date(from: "2026-01-01T10:00:00Z")!
		#expect(meetingAt == expectedMeetingAt)
	} else {
		#expect(Bool(false), "meeting_at should be a Date")
	}
	
	// Check children array for spaced result
	if let children = spacedResult["children"] as? [OrderedDictionary<String, Any>] {
		#expect(children.count == 1)
		#expect(children[0]["name"] as? String == "Rocket")
		#expect(children[0]["age"] as? Int == 5)
	} else {
		#expect(Bool(false), "children should be an array of dictionaries")
	}
	
	#expect(spacedResult["has_license"] as? Bool == true)
	#expect(spacedResult["license_num"] as? String == "112")
	
	// Test with unspaced input
	let unspacedInput = unspace(input)
	let unspacedResult = try parse(unspacedInput)
	
	#expect(unspacedResult["active"] as? Bool == true)
	#expect(unspacedResult["name"] as? String == "Darren")
	#expect(unspacedResult["age"] as? Int == 25)
	#expect(unspacedResult["rating"] as? Double == 4.2)
	#expect(unspacedResult["skills"] as? String == expectedSkills)
	
	// Check dates for unspaced result
	if let startedAt = unspacedResult["started_at"] as? Date {
		let formatter = ISO8601DateFormatter()
		formatter.formatOptions = [.withFullDate]
		let expectedStartedAt = formatter.date(from: "2025-01-01T00:00:00Z")!
		#expect(startedAt == expectedStartedAt)
	} else {
		#expect(Bool(false), "started_at should be a Date")
	}
	
	if let meetingAt = unspacedResult["meeting_at"] as? Date {
		let formatter = ISO8601DateFormatter()
		formatter.formatOptions = [.withFullDate, .withFullTime, .withTimeZone]
		let expectedMeetingAt = formatter.date(from: "2026-01-01T10:00:00Z")!
		#expect(meetingAt == expectedMeetingAt)
	} else {
		#expect(Bool(false), "meeting_at should be a Date")
	}
	
	// Check children array for unspaced result
	if let children = unspacedResult["children"] as? [OrderedDictionary<String, Any>] {
		#expect(children.count == 1)
		#expect(children[0]["name"] as? String == "Rocket")
		#expect(children[0]["age"] as? Int == 5)
	} else {
		#expect(Bool(false), "children should be an array of dictionaries")
	}
	
	#expect(unspacedResult["has_license"] as? Bool == true)
	#expect(unspacedResult["license_num"] as? String == "112")
}

@Test func emptyObject() throws {
	let input = "{}"

	let result = try parse(input)
	
	#expect(result.isEmpty)
	
	// Test with spaced input
	let spacedInput = space(input)
	let spacedResult = try parse(spacedInput)
	#expect(spacedResult.isEmpty)
	
	// Test with unspaced input
	let unspacedInput = unspace(input)
	let unspacedResult = try parse(unspacedInput)
	#expect(unspacedResult.isEmpty)
}

@Test func negativeNumbers() throws {
	let input = "{temp: -10, balance: -3.14}"

	let result = try parse(input)
	
	#expect(result["temp"] as? Int == -10)
	#expect(result["balance"] as? Double == -3.14)
	
	// Test with spaced input
	let spacedInput = space(input)
	let spacedResult = try parse(spacedInput)
	#expect(spacedResult["temp"] as? Int == -10)
	#expect(spacedResult["balance"] as? Double == -3.14)
	
	// Test with unspaced input
	let unspacedInput = unspace(input)
	let unspacedResult = try parse(unspacedInput)
	#expect(unspacedResult["temp"] as? Int == -10)
	#expect(unspacedResult["balance"] as? Double == -3.14)
}

@Test func positiveNumbersWithPlusPrefix() throws {
	let input = "{count: +42, score: +4.5}"

	let result = try parse(input)
	
	#expect(result["count"] as? Int == 42)
	#expect(result["score"] as? Double == 4.5)
	
	// Test with spaced input
	let spacedInput = space(input)
	let spacedResult = try parse(spacedInput)
	#expect(spacedResult["count"] as? Int == 42)
	#expect(spacedResult["score"] as? Double == 4.5)
	
	// Test with unspaced input
	let unspacedInput = unspace(input)
	let unspacedResult = try parse(unspacedInput)
	#expect(unspacedResult["count"] as? Int == 42)
	#expect(unspacedResult["score"] as? Double == 4.5)
}

@Test func hexadecimalIntegers() throws {
	let input = "{color: 0xFF00FF, alpha: 0xAB}"

	let result = try parse(input)
	
	#expect(result["color"] as? Int == 0xff00ff)
	#expect(result["alpha"] as? Int == 0xab)
	
	// Test with spaced input
	let spacedInput = space(input)
	let spacedResult = try parse(spacedInput)
	#expect(spacedResult["color"] as? Int == 0xff00ff)
	#expect(spacedResult["alpha"] as? Int == 0xab)
	
	// Test with unspaced input
	let unspacedInput = unspace(input)
	let unspacedResult = try parse(unspacedInput)
	#expect(unspacedResult["color"] as? Int == 0xff00ff)
	#expect(unspacedResult["alpha"] as? Int == 0xab)
}

@Test func scientificNotation() throws {
	let input = "{distance: 1.5e10, tiny: 1.5e-5}"

	let result = try parse(input)
	
	#expect(result["distance"] as? Double == 1.5e10)
	#expect(result["tiny"] as? Double == 1.5e-5)
	
	// Test with spaced input
	let spacedInput = space(input)
	let spacedResult = try parse(spacedInput)
	#expect(spacedResult["distance"] as? Double == 1.5e10)
	#expect(spacedResult["tiny"] as? Double == 1.5e-5)
	
	// Test with unspaced input
	let unspacedInput = unspace(input)
	let unspacedResult = try parse(unspacedInput)
	#expect(unspacedResult["distance"] as? Double == 1.5e10)
	#expect(unspacedResult["tiny"] as? Double == 1.5e-5)
}

@Test func numbersWithUnderscoreSeparators() throws {
	let input = "{population: 1_000_000, big_number: 1_000_000.123}"

	let result = try parse(input)
	
	#expect(result["population"] as? Int == 1_000_000)
	#expect(result["big_number"] as? Double == 1_000_000.123)
	
	// Test with spaced input
	let spacedInput = space(input)
	let spacedResult = try parse(spacedInput)
	#expect(spacedResult["population"] as? Int == 1_000_000)
	#expect(spacedResult["big_number"] as? Double == 1_000_000.123)
	
	// Test with unspaced input
	let unspacedInput = unspace(input)
	let unspacedResult = try parse(unspacedInput)
	#expect(unspacedResult["population"] as? Int == 1_000_000)
	#expect(unspacedResult["big_number"] as? Double == 1_000_000.123)
}

@Test func stringWithEscapedQuotes() throws {
	let input = "{quote: \"She said \\\"Hello\\\"\"}"

	let result = try parse(input)
	
	#expect(result["quote"] as? String == "She said \"Hello\"")
	
	// Test with spaced input
	let spacedInput = space(input)
	let spacedResult = try parse(spacedInput)
	#expect(spacedResult["quote"] as? String == "She said \"Hello\"")
	
	// Test with unspaced input
	let unspacedInput = unspace(input)
	let unspacedResult = try parse(unspacedInput)
	#expect(unspacedResult["quote"] as? String == "She said \"Hello\"")
}

@Test func quotedFieldName() throws {
	let input = "{\"/field-with-dash\": \"value\", \"with spaces\": \"test\"}"

	let result = try parse(input)
	
	#expect(result["\"/field-with-dash\""] as? String == "value")
	#expect(result["\"with spaces\""] as? String == "test")
	
	// Test with spaced input
	let spacedInput = space(input)
	let spacedResult = try parse(spacedInput)
	#expect(spacedResult["\"/field-with-dash\""] as? String == "value")
	#expect(spacedResult["\"with spaces\""] as? String == "test")
	
	// Test with unspaced input
	let unspacedInput = unspace(input)
	let unspacedResult = try parse(unspacedInput)
	#expect(unspacedResult["\"/field-with-dash\""] as? String == "value")
	#expect(unspacedResult["\"with spaces\""] as? String == "test")
}

@Test func fieldNamesWithNumbersAndUnderscores() throws {
	let input = "{field1: \"a\", field_2: \"b\", _private: \"c\", field_3_name: \"d\"}"

	let result = try parse(input)
	
	#expect(result["field1"] as? String == "a")
	#expect(result["field_2"] as? String == "b")
	#expect(result["_private"] as? String == "c")
	#expect(result["field_3_name"] as? String == "d")
	
	// Test with spaced input
	let spacedInput = space(input)
	let spacedResult = try parse(spacedInput)
	#expect(spacedResult["field1"] as? String == "a")
	#expect(spacedResult["field_2"] as? String == "b")
	#expect(spacedResult["_private"] as? String == "c")
	#expect(spacedResult["field_3_name"] as? String == "d")
	
	// Test with unspaced input
	let unspacedInput = unspace(input)
	let unspacedResult = try parse(unspacedInput)
	#expect(unspacedResult["field1"] as? String == "a")
	#expect(unspacedResult["field_2"] as? String == "b")
	#expect(unspacedResult["_private"] as? String == "c")
	#expect(unspacedResult["field_3_name"] as? String == "d")
}

@Test func timeOnly() throws {
	let input = "{meeting_time: 14:30, alarm_time: 07:15:30}"

	let result = try parse(input)
	
	let formatter = ISO8601DateFormatter()
	formatter.formatOptions = [.withFullDate, .withFullTime, .withTimeZone]
	
	if let meetingTime = result["meeting_time"] as? Date {
		let expected = formatter.date(from: "1900-01-01T14:30:00Z")!
		#expect(meetingTime == expected)
	} else {
		#expect(Bool(false), "meeting_time should be a Date")
	}
	
	if let alarmTime = result["alarm_time"] as? Date {
		let expected = formatter.date(from: "1900-01-01T07:15:30Z")!
		#expect(alarmTime == expected)
	} else {
		#expect(Bool(false), "alarm_time should be a Date")
	}
	
	// Test with spaced input (fix time formats that get broken by spacing)
	let spacedInput = space(input)
		.replacingOccurrences(of: "14 : 30", with: "14:30")
		.replacingOccurrences(of: "07 : 15 : 30", with: "07:15:30")
	let spacedResult = try parse(spacedInput)
	
	if let meetingTime = spacedResult["meeting_time"] as? Date {
		let expected = formatter.date(from: "1900-01-01T14:30:00Z")!
		#expect(meetingTime == expected)
	} else {
		#expect(Bool(false), "meeting_time should be a Date")
	}
	
	if let alarmTime = spacedResult["alarm_time"] as? Date {
		let expected = formatter.date(from: "1900-01-01T07:15:30Z")!
		#expect(alarmTime == expected)
	} else {
		#expect(Bool(false), "alarm_time should be a Date")
	}
	
	// Test with unspaced input
	let unspacedInput = unspace(input)
	let unspacedResult = try parse(unspacedInput)
	
	if let meetingTime = unspacedResult["meeting_time"] as? Date {
		let expected = formatter.date(from: "1900-01-01T14:30:00Z")!
		#expect(meetingTime == expected)
	} else {
		#expect(Bool(false), "meeting_time should be a Date")
	}
	
	if let alarmTime = unspacedResult["alarm_time"] as? Date {
		let expected = formatter.date(from: "1900-01-01T07:15:30Z")!
		#expect(alarmTime == expected)
	} else {
		#expect(Bool(false), "alarm_time should be a Date")
	}
}

@Test func datetimeWithTimezoneOffset() throws {
	let input = "{event_time: 2025-01-15T14:30+02:00}"

	let result = try parse(input)
	
	if let eventTime = result["event_time"] as? Date {
		let formatter = ISO8601DateFormatter()
		formatter.formatOptions = [.withFullDate, .withFullTime, .withTimeZone]
		let expected = formatter.date(from: "2025-01-15T14:30:00+02:00")!
		#expect(eventTime == expected)
	} else {
		#expect(Bool(false), "event_time should be a Date")
	}
	
	// Test with spaced input (fix time format that gets broken by spacing)
	let spacedInput = space(input).replacingOccurrences(of: "14 : 30+02 : 00", with: "14:30+02:00")
	let spacedResult = try parse(spacedInput)
	
	if let eventTime = spacedResult["event_time"] as? Date {
		let formatter = ISO8601DateFormatter()
		formatter.formatOptions = [.withFullDate, .withFullTime, .withTimeZone]
		let expected = formatter.date(from: "2025-01-15T14:30:00+02:00")!
		#expect(eventTime == expected)
	} else {
		#expect(Bool(false), "event_time should be a Date")
	}
	
	// Test with unspaced input
	let unspacedInput = unspace(input)
	let unspacedResult = try parse(unspacedInput)
	
	if let eventTime = unspacedResult["event_time"] as? Date {
		let formatter = ISO8601DateFormatter()
		formatter.formatOptions = [.withFullDate, .withFullTime, .withTimeZone]
		let expected = formatter.date(from: "2025-01-15T14:30:00+02:00")!
		#expect(eventTime == expected)
	} else {
		#expect(Bool(false), "event_time should be a Date")
	}
}

@Test func multipleConsecutiveComments() throws {
	let input = """
	# First comment
	# Second comment
	# Third comment
	{
		name: "Alice"
	}
	"""

	let result = try parse(input)
	
	#expect(result["name"] as? String == "Alice")
	
	// Test with spaced input
	let spacedInput = space(input)
	let spacedResult = try parse(spacedInput)
	#expect(spacedResult["name"] as? String == "Alice")
	
	// Test with unspaced input
	let unspacedInput = unspace(input)
	let unspacedResult = try parse(unspacedInput)
	#expect(unspacedResult["name"] as? String == "Alice")
}

@Test func inlineComments() throws {
	let input = "{name: \"Bob\", # inline comment\nage: 30}"

	let result = try parse(input)
	
	#expect(result["name"] as? String == "Bob")
	#expect(result["age"] as? Int == 30)
	
	// Test with spaced input
	let spacedInput = space(input)
	let spacedResult = try parse(spacedInput)
	#expect(spacedResult["name"] as? String == "Bob")
	#expect(spacedResult["age"] as? Int == 30)
	
	// Test with unspaced input
	let unspacedInput = unspace(input)
	let unspacedResult = try parse(unspacedInput)
	#expect(unspacedResult["name"] as? String == "Bob")
	#expect(unspacedResult["age"] as? Int == 30)
}

@Test func commentsBetweenFields() throws {
	let input = """
	{name: "Alice", # name field
	# separator
	age: 25 # age field
	}
	"""

	let result = try parse(input)
	
	#expect(result["name"] as? String == "Alice")
	#expect(result["age"] as? Int == 25)
	
	// Test with spaced input
	let spacedInput = space(input)
	let spacedResult = try parse(spacedInput)
	#expect(spacedResult["name"] as? String == "Alice")
	#expect(spacedResult["age"] as? Int == 25)
	
	// Test with unspaced input
	let unspacedInput = unspace(input)
	let unspacedResult = try parse(unspacedInput)
	#expect(unspacedResult["name"] as? String == "Alice")
	#expect(unspacedResult["age"] as? Int == 25)
}

@Test func deeplyNestedStructures() throws {
	let input = """
	{
		level1: {
			level2: {
				level3: {
					deep: "value"
				}
			}
		},
		nested_array: [[[1, 2], [3, 4]], [[5, 6], [7, 8]]]
	}
	"""

	let result = try parse(input)
	
	// Check deeply nested object
	if let level1 = result["level1"] as? OrderedDictionary<String, Any>,
	   let level2 = level1["level2"] as? OrderedDictionary<String, Any>,
	   let level3 = level2["level3"] as? OrderedDictionary<String, Any> {
		#expect(level3["deep"] as? String == "value")
	} else {
		#expect(Bool(false), "Deeply nested structure should be accessible")
	}
	
	// Check deeply nested array
	if let nestedArray = result["nested_array"] as? [[[Int]]] {
		#expect(nestedArray.count == 2)
		#expect(nestedArray[0].count == 2)
		#expect(nestedArray[0][0] == [1, 2])
		#expect(nestedArray[0][1] == [3, 4])
		#expect(nestedArray[1][0] == [5, 6])
		#expect(nestedArray[1][1] == [7, 8])
	} else {
		#expect(Bool(false), "nested_array should be a 3D array of integers")
	}
	
	// Test with spaced input
	let spacedInput = space(input)
	let spacedResult = try parse(spacedInput)
	
	if let level1 = spacedResult["level1"] as? OrderedDictionary<String, Any>,
	   let level2 = level1["level2"] as? OrderedDictionary<String, Any>,
	   let level3 = level2["level3"] as? OrderedDictionary<String, Any> {
		#expect(level3["deep"] as? String == "value")
	} else {
		#expect(Bool(false), "Deeply nested structure should be accessible")
	}
	
	if let nestedArray = spacedResult["nested_array"] as? [[[Int]]] {
		#expect(nestedArray.count == 2)
		#expect(nestedArray[0].count == 2)
		#expect(nestedArray[0][0] == [1, 2])
		#expect(nestedArray[0][1] == [3, 4])
		#expect(nestedArray[1][0] == [5, 6])
		#expect(nestedArray[1][1] == [7, 8])
	} else {
		#expect(Bool(false), "nested_array should be a 3D array of integers")
	}
	
	// Test with unspaced input
	let unspacedInput = unspace(input)
	let unspacedResult = try parse(unspacedInput)
	
	if let level1 = unspacedResult["level1"] as? OrderedDictionary<String, Any>,
	   let level2 = level1["level2"] as? OrderedDictionary<String, Any>,
	   let level3 = level2["level3"] as? OrderedDictionary<String, Any> {
		#expect(level3["deep"] as? String == "value")
	} else {
		#expect(Bool(false), "Deeply nested structure should be accessible")
	}
	
	if let nestedArray = unspacedResult["nested_array"] as? [[[Int]]] {
		#expect(nestedArray.count == 2)
		#expect(nestedArray[0].count == 2)
		#expect(nestedArray[0][0] == [1, 2])
		#expect(nestedArray[0][1] == [3, 4])
		#expect(nestedArray[1][0] == [5, 6])
		#expect(nestedArray[1][1] == [7, 8])
	} else {
		#expect(Bool(false), "nested_array should be a 3D array of integers")
	}
}

@Test func singleFieldObject() throws {
	let input = "{name: \"Alice\"}"

	let result = try parse(input)
	
	#expect(result["name"] as? String == "Alice")
	
	// Test with spaced input
	let spacedInput = space(input)
	let spacedResult = try parse(spacedInput)
	#expect(spacedResult["name"] as? String == "Alice")
	
	// Test with unspaced input
	let unspacedInput = unspace(input)
	let unspacedResult = try parse(unspacedInput)
	#expect(unspacedResult["name"] as? String == "Alice")
}

@Test func largeDataset() throws {
	let input = """
	{
		users: [
			{ id: 1, name: "Alice", active: true },
			{ id: 2, name: "Bob", active: false },
			{ id: 3, name: "Charlie", active: true },
			{ id: 4, name: "Diana", active: true },
			{ id: 5, name: "Eve", active: false }
		],
		stats: {
			total: 5,
			active: 3,
			inactive: 2,
			rating: 4.5
		},
		metadata: {
			created_at: 2025-01-01,
			updated_at: 2025-01-15T10:30:00,
			tags: ["production", "api", "v1"]
		}
	}
	"""

	let result = try parse(input)
	
	// Check users array
	if let users = result["users"] as? [OrderedDictionary<String, Any>] {
		#expect(users.count == 5)
		
		// Check first user
		#expect(users[0]["id"] as? Int == 1)
		#expect(users[0]["name"] as? String == "Alice")
		#expect(users[0]["active"] as? Bool == true)
		
		// Check last user
		#expect(users[4]["id"] as? Int == 5)
		#expect(users[4]["name"] as? String == "Eve")
		#expect(users[4]["active"] as? Bool == false)
	} else {
		#expect(Bool(false), "users should be an array of dictionaries")
	}
	
	// Check stats
	if let stats = result["stats"] as? OrderedDictionary<String, Any> {
		#expect(stats["total"] as? Int == 5)
		#expect(stats["active"] as? Int == 3)
		#expect(stats["inactive"] as? Int == 2)
		#expect(stats["rating"] as? Double == 4.5)
	} else {
		#expect(Bool(false), "stats should be a dictionary")
	}
	
	// Check metadata
	if let metadata = result["metadata"] as? OrderedDictionary<String, Any> {
		if let createdAt = metadata["created_at"] as? Date {
			let formatter = ISO8601DateFormatter()
			formatter.formatOptions = [.withFullDate]
			let expected = formatter.date(from: "2025-01-01T00:00:00Z")!
			#expect(createdAt == expected)
		} else {
			#expect(Bool(false), "created_at should be a Date")
		}
		
		if let updatedAt = metadata["updated_at"] as? Date {
			let formatter = ISO8601DateFormatter()
			formatter.formatOptions = [.withFullDate, .withFullTime, .withTimeZone]
			let expected = formatter.date(from: "2025-01-15T10:30:00Z")!
			#expect(updatedAt == expected)
		} else {
			#expect(Bool(false), "updated_at should be a Date")
		}
		
		if let tags = metadata["tags"] as? [String] {
			#expect(tags == ["production", "api", "v1"])
		} else {
			#expect(Bool(false), "tags should be an array of strings")
		}
	} else {
		#expect(Bool(false), "metadata should be a dictionary")
	}
	
	// Test with spaced input (fix time format that gets broken by spacing)
	let spacedInput = space(input).replacingOccurrences(of: "10 : 30 : 00", with: "10:30:00")
	let spacedResult = try parse(spacedInput)
	
	// Check users array for spaced result
	if let users = spacedResult["users"] as? [OrderedDictionary<String, Any>] {
		#expect(users.count == 5)
		
		// Check first user
		#expect(users[0]["id"] as? Int == 1)
		#expect(users[0]["name"] as? String == "Alice")
		#expect(users[0]["active"] as? Bool == true)
		
		// Check last user
		#expect(users[4]["id"] as? Int == 5)
		#expect(users[4]["name"] as? String == "Eve")
		#expect(users[4]["active"] as? Bool == false)
	} else {
		#expect(Bool(false), "users should be an array of dictionaries")
	}
	
	// Check stats for spaced result
	if let stats = spacedResult["stats"] as? OrderedDictionary<String, Any> {
		#expect(stats["total"] as? Int == 5)
		#expect(stats["active"] as? Int == 3)
		#expect(stats["inactive"] as? Int == 2)
		#expect(stats["rating"] as? Double == 4.5)
	} else {
		#expect(Bool(false), "stats should be a dictionary")
	}
	
	// Check metadata for spaced result
	if let metadata = spacedResult["metadata"] as? OrderedDictionary<String, Any> {
		if let createdAt = metadata["created_at"] as? Date {
			let formatter = ISO8601DateFormatter()
			formatter.formatOptions = [.withFullDate]
			let expected = formatter.date(from: "2025-01-01T00:00:00Z")!
			#expect(createdAt == expected)
		} else {
			#expect(Bool(false), "created_at should be a Date")
		}
		
		if let updatedAt = metadata["updated_at"] as? Date {
			let formatter = ISO8601DateFormatter()
			formatter.formatOptions = [.withFullDate, .withFullTime, .withTimeZone]
			let expected = formatter.date(from: "2025-01-15T10:30:00Z")!
			#expect(updatedAt == expected)
		} else {
			#expect(Bool(false), "updated_at should be a Date")
		}
		
		if let tags = metadata["tags"] as? [String] {
			#expect(tags == ["production", "api", "v1"])
		} else {
			#expect(Bool(false), "tags should be an array of strings")
		}
	} else {
		#expect(Bool(false), "metadata should be a dictionary")
	}
	
	// Test with unspaced input
	let unspacedInput = unspace(input)
	let unspacedResult = try parse(unspacedInput)
	
	// Check users array for unspaced result
	if let users = unspacedResult["users"] as? [OrderedDictionary<String, Any>] {
		#expect(users.count == 5)
		
		// Check first user
		#expect(users[0]["id"] as? Int == 1)
		#expect(users[0]["name"] as? String == "Alice")
		#expect(users[0]["active"] as? Bool == true)
		
		// Check last user
		#expect(users[4]["id"] as? Int == 5)
		#expect(users[4]["name"] as? String == "Eve")
		#expect(users[4]["active"] as? Bool == false)
	} else {
		#expect(Bool(false), "users should be an array of dictionaries")
	}
	
	// Check stats for unspaced result
	if let stats = unspacedResult["stats"] as? OrderedDictionary<String, Any> {
		#expect(stats["total"] as? Int == 5)
		#expect(stats["active"] as? Int == 3)
		#expect(stats["inactive"] as? Int == 2)
		#expect(stats["rating"] as? Double == 4.5)
	} else {
		#expect(Bool(false), "stats should be a dictionary")
	}
	
	// Check metadata for unspaced result
	if let metadata = unspacedResult["metadata"] as? OrderedDictionary<String, Any> {
		if let createdAt = metadata["created_at"] as? Date {
			let formatter = ISO8601DateFormatter()
			formatter.formatOptions = [.withFullDate]
			let expected = formatter.date(from: "2025-01-01T00:00:00Z")!
			#expect(createdAt == expected)
		} else {
			#expect(Bool(false), "created_at should be a Date")
		}
		
		if let updatedAt = metadata["updated_at"] as? Date {
			let formatter = ISO8601DateFormatter()
			formatter.formatOptions = [.withFullDate, .withFullTime, .withTimeZone]
			let expected = formatter.date(from: "2025-01-15T10:30:00Z")!
			#expect(updatedAt == expected)
		} else {
			#expect(Bool(false), "updated_at should be a Date")
		}
		
		if let tags = metadata["tags"] as? [String] {
			#expect(tags == ["production", "api", "v1"])
		} else {
			#expect(Bool(false), "tags should be an array of strings")
		}
	} else {
		#expect(Bool(false), "metadata should be a dictionary")
	}
}
