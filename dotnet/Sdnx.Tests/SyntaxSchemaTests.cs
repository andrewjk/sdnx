using Microsoft.VisualStudio.TestTools.UnitTesting;
using Sdnx.Core;
using System.Linq;

namespace Sdnx.Tests;

[TestClass]
public class SyntaxSchemaTests
{
	[TestMethod]
	public void SchemaSyntaxErrors_NoOpeningBraceAtTopLevel()
	{
		const string input = "age: int";
		var result = ParseSchema.Parse(input);
		Assert.IsFalse(result.Ok);
		Assert.IsNotNull(result.Errors.FirstOrDefault(e => e.Message == "Expected '{' but found 'a'"));
	}

	[TestMethod]
	public void SchemaSyntaxErrors_NoClosingBraceAtTopLevel()
	{
		const string input = "{ age: int ";
		var result = ParseSchema.Parse(input);
		Assert.IsFalse(result.Ok);
		Assert.IsNotNull(result.Errors.FirstOrDefault(e => e.Message == "Schema object not closed"));
	}

	[TestMethod]
	public void SchemaSyntaxErrors_NoClosingArrayBrace()
	{
		const string input = "{ foods: [string }";
		var result = ParseSchema.Parse(input);
		Assert.IsFalse(result.Ok);
		Assert.IsNotNull(result.Errors.FirstOrDefault(e => e.Message == "Schema array not closed"));
	}

	[TestMethod]
	public void SchemaSyntaxErrors_NoFieldValue()
	{
		const string input = "{ foods, things: boolean }";
		var result = ParseSchema.Parse(input);
		Assert.IsFalse(result.Ok);
		Assert.IsNotNull(result.Errors.FirstOrDefault(e => e.Message == "Expected ':' but found ','"));
	}

	[TestMethod]
	public void SchemaSyntaxErrors_UnsupportedValueType()
	{
		const string input = "{ foods: things }";
		var result = ParseSchema.Parse(input);
		Assert.IsFalse(result.Ok);
		Assert.IsNotNull(result.Errors.FirstOrDefault(e => e.Message == "Unsupported value type 'things'"));
	}

	[TestMethod]
	public void SchemaSyntaxErrors_EmptyInput()
	{
		const string input = "";
		var result = ParseSchema.Parse(input);
		Assert.IsFalse(result.Ok);
		Assert.IsNotNull(result.Errors.FirstOrDefault(e => e.Message == "Expected '{' but found 'undefined'"));
	}

	[TestMethod]
	public void SchemaSyntaxErrors_JustWhitespace()
	{
		const string input = "   \n\t  ";
		var result = ParseSchema.Parse(input);
		Assert.IsFalse(result.Ok);
		Assert.IsNotNull(result.Errors.FirstOrDefault(e => e.Message == "Expected '{' but found 'undefined'"));
	}

	[TestMethod]
	public void SchemaSyntaxErrors_FieldNameStartsWithNumber()
	{
		const string input = "{ 1field: string }";
		var result = ParseSchema.Parse(input);
		Assert.IsFalse(result.Ok);
		Assert.IsNotNull(result.Errors.FirstOrDefault(e => e.Message == "Field must start with quote or alpha"));
	}

	[TestMethod]
	public void SchemaSyntaxErrors_FieldNameWithSpecialChars()
	{
		const string input = "{ field-name: string }";
		var result = ParseSchema.Parse(input);
		Assert.IsFalse(result.Ok);
		Assert.IsNotNull(result.Errors.FirstOrDefault(e => e.Message == "Expected ':' but found '-'"));
	}

	[TestMethod]
	public void SchemaSyntaxErrors_UnclosedString()
	{
		const string input = "{ name: \"Alice }";
		var result = ParseSchema.Parse(input);
		Assert.IsFalse(result.Ok);
		Assert.IsNotNull(result.Errors.FirstOrDefault(e => e.Message == "String not closed"));
	}

