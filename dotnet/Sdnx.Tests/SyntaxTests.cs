using Microsoft.VisualStudio.TestTools.UnitTesting;
using System.Linq;
using Sdnx.Core;

namespace Sdnx.Tests;

[TestClass]
public class SyntaxTests
{
	[TestMethod]
	public void SyntaxErrors_NoOpeningBraceAtTopLevel()
	{
		const string input = "age: 5";
		var result = ParseData.Parse(input);
		Assert.IsFalse(result.Ok);
		Assert.IsNotNull(result.Errors.FirstOrDefault(e => e.Message == "Expected '{' but found 'a'"));
	}

	[TestMethod]
	public void SyntaxErrors_NoClosingBraceAtTopLevel()
	{
		const string input = "{ age: 5 ";
		var result = ParseData.Parse(input);
		Assert.IsFalse(result.Ok);
		Assert.IsNotNull(result.Errors.FirstOrDefault(e => e.Message == "Object not closed"));
	}

	[TestMethod]
	public void SyntaxErrors_NoClosingArrayBrace()
	{
		const string input = "{ foods: [\"ice cream\", \"strudel\" }";
		var result = ParseData.Parse(input);
		Assert.IsFalse(result.Ok);
		Assert.IsNotNull(result.Errors.FirstOrDefault(e => e.Message == "Array not closed"));
	}

	[TestMethod]
	public void SyntaxErrors_NoFieldValue()
	{
		const string input = "{ foods, things: true }";
		var result = ParseData.Parse(input);
		Assert.IsFalse(result.Ok);
		Assert.IsNotNull(result.Errors.FirstOrDefault(e => e.Message == "Expected ':' but found ','"));
	}

	[TestMethod]
	public void SyntaxErrors_UnsupportedValueType()
	{
		const string input = "{ foods: things }";
		var result = ParseData.Parse(input);
		Assert.IsFalse(result.Ok);
		Assert.IsNotNull(result.Errors.FirstOrDefault(e => e.Message == "Unsupported value type 'things'"));
	}

	[TestMethod]
	public void SyntaxErrors_EmptyInput()
	{
		const string input = "";
		var result = ParseData.Parse(input);
		Assert.IsFalse(result.Ok);
		Assert.IsNotNull(result.Errors.FirstOrDefault(e => e.Message == "Expected '{' but found 'undefined'"));
	}

	[TestMethod]
	public void SyntaxErrors_JustWhitespace()
	{
		const string input = "   \n\t  ";
		var result = ParseData.Parse(input);
		Assert.IsFalse(result.Ok);
		Assert.IsNotNull(result.Errors.FirstOrDefault(e => e.Message == "Expected '{' but found 'undefined'"));
	}

	[TestMethod]
	public void SyntaxErrors_FieldNameStartsWithNumber()
	{
		const string input = "{ 1field: \"value\" }";
		var result = ParseData.Parse(input);
		Assert.IsFalse(result.Ok);
		Assert.IsNotNull(result.Errors.FirstOrDefault(e => e.Message == "Field must start with quote or alpha"));
	}

	[TestMethod]
	public void SyntaxErrors_FieldNameWithSpecialChars()
	{
		const string input = "{ field-name: \"value\" }";
		var result = ParseData.Parse(input);
		Assert.IsFalse(result.Ok);
		Assert.IsNotNull(result.Errors.FirstOrDefault(e => e.Message == "Expected ':' but found '-'"));
	}

	[TestMethod]
	public void SyntaxErrors_UnclosedString()
	{
		const string input = "{ name: \"Alice }";
		var result = ParseData.Parse(input);
		Assert.IsFalse(result.Ok);
		Assert.IsNotNull(result.Errors.FirstOrDefault(e => e.Message == "String not closed"));
	}

	[TestMethod]
	public void SyntaxErrors_InvalidEscapeSequence()
	{
		const string input = "{ quote: \"Hel\\lo\" }";
		var result = ParseData.Parse(input);
		Assert.IsFalse(result.Ok);
		Assert.IsNotNull(result.Errors.FirstOrDefault(e => e.Message == "Invalid escape sequence '\\l'"));
	}

	[TestMethod]
	public void SyntaxErrors_NumberWithDecimalButNoDigits()
	{
		const string input = "{ value: 123. }";
		var result = ParseData.Parse(input);
		Assert.IsFalse(result.Ok);
		Assert.IsNotNull(result.Errors.FirstOrDefault(e => e.Message == "Unsupported value type '123.'"));
	}

	[TestMethod]
	public void SyntaxErrors_HexNumberWithInvalidChars()
	{
		const string input = "{ color: 0xGHIJKL }";
		var result = ParseData.Parse(input);
		Assert.IsFalse(result.Ok);
		Assert.IsNotNull(result.Errors.FirstOrDefault(e => e.Message == "Unsupported value type '0xGHIJKL'"));
	}

	[TestMethod]
	public void SyntaxErrors_InvalidDateFormat()
	{
		const string input = "{ dob: 2025-13-01 }";
		var result = ParseData.Parse(input);
		Assert.IsFalse(result.Ok);
		Assert.IsNotNull(result.Errors.FirstOrDefault(e => e.Message == "Invalid date '2025-13-01'"));
	}

	[TestMethod]
	public void SyntaxErrors_BooleanWithWrongCase()
	{
		const string input = "{ active: True }";
		var result = ParseData.Parse(input);
		Assert.IsFalse(result.Ok);
		Assert.IsNotNull(result.Errors.FirstOrDefault(e => e.Message == "Unsupported value type 'True'"));
	}

	[TestMethod]
	public void SyntaxErrors_NegativeWithoutDigits()
	{
		const string input = "{ value: - }";
		var result = ParseData.Parse(input);
		Assert.IsFalse(result.Ok);
		Assert.IsNotNull(result.Errors.FirstOrDefault(e => e.Message == "Unsupported value type '-'"));
	}

