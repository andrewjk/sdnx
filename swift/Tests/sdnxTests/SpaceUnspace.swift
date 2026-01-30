import Foundation

/// Adds spaces around punctuation characters: {}[]:,
func space(_ value: String) -> String {
	let spacedChars = CharacterSet(charactersIn: "{}[]:,")
	var result = ""
	var i = value.startIndex
	
	while i < value.endIndex {
		let char = value[i]
		
		if char == "\"" {
			result.append(" \"")
			value.formIndex(after: &i)
			while i < value.endIndex {
				let current = value[i]
				let prev = value.index(i, offsetBy: -1)
				if current == "\"" && value[prev] != "\\" {
					break
				}
				result.append(current)
				value.formIndex(after: &i)
			}
			if i < value.endIndex {
				result.append(value[i])
			}
		} else if char == "#" {
			result.append(" #")
			value.formIndex(after: &i)
			while i < value.endIndex && value[i] != "\n" {
				result.append(value[i])
				value.formIndex(after: &i)
			}
			if i < value.endIndex {
				result.append(value[i])
			}
		} else if spacedChars.contains(char.unicodeScalars.first!) {
			result.append(" ")
			result.append(char)
			result.append(" ")
		} else {
			result.append(char)
		}
		
		if i < value.endIndex {
			value.formIndex(after: &i)
		}
	}
	
	return result
}

/// Removes all whitespace except within strings and comments
func unspace(_ value: String) -> String {
	var result = ""
	var i = value.startIndex
	
	while i < value.endIndex {
		let char = value[i]
		
		if char == "\"" {
			result.append(char)
			value.formIndex(after: &i)
			while i < value.endIndex {
				let current = value[i]
				let prev = value.index(i, offsetBy: -1)
				if current == "\"" && value[prev] != "\\" {
					break
				}
				result.append(current)
				value.formIndex(after: &i)
			}
			if i < value.endIndex {
				result.append(value[i])
			}
		} else if char == "#" {
			result.append(" #")
			value.formIndex(after: &i)
			while i < value.endIndex && value[i] != "\n" {
				result.append(value[i])
				value.formIndex(after: &i)
			}
			if i < value.endIndex {
				result.append(value[i])
			}
		} else if char != " " && char != "\t" && char != "\n" && char != "\r" {
			result.append(char)
		}
		
		if i < value.endIndex {
			value.formIndex(after: &i)
		}
	}
	
	return result
}