	[TestMethod]
	public void SchemaSyntaxErrors_InvalidEscapeSequence()
	{
		const string input = "{ quote: \"Hel\\lo\" }";
		var result = ParseSchema.Parse(input);
		Assert.IsFalse(result.Ok);
		Assert.IsNotNull(result.Errors.FirstOrDefault(e => e.Message == "Invalid escape sequence '\\l'"));
	}

	[TestMethod]
	public void SchemaSyntaxErrors_NumberWithDecimalButNoDigits()
	{
		const string input = "{ value: 123. }";
		var result = ParseSchema.Parse(input);
		Assert.IsFalse(result.Ok);
		Assert.IsNotNull(result.Errors.FirstOrDefault(e => e.Message == "Unsupported value type '123.'"));
	}

	[TestMethod]
	public void SchemaSyntaxErrors_HexNumberWithInvalidChars()
	{
		const string input = "{ color: 0xGHIJKL }";
		var result = ParseSchema.Parse(input);
		Assert.IsFalse(result.Ok);
		Assert.IsNotNull(result.Errors.FirstOrDefault(e => e.Message == "Unsupported value type '0xGHIJKL'"));
	}

	[TestMethod]
	public void SchemaSyntaxErrors_InvalidDateFormat()
	{
		const string input = "{ dob: 2025-13-01 }";
		var result = ParseSchema.Parse(input);
		Assert.IsFalse(result.Ok);
		Assert.IsNotNull(result.Errors.FirstOrDefault(e => e.Message == "Invalid date '2025-13-01'"));
	}

	[TestMethod]
	public void SchemaSyntaxErrors_BooleanWithWrongCase()
	{
		const string input = "{ active: True }";
		var result = ParseSchema.Parse(input);
		Assert.IsFalse(result.Ok);
		Assert.IsNotNull(result.Errors.FirstOrDefault(e => e.Message == "Unsupported value type 'True'"));
	}

	[TestMethod]
	public void SchemaSyntaxErrors_NegativeWithoutDigits()
	{
		const string input = "{ value: - }";
		var result = ParseSchema.Parse(input);
		Assert.IsFalse(result.Ok);
		Assert.IsNotNull(result.Errors.FirstOrDefault(e => e.Message == "Unsupported value type '-'"));
	}

	[TestMethod]
	public void SchemaSyntaxErrors_ScientificNotationMissingExponent()
	{
		const string input = "{ value: 1.5e }";
		var result = ParseSchema.Parse(input);
		Assert.IsFalse(result.Ok);
		Assert.IsNotNull(result.Errors.FirstOrDefault(e => e.Message == "Unsupported value type '1.5e'"));
	}

	[TestMethod]
	public void SchemaSyntaxErrors_MultipleColonsInField()
	{
		const string input = "{ name:: string }";
		var result = ParseSchema.Parse(input);
		Assert.IsFalse(result.Ok);
		Assert.IsNotNull(result.Errors.FirstOrDefault(e => e.Message == "Unsupported value type ':'"));
	}

	[TestMethod]
	public void SchemaSyntaxErrors_ArrayWithTrailingCommaNotFollowedByItem()
	{
		const string input = "{ items: [\"a\",] }";
		var result = ParseSchema.Parse(input);
		Assert.IsFalse(result.Ok);
		Assert.IsNotNull(result.Errors.FirstOrDefault(e => e.Message == "Schema array not closed"));
	}

	[TestMethod]
	public void SchemaSyntaxErrors_NestedObjectNotClosed()
	{
		const string input = "{ data: { nested: string }";
		var result = ParseSchema.Parse(input);
		Assert.IsFalse(result.Ok);
		Assert.IsNotNull(result.Errors.FirstOrDefault(e => e.Message == "Schema object not closed"));
	}

	[TestMethod]
	public void SchemaSyntaxErrors_NestedArrayNotClosed()
	{
		const string input = "{ matrix: [[int] }";
		var result = ParseSchema.Parse(input);
		Assert.IsFalse(result.Ok);
		Assert.IsNotNull(result.Errors.FirstOrDefault(e => e.Message == "Schema array not closed"));
	}