	[TestMethod]
	public void SyntaxErrors_ScientificNotationMissingExponent()
	{
		const string input = "{ value: 1.5e }";
		var result = ParseData.Parse(input);
		Assert.IsFalse(result.Ok);
		Assert.IsNotNull(result.Errors.FirstOrDefault(e => e.Message == "Unsupported value type '1.5e'"));
	}

	[TestMethod]
	public void SyntaxErrors_MultipleColonsInField()
	{
		const string input = "{ name:: \"Alice\" }";
		var result = ParseData.Parse(input);
		Assert.IsFalse(result.Ok);
		Assert.IsNotNull(result.Errors.FirstOrDefault(e => e.Message == "Unsupported value type ':'"));
	}

	[TestMethod]
	public void SyntaxErrors_ArrayMissingSeparator()
	{
		const string input = "{ items: [\"a\" \"b\"] }";
		var result = ParseData.Parse(input);
		Assert.IsFalse(result.Ok);
		Assert.IsNotNull(result.Errors.FirstOrDefault(e => e.Message == "Expected ',' but found '\"'"));
	}

	[TestMethod]
	public void SyntaxErrors_ArrayWithTrailingCommaNotFollowedByItem()
	{
		const string input = "{ items: [\"a\",] }";
		var result = ParseData.Parse(input);
		Assert.IsFalse(result.Ok);
		Assert.IsNotNull(result.Errors.FirstOrDefault(e => e.Message == "Unsupported value type ''"));
	}

	[TestMethod]
	public void SyntaxErrors_NestedObjectNotClosed()
	{
		const string input = "{ data: { nested: \"value\" }";
		var result = ParseData.Parse(input);
		Assert.IsFalse(result.Ok);
		Assert.IsNotNull(result.Errors.FirstOrDefault(e => e.Message == "Object not closed"));
	}

	[TestMethod]
	public void SyntaxErrors_NestedArrayNotClosed()
	{
		const string input = "{ matrix: [[1, 2] }";
		var result = ParseData.Parse(input);
		Assert.IsFalse(result.Ok);
		Assert.IsNotNull(result.Errors.FirstOrDefault(e => e.Message == "Array not closed"));
	}

	[TestMethod]
	public void SyntaxErrors_ObjectWithMissingColonAfterFieldName()
	{
		const string input = "{ name \"Alice\" }";
		var result = ParseData.Parse(input);
		Assert.IsFalse(result.Ok);
		Assert.IsNotNull(result.Errors.FirstOrDefault(e => e.Message == "Expected ':' but found '\"'"));
	}

	[TestMethod]
	public void SyntaxErrors_ArrayWithJustOpeningBrace()
	{
		const string input = "{ items: [ }";
		var result = ParseData.Parse(input);
		Assert.IsFalse(result.Ok);
		Assert.IsNotNull(result.Errors.FirstOrDefault(e => e.Message == "Array not closed"));
	}

	[TestMethod]
	public void SyntaxErrors_ArrayWithMissingOpeningBrace()
	{
		const string input = "{ items: 1, 2, 3] }";
		var result = ParseData.Parse(input);
		Assert.IsFalse(result.Ok);
		Assert.IsNotNull(result.Errors.FirstOrDefault(e => e.Message == "Field must start with quote or alpha"));
	}

	[TestMethod]
	public void SyntaxErrors_FieldNameWithStartingUnderscore()
	{
		const string input = "{ _private: \"value\" }";
		var result = ParseData.Parse(input);
		Assert.IsTrue(result.Ok);
	}

	[TestMethod]
	public void SyntaxErrors_FieldNameInQuotes()
	{
		const string input = "{ \"private-field\": \"hidden\" }";
		var result = ParseData.Parse(input);
		Assert.IsTrue(result.Ok);
	}

	[TestMethod]
	public void SyntaxErrors_MultipleCommasInObject()
	{
		const string input = "{ name: \"Alice\",, age: 30 }";
		var result = ParseData.Parse(input);
		Assert.IsFalse(result.Ok);
		Assert.IsNotNull(result.Errors.FirstOrDefault(e => e.Message == "Field must start with quote or alpha"));
	}

	[TestMethod]
	public void SyntaxErrors_CommaAtStartOfObject()
	{
		const string input = "{ , name: \"Alice\" }";
		var result = ParseData.Parse(input);
		Assert.IsFalse(result.Ok);
		Assert.IsNotNull(result.Errors.FirstOrDefault(e => e.Message == "Field must start with quote or alpha"));
	}

	[TestMethod]
	public void SyntaxErrors_InvalidTimeFormat()
	{
		const string input = "{ time: 25:00 }";
		var result = ParseData.Parse(input);
		Assert.IsFalse(result.Ok);
		Assert.IsNotNull(result.Errors.FirstOrDefault(e => e.Message == "Invalid time '25:00'"));
	}

	[TestMethod]
	public void SyntaxErrors_InvalidDatetimeFormat()
	{
		const string input = "{ created: 2025-01-15T14:90+02:00 }";
		var result = ParseData.Parse(input);
		Assert.IsFalse(result.Ok);
		Assert.IsNotNull(result.Errors.FirstOrDefault(e => e.Message == "Invalid date '2025-01-15T14:90+02:00'"));
	}

	[TestMethod]
	public void SyntaxErrors_StringWithUnescapedQuote()
	{
		const string input = "{ text: \"Hello \"World\"\" }";
		var result = ParseData.Parse(input);
		Assert.IsFalse(result.Ok);
		Assert.IsNotNull(result.Errors.FirstOrDefault(e => e.Message == "Expected ':' but found '\"'"));
	}
}