	[TestMethod]
	public void SchemaSyntaxErrors_ObjectWithMissingColonAfterFieldName()
	{
		const string input = "{ name string }";
		var result = ParseSchema.Parse(input);
		Assert.IsFalse(result.Ok);
		Assert.IsNotNull(result.Errors.FirstOrDefault(e => e.Message == "Expected ':' but found 's'"));
	}

	[TestMethod]
	public void SchemaSyntaxErrors_ArrayWithJustOpeningBrace()
	{
		const string input = "{ items: [ }";
		var result = ParseSchema.Parse(input);
		Assert.IsFalse(result.Ok);
		Assert.IsNotNull(result.Errors.FirstOrDefault(e => e.Message == "Schema array not closed"));
	}

	[TestMethod]
	public void SchemaSyntaxErrors_ArrayWithMissingOpeningBrace()
	{
		const string input = "{ items: int] }";
		var result = ParseSchema.Parse(input);
		Assert.IsFalse(result.Ok);
		// TODO: a better error
		//Assert.IsNotNull(result.Errors.FirstOrDefault(e => e.Message == "Schema object not opened"));
		Assert.IsNotNull(result.Errors.FirstOrDefault(e => e.Message == "Schema object not closed"));
	}

	[TestMethod]
	public void SchemaSyntaxErrors_FieldNameWithStartingUnderscore()
	{
		const string input = "{ _private: string }";
		var result = ParseSchema.Parse(input);
		Assert.IsTrue(result.Ok);
	}

	[TestMethod]
	public void SchemaSyntaxErrors_FieldNameInQuotes()
	{
		const string input = "{ \"private-field\": string }";
		var result = ParseSchema.Parse(input);
		Assert.IsTrue(result.Ok);
	}

	[TestMethod]
	public void SchemaSyntaxErrors_MultipleCommasInObject()
	{
		const string input = "{ name: string,, age: int }";
		var result = ParseSchema.Parse(input);
		Assert.IsFalse(result.Ok);
		Assert.IsNotNull(result.Errors.FirstOrDefault(e => e.Message == "Field must start with quote or alpha"));
	}

	[TestMethod]
	public void SchemaSyntaxErrors_CommaAtStartOfObject()
	{
		const string input = "{ , name: string }";
		var result = ParseSchema.Parse(input);
		Assert.IsFalse(result.Ok);
		Assert.IsNotNull(result.Errors.FirstOrDefault(e => e.Message == "Field must start with quote or alpha"));
	}

	[TestMethod]
	public void SchemaSyntaxErrors_InvalidTimeFormat()
	{
		const string input = "{ time: 25:00 }";
		var result = ParseSchema.Parse(input);
		Assert.IsFalse(result.Ok);
		Assert.IsNotNull(result.Errors.FirstOrDefault(e => e.Message == "Invalid time '25:00'"));
	}

	[TestMethod]
	public void SchemaSyntaxErrors_InvalidDatetimeFormat()
	{
		const string input = "{ created: 2025-01-15T14:90+02:00 }";
		var result = ParseSchema.Parse(input);
		Assert.IsFalse(result.Ok);
		Assert.IsNotNull(result.Errors.FirstOrDefault(e => e.Message == "Invalid date '2025-01-15T14:90+02:00'"));
	}

	[TestMethod]
	public void SchemaSyntaxErrors_StringWithUnescapedQuote()
	{
		const string input = "{ text: \"Hello \"World\"\" }";
		var result = ParseSchema.Parse(input);
		Assert.IsFalse(result.Ok);
		Assert.IsNotNull(result.Errors.FirstOrDefault(e => e.Message == "Expected ':' but found '\"'"));
	}

	[TestMethod]
	public void SchemaSyntaxErrors_UnknownValidator()
	{
		const string input = "{ text: string required }";
		var result = ParseSchema.Parse(input);
		Assert.IsFalse(result.Ok);
		Assert.IsNotNull(result.Errors.FirstOrDefault(e => e.Message == "Unsupported validator 'required'"));
	}
}
