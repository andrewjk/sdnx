using Microsoft.VisualStudio.TestTools.UnitTesting;
using Sdnx.Core;

namespace Sdnx.Tests;

[TestClass]
public class CheckTests
{
    private void AssertCheckOk(CheckResult result)
    {
        Assert.IsTrue(result.Ok, result.Ok ? "" : string.Join("\n", result.Errors?.Select(e => e.Message) ?? new List<string>()));
    }

    private void AssertCheckError(CheckResult result, string expectedMessage)
    {
        Assert.IsFalse(result.Ok);
        Assert.IsNotNull(result.Errors);
        Assert.HasCount(1, result.Errors);
        Assert.AreEqual(expectedMessage, result.Errors[0].Message);
    }

    [TestMethod]
    public void NullTypeValid()
    {
        string schemaInput = "{ meeting_at: null | date }";
        string input = "{ meeting_at: null }";

        var obj = ParseData.Parse(input);
        Assert.IsTrue(obj.Ok);
        var schema = ParseSchema.Parse(schemaInput);
        Assert.IsTrue(schema.Ok);
        var result = CheckData.Check(obj.Data!, schema.Data!);
        AssertCheckOk(result);
    }

    [TestMethod]
    public void BoolTypeValid()
    {
        string schemaInput = "{ is_active: bool }";
        string input = "{ is_active: true }";

        var obj = ParseData.Parse(input);
        Assert.IsTrue(obj.Ok);
        var schema = ParseSchema.Parse(schemaInput);
        Assert.IsTrue(schema.Ok);
        var result = CheckData.Check(obj.Data!, schema.Data!);
        AssertCheckOk(result);
    }

    [TestMethod]
    public void BoolTypeInvalid()
    {
        string schemaInput = "{ is_active: bool }";
        string input = "{ is_active: 1 }";

        var obj = ParseData.Parse(input);
        Assert.IsTrue(obj.Ok);
        var schema = ParseSchema.Parse(schemaInput);
        Assert.IsTrue(schema.Ok);
        var result = CheckData.Check(obj.Data!, schema.Data!);
        AssertCheckError(result, "'is_active' must be a boolean value");
    }

    [TestMethod]
    public void IntTypeValid()
    {
        string schemaInput = "{ age: int }";
        string input = "{ age: 25 }";

        var obj = ParseData.Parse(input);
        Assert.IsTrue(obj.Ok);
        var schema = ParseSchema.Parse(schemaInput);
        Assert.IsTrue(schema.Ok);
        var result = CheckData.Check(obj.Data!, schema.Data!);
        AssertCheckOk(result);
    }

    [TestMethod]
    public void IntTypeInvalid()
    {
        string schemaInput = "{ age: int }";
        string input = "{ age: 25.5 }";

        var obj = ParseData.Parse(input);
        Assert.IsTrue(obj.Ok);
        var schema = ParseSchema.Parse(schemaInput);
        Assert.IsTrue(schema.Ok);
        var result = CheckData.Check(obj.Data!, schema.Data!);
        AssertCheckError(result, "'age' must be an integer value");
    }

    [TestMethod]
    public void NumTypeValid()
    {
        string schemaInput = "{ rating: num }";
        string input = "{ rating: 4.5 }";

        var obj = ParseData.Parse(input);
        Assert.IsTrue(obj.Ok);
        var schema = ParseSchema.Parse(schemaInput);
        Assert.IsTrue(schema.Ok);
        var result = CheckData.Check(obj.Data!, schema.Data!);
        AssertCheckOk(result);
    }

    [TestMethod]
    public void NumTypeInvalid()
    {
        string schemaInput = "{ rating: num }";
        string input = "{ rating: \"excellent\" }";

        var obj = ParseData.Parse(input);
        Assert.IsTrue(obj.Ok);
        var schema = ParseSchema.Parse(schemaInput);
        Assert.IsTrue(schema.Ok);
        var result = CheckData.Check(obj.Data!, schema.Data!);
        AssertCheckError(result, "'rating' must be a number value");
    }

    [TestMethod]
    public void DateTypeValid()
    {
        string schemaInput = "{ birthday: date }";
        string input = "{ birthday: 2025-01-15 }";

        var obj = ParseData.Parse(input);
        Assert.IsTrue(obj.Ok);
        var schema = ParseSchema.Parse(schemaInput);
        Assert.IsTrue(schema.Ok);
        var result = CheckData.Check(obj.Data!, schema.Data!);
        AssertCheckOk(result);
    }

    [TestMethod]
    public void DateTypeInvalid()
    {
        string schemaInput = "{ birthday: date }";
        string input = "{ birthday: \"2025-01-15\" }";

        var obj = ParseData.Parse(input);
        Assert.IsTrue(obj.Ok);
        var schema = ParseSchema.Parse(schemaInput);
        Assert.IsTrue(schema.Ok);
        var result = CheckData.Check(obj.Data!, schema.Data!);
        AssertCheckError(result, "'birthday' must be a date value");
    }

    [TestMethod]
    public void StringTypeValid()
    {
        string schemaInput = "{ name: string }";
        string input = "{ name: \"Alice\" }";

        var obj = ParseData.Parse(input);
        Assert.IsTrue(obj.Ok);
        var schema = ParseSchema.Parse(schemaInput);
        Assert.IsTrue(schema.Ok);
        var result = CheckData.Check(obj.Data!, schema.Data!);
        AssertCheckOk(result);
    }

    [TestMethod]
    public void StringTypeInvalid()
    {
        string schemaInput = "{ name: string }";
        string input = "{ name: 123 }";

        var obj = ParseData.Parse(input);
        Assert.IsTrue(obj.Ok);
        var schema = ParseSchema.Parse(schemaInput);
        Assert.IsTrue(schema.Ok);
        var result = CheckData.Check(obj.Data!, schema.Data!);
        AssertCheckError(result, "'name' must be a string value");
    }

    [TestMethod]
    public void IntUnion()
    {
        string schemaInput = "{ age: 15 | 16 | 17 }";
        string input = "{ age: 22 }";

        var obj = ParseData.Parse(input);
        Assert.IsTrue(obj.Ok);
        var schema = ParseSchema.Parse(schemaInput);
        Assert.IsTrue(schema.Ok);
        var result = CheckData.Check(obj.Data!, schema.Data!);
        Assert.IsFalse(result.Ok);
        Assert.IsNotNull(result.Errors);
        Assert.HasCount(1, result.Errors!);
        StringAssert.Contains(result.Errors[0].Message, "must be");
    }

    [TestMethod]
    public void IntMinValidatorValid()
    {
        string schemaInput = "{ age: int min(18) }";
        string input = "{ age: 20 }";

        var obj = ParseData.Parse(input);
        Assert.IsTrue(obj.Ok);
        var schema = ParseSchema.Parse(schemaInput);
        Assert.IsTrue(schema.Ok);
        var result = CheckData.Check(obj.Data!, schema.Data!);
        AssertCheckOk(result);
    }

    [TestMethod]
    public void IntMinValidatorInvalid()
    {
        string schemaInput = "{ age: int min(18) }";
        string input = "{ age: 15 }";

        var obj = ParseData.Parse(input);
        Assert.IsTrue(obj.Ok);
        var schema = ParseSchema.Parse(schemaInput);
        Assert.IsTrue(schema.Ok);
        var result = CheckData.Check(obj.Data!, schema.Data!);
        AssertCheckError(result, "'age' must be at least 18");
    }

    [TestMethod]
    public void IntMaxValidatorValid()
    {
        string schemaInput = "{ age: int max(100) }";
        string input = "{ age: 50 }";

        var obj = ParseData.Parse(input);
        Assert.IsTrue(obj.Ok);
        var schema = ParseSchema.Parse(schemaInput);
        Assert.IsTrue(schema.Ok);
        var result = CheckData.Check(obj.Data!, schema.Data!);
        AssertCheckOk(result);
    }

    [TestMethod]
    public void IntMaxValidatorInvalid()
    {
        string schemaInput = "{ age: int max(100) }";
        string input = "{ age: 120 }";

        var obj = ParseData.Parse(input);
        Assert.IsTrue(obj.Ok);
        var schema = ParseSchema.Parse(schemaInput);
        Assert.IsTrue(schema.Ok);
        var result = CheckData.Check(obj.Data!, schema.Data!);
        AssertCheckError(result, "'age' cannot be more than 100");
    }

    [TestMethod]
    public void NumMinValidatorValid()
    {
        string schemaInput = "{ rating: num min(0) }";
        string input = "{ rating: 4.5 }";

        var obj = ParseData.Parse(input);
        Assert.IsTrue(obj.Ok);
        var schema = ParseSchema.Parse(schemaInput);
        Assert.IsTrue(schema.Ok);
        var result = CheckData.Check(obj.Data!, schema.Data!);
        AssertCheckOk(result);
    }

    [TestMethod]
    public void NumMinValidatorInvalid()
    {
        string schemaInput = "{ rating: num min(0) }";
        string input = "{ rating: -0.5 }";

        var obj = ParseData.Parse(input);
        Assert.IsTrue(obj.Ok);
        var schema = ParseSchema.Parse(schemaInput);
        Assert.IsTrue(schema.Ok);
        var result = CheckData.Check(obj.Data!, schema.Data!);
        AssertCheckError(result, "'rating' must be at least 0");
    }

    [TestMethod]
    public void NumMaxValidatorValid()
    {
        string schemaInput = "{ rating: num max(5) }";
        string input = "{ rating: 4.5 }";

        var obj = ParseData.Parse(input);
        Assert.IsTrue(obj.Ok);
        var schema = ParseSchema.Parse(schemaInput);
        Assert.IsTrue(schema.Ok);
        var result = CheckData.Check(obj.Data!, schema.Data!);
        AssertCheckOk(result);
    }

    [TestMethod]
    public void NumMaxValidatorInvalid()
    {
        string schemaInput = "{ rating: num max(5) }";
        string input = "{ rating: 5.5 }";

        var obj = ParseData.Parse(input);
        Assert.IsTrue(obj.Ok);
        var schema = ParseSchema.Parse(schemaInput);
        Assert.IsTrue(schema.Ok);
        var result = CheckData.Check(obj.Data!, schema.Data!);
        AssertCheckError(result, "'rating' cannot be more than 5");
    }

    [TestMethod]
    public void FieldNotFound()
    {
        string schemaInput = "{ name: string, age: int }";
        string input = "{ name: \"Alice\" }";

        var obj = ParseData.Parse(input);
        Assert.IsTrue(obj.Ok);
        var schema = ParseSchema.Parse(schemaInput);
        Assert.IsTrue(schema.Ok);
        var result = CheckData.Check(obj.Data!, schema.Data!);
        AssertCheckError(result, "Field not found: age");
    }

    [TestMethod]
    public void ArrayNotFound()
    {
        string schemaInput = "{ name: string, children: [string] }";
        string input = "{ name: \"Harold\" }";

        var obj = ParseData.Parse(input);
        Assert.IsTrue(obj.Ok);
        var schema = ParseSchema.Parse(schemaInput);
        Assert.IsTrue(schema.Ok);
        var result = CheckData.Check(obj.Data!, schema.Data!);
        AssertCheckError(result, "Field not found: children");
    }

    [TestMethod]
    public void ObjectNotFound()
    {
        string schemaInput = "{ name: string, passport: { number: string } }";
        string input = "{ name: \"Harold\" }";

        var obj = ParseData.Parse(input);
        Assert.IsTrue(obj.Ok);
        var schema = ParseSchema.Parse(schemaInput);
        Assert.IsTrue(schema.Ok);
        var result = CheckData.Check(obj.Data!, schema.Data!);
        AssertCheckError(result, "Field not found: passport");
    }

    [TestMethod]
    public void MultipleFieldsValid()
    {
        string schemaInput = "{ name: string, age: int, is_active: bool }";
        string input = "{ name: \"Alice\", age: 25, is_active: true }";

        var obj = ParseData.Parse(input);
        Assert.IsTrue(obj.Ok);
        var schema = ParseSchema.Parse(schemaInput);
        Assert.IsTrue(schema.Ok);
        var result = CheckData.Check(obj.Data!, schema.Data!);
        AssertCheckOk(result);
    }

    [TestMethod]
    public void MultipleFieldsInvalid()
    {
        string schemaInput = "{ name: string, age: int, is_active: bool }";
        string input = "{ name: \"Alice\", age: 25.5, is_active: \"yes\" }";

        var obj = ParseData.Parse(input);
        Assert.IsTrue(obj.Ok);
        var schema = ParseSchema.Parse(schemaInput);
        Assert.IsTrue(schema.Ok);
        var result = CheckData.Check(obj.Data!, schema.Data!);
        Assert.IsFalse(result.Ok);
        Assert.IsNotNull(result.Errors);
        Assert.HasCount(2, result.Errors!);
    }

    [TestMethod]
    public void ArrayValid()
    {
        string schemaInput = "{ fruits: [string] }";
        string input = "{ fruits: [\"apple\", \"banana\"] }";

        var obj = ParseData.Parse(input);
        Assert.IsTrue(obj.Ok);
        var schema = ParseSchema.Parse(schemaInput);
        Assert.IsTrue(schema.Ok);
        var result = CheckData.Check(obj.Data!, schema.Data!);
        AssertCheckOk(result);
    }

    [TestMethod]
    public void ArrayInvalid()
    {
        string schemaInput = "{ fruits: [string] }";
        string input = "{ fruits: [\"apple\", 5] }";

        var obj = ParseData.Parse(input);
        Assert.IsTrue(obj.Ok);
        var schema = ParseSchema.Parse(schemaInput);
        Assert.IsTrue(schema.Ok);
        var result = CheckData.Check(obj.Data!, schema.Data!);
        AssertCheckError(result, "'1' must be a string value");
    }

    [TestMethod]
    public void NestedObjectValid()
    {
        string schemaInput = "{ child: { is_active: bool } }";
        string input = "{ child: { is_active: true } }";

        var obj = ParseData.Parse(input);
        Assert.IsTrue(obj.Ok);
        var schema = ParseSchema.Parse(schemaInput);
        Assert.IsTrue(schema.Ok);
        var result = CheckData.Check(obj.Data!, schema.Data!);
        AssertCheckOk(result);
    }

    [TestMethod]
    public void NestedObjectInvalid()
    {
        string schemaInput = "{ child: { is_active: bool } }";
        string input = "{ child: { is_active: 1 } }";

        var obj = ParseData.Parse(input);
        Assert.IsTrue(obj.Ok);
        var schema = ParseSchema.Parse(schemaInput);
        Assert.IsTrue(schema.Ok);
        var result = CheckData.Check(obj.Data!, schema.Data!);
        AssertCheckError(result, "'is_active' must be a boolean value");
    }

    [TestMethod]
    public void NestedArrayValid()
    {
        string schemaInput = "{ points: [[ int ]] }";
        string input = "{ points: [[0, 1], [1, 2]] }";

        var obj = ParseData.Parse(input);
        Assert.IsTrue(obj.Ok);
        var schema = ParseSchema.Parse(schemaInput);
        Assert.IsTrue(schema.Ok);
        var result = CheckData.Check(obj.Data!, schema.Data!);
        AssertCheckOk(result);
    }

    [TestMethod]
    public void NestedArrayInvalid()
    {
        string schemaInput = "{ points: [[ int ]] }";
        string input = "{ points: [[0, 1], [\"one\", \"two\"]] }";

        var obj = ParseData.Parse(input);
        Assert.IsTrue(obj.Ok);
        var schema = ParseSchema.Parse(schemaInput);
        Assert.IsTrue(schema.Ok);
        var result = CheckData.Check(obj.Data!, schema.Data!);
        Assert.IsFalse(result.Ok);
        Assert.IsNotNull(result.Errors);
        Assert.HasCount(2, result.Errors!);
    }

    [TestMethod]
    public void ObjectInArrayValid()
    {
        string schemaInput = "{ children: [ { name: string, age: int }] }";
        string input = "{ children: [ { name: \"Child A\", age: 12 }] }";

        var obj = ParseData.Parse(input);
        Assert.IsTrue(obj.Ok);
        var schema = ParseSchema.Parse(schemaInput);
        Assert.IsTrue(schema.Ok);
        var result = CheckData.Check(obj.Data!, schema.Data!);
        AssertCheckOk(result);
    }

    [TestMethod]
    public void ObjectInArrayInvalid()
    {
        string schemaInput = "{ children: [ { name: string, age: int }] }";
        string input = "{ children: [ { name: 12, age: 12 }] }";

        var obj = ParseData.Parse(input);
        Assert.IsTrue(obj.Ok);
        var schema = ParseSchema.Parse(schemaInput);
        Assert.IsTrue(schema.Ok);
        var result = CheckData.Check(obj.Data!, schema.Data!);
        AssertCheckError(result, "'name' must be a string value");
    }

    [TestMethod]
    public void UnionTypeValidFirst()
    {
        string schemaInput = "{ value: string | int }";
        string input = "{ value: \"hello\" }";

        var obj = ParseData.Parse(input);
        Assert.IsTrue(obj.Ok);
        var schema = ParseSchema.Parse(schemaInput);
        Assert.IsTrue(schema.Ok);
        var result = CheckData.Check(obj.Data!, schema.Data!);
        AssertCheckOk(result);
    }

    [TestMethod]
    public void UnionTypeValidSecond()
    {
        string schemaInput = "{ value: string | int }";
        string input = "{ value: 42 }";

        var obj = ParseData.Parse(input);
        Assert.IsTrue(obj.Ok);
        var schema = ParseSchema.Parse(schemaInput);
        Assert.IsTrue(schema.Ok);
        var result = CheckData.Check(obj.Data!, schema.Data!);
        AssertCheckOk(result);
    }

    [TestMethod]
    public void UnionTypeInvalid()
    {
        string schemaInput = "{ value: string | int }";
        string input = "{ value: true }";

        var obj = ParseData.Parse(input);
        Assert.IsTrue(obj.Ok);
        var schema = ParseSchema.Parse(schemaInput);
        Assert.IsTrue(schema.Ok);
        var result = CheckData.Check(obj.Data!, schema.Data!);
        Assert.IsFalse(result.Ok);
        Assert.IsNotNull(result.Errors);
        Assert.HasCount(1, result.Errors!);
    }

    [TestMethod]
    public void UnionOfThreeTypesValid()
    {
        string schemaInput = "{ value: string | int | bool }";
        string input = "{ value: false }";

        var obj = ParseData.Parse(input);
        Assert.IsTrue(obj.Ok);
        var schema = ParseSchema.Parse(schemaInput);
        Assert.IsTrue(schema.Ok);
        var result = CheckData.Check(obj.Data!, schema.Data!);
        AssertCheckOk(result);
    }

    [TestMethod]
    public void UnionTypeInArrayValid()
    {
        string schemaInput = "{ values: [string | int] }";
        string input = "{ values: [\"hello\", 45] }";

        var obj = ParseData.Parse(input);
        Assert.IsTrue(obj.Ok);
        var schema = ParseSchema.Parse(schemaInput);
        Assert.IsTrue(schema.Ok);
        var result = CheckData.Check(obj.Data!, schema.Data!);
        AssertCheckOk(result);
    }

    [TestMethod]
    public void UnionTypeInArrayInvalid()
    {
        string schemaInput = "{ values: [ string | int ] }";
        string input = "{ values: [ true ] }";

        var obj = ParseData.Parse(input);
        Assert.IsTrue(obj.Ok);
        var schema = ParseSchema.Parse(schemaInput);
        Assert.IsTrue(schema.Ok);
        var result = CheckData.Check(obj.Data!, schema.Data!);
        Assert.IsFalse(result.Ok);
        Assert.IsNotNull(result.Errors);
        Assert.HasCount(1, result.Errors!);
    }

    [TestMethod]
    public void StringMinLengthValid()
    {
        string schemaInput = "{ name: string minlen(3) }";
        string input = "{ name: \"Alice\" }";

        var obj = ParseData.Parse(input);
        Assert.IsTrue(obj.Ok);
        var schema = ParseSchema.Parse(schemaInput);
        Assert.IsTrue(schema.Ok);
        var result = CheckData.Check(obj.Data!, schema.Data!);
        AssertCheckOk(result);
    }

    [TestMethod]
    public void StringMinLengthInvalid()
    {
        string schemaInput = "{ name: string minlen(3) }";
        string input = "{ name: \"Al\" }";

        var obj = ParseData.Parse(input);
        Assert.IsTrue(obj.Ok);
        var schema = ParseSchema.Parse(schemaInput);
        Assert.IsTrue(schema.Ok);
        var result = CheckData.Check(obj.Data!, schema.Data!);
        AssertCheckError(result, "'name' must be at least 3 characters");
    }

    [TestMethod]
    public void StringMaxLengthValid()
    {
        string schemaInput = "{ name: string maxlen(10) }";
        string input = "{ name: \"Alice\" }";

        var obj = ParseData.Parse(input);
        Assert.IsTrue(obj.Ok);
        var schema = ParseSchema.Parse(schemaInput);
        Assert.IsTrue(schema.Ok);
        var result = CheckData.Check(obj.Data!, schema.Data!);
        AssertCheckOk(result);
    }

    [TestMethod]
    public void StringMaxLengthInvalid()
    {
        string schemaInput = "{ name: string maxlen(5) }";
        string input = "{ name: \"Alexander\" }";

        var obj = ParseData.Parse(input);
        Assert.IsTrue(obj.Ok);
        var schema = ParseSchema.Parse(schemaInput);
        Assert.IsTrue(schema.Ok);
        var result = CheckData.Check(obj.Data!, schema.Data!);
        AssertCheckError(result, "'name' cannot be more than 5 characters");
    }

    [TestMethod]
    public void StringRegexValid()
    {
        string schemaInput = "{ email: string pattern(/^[^@]+@[^@]+$/) }";
        string input = "{ email: \"user@example.com\" }";

        var obj = ParseData.Parse(input);
        Assert.IsTrue(obj.Ok);
        var schema = ParseSchema.Parse(schemaInput);
        Assert.IsTrue(schema.Ok);
        var result = CheckData.Check(obj.Data!, schema.Data!);
        AssertCheckOk(result);
    }

    [TestMethod]
    public void StringRegexInvalid()
    {
        string schemaInput = "{ email: string pattern(/^[^@]+@[^@]+$/) }";
        string input = "{ email: \"not-an-email\" }";

        var obj = ParseData.Parse(input);
        Assert.IsTrue(obj.Ok);
        var schema = ParseSchema.Parse(schemaInput);
        Assert.IsTrue(schema.Ok);
        var result = CheckData.Check(obj.Data!, schema.Data!);
        AssertCheckError(result, "'email' doesn't match pattern '/^[^@]+@[^@]+$/'");
    }

    [TestMethod]
    public void DateMinValid()
    {
        string schemaInput = "{ birthday: date min(2000-01-01) }";
        string input = "{ birthday: 2005-06-15 }";

        var obj = ParseData.Parse(input);
        Assert.IsTrue(obj.Ok);
        var schema = ParseSchema.Parse(schemaInput);
        Assert.IsTrue(schema.Ok);
        var result = CheckData.Check(obj.Data!, schema.Data!);
        AssertCheckOk(result);
    }

    [TestMethod]
    public void DateMinInvalid()
    {
        string schemaInput = "{ birthday: date min(2000-01-01) }";
        string input = "{ birthday: 1995-06-15 }";

        var obj = ParseData.Parse(input);
        Assert.IsTrue(obj.Ok);
        var schema = ParseSchema.Parse(schemaInput);
        Assert.IsTrue(schema.Ok);
        var result = CheckData.Check(obj.Data!, schema.Data!);
        AssertCheckError(result, "'birthday' must be at least 2000-01-01");
    }

    [TestMethod]
    public void DateMaxValid()
    {
        string schemaInput = "{ birthday: date max(2025-01-01) }";
        string input = "{ birthday: 2020-06-15 }";

        var obj = ParseData.Parse(input);
        Assert.IsTrue(obj.Ok);
        var schema = ParseSchema.Parse(schemaInput);
        Assert.IsTrue(schema.Ok);
        var result = CheckData.Check(obj.Data!, schema.Data!);
        AssertCheckOk(result);
    }

    [TestMethod]
    public void DateMaxInvalid()
    {
        string schemaInput = "{ birthday: date max(2020-01-01) }";
        string input = "{ birthday: 2025-06-15 }";

        var obj = ParseData.Parse(input);
        Assert.IsTrue(obj.Ok);
        var schema = ParseSchema.Parse(schemaInput);
        Assert.IsTrue(schema.Ok);
        var result = CheckData.Check(obj.Data!, schema.Data!);
        AssertCheckError(result, "'birthday' cannot be after 2020-01-01");
    }

    [TestMethod]
    public void MixValidFirstAlternative()
    {
        string schemaInput = "{ @mix({ role: \"admin\", level: int } | { role: \"user\", plan: string }) }";
        string input = "{ role: \"admin\", level: 5 }";

        var obj = ParseData.Parse(input);
        Assert.IsTrue(obj.Ok);
        var schema = ParseSchema.Parse(schemaInput);
        Assert.IsTrue(schema.Ok);
        var result = CheckData.Check(obj.Data!, schema.Data!);
        AssertCheckOk(result);
    }

    [TestMethod]
    public void MixValidSecondAlternative()
    {
        string schemaInput = "{ @mix({ role: \"admin\", level: int } | { role: \"user\", plan: string }) }";
        string input = "{ role: \"user\", plan: \"premium\" }";

        var obj = ParseData.Parse(input);
        Assert.IsTrue(obj.Ok);
        var schema = ParseSchema.Parse(schemaInput);
        Assert.IsTrue(schema.Ok);
        var result = CheckData.Check(obj.Data!, schema.Data!);
        AssertCheckOk(result);
    }

    [TestMethod]
    public void MixInvalidAllAlternatives()
    {
        string schemaInput = "{ @mix({ role: \"admin\", level: int } | { role: \"user\", plan: string }) }";
        string input = "{ role: \"guest\", plan: \"free\" }";

        var obj = ParseData.Parse(input);
        Assert.IsTrue(obj.Ok);
        var schema = ParseSchema.Parse(schemaInput);
        Assert.IsTrue(schema.Ok);
        var result = CheckData.Check(obj.Data!, schema.Data!);
        Assert.IsFalse(result.Ok);
        Assert.IsNotNull(result.Errors);
        Assert.HasCount(1, result.Errors!);
        StringAssert.Contains(result.Errors[0].Message, "'role' must be 'admin'");
    }

    [TestMethod]
    public void DefInMixValid()
    {
        string schemaInput = "{ @def(admin): { role: \"admin\", level: int }, @mix(admin) }";
        string input = "{ role: \"admin\", level: 5 }";

        var obj = ParseData.Parse(input);
        Assert.IsTrue(obj.Ok);
        var schema = ParseSchema.Parse(schemaInput);
        Assert.IsTrue(schema.Ok);
        var result = CheckData.Check(obj.Data!, schema.Data!);
        AssertCheckOk(result);
    }

    [TestMethod]
    public void DefInMixInvalid()
    {
        string schemaInput = "{ @def(admin): { role: \"admin\", level: int }, @mix(admin) }";
        string input = "{ role: \"user\", level: 5 }";

        var obj = ParseData.Parse(input);
        Assert.IsTrue(obj.Ok);
        var schema = ParseSchema.Parse(schemaInput);
        Assert.IsTrue(schema.Ok);
        var result = CheckData.Check(obj.Data!, schema.Data!);
        Assert.IsFalse(result.Ok);
        Assert.IsNotNull(result.Errors);
        Assert.HasCount(1, result.Errors!);
        StringAssert.Contains(result.Errors[0].Message, "'role' must be 'admin'");
    }

    [TestMethod]
    public void PropsNoPatternValid()
    {
        string schemaInput = "{ @props(): string }";
        string input = "{ greeting: \"hello\", farewell: \"goodbye\" }";

        var obj = ParseData.Parse(input);
        Assert.IsTrue(obj.Ok);
        var schema = ParseSchema.Parse(schemaInput);
        Assert.IsTrue(schema.Ok);
        var result = CheckData.Check(obj.Data!, schema.Data!);
        AssertCheckOk(result);
    }

    [TestMethod]
    public void PropsNoPatternInvalidType()
    {
        string schemaInput = "{ @props(): string }";
        string input = "{ greeting: \"hello\", count: 5 }";

        var obj = ParseData.Parse(input);
        Assert.IsTrue(obj.Ok);
        var schema = ParseSchema.Parse(schemaInput);
        Assert.IsTrue(schema.Ok);
        var result = CheckData.Check(obj.Data!, schema.Data!);
        Assert.IsFalse(result.Ok);
    }

    [TestMethod]
    public void PropsWithPatternValid()
    {
        string schemaInput = "{ @props(/v\\d/): string }";
        string input = "{ v1: \"version 1\", v2: \"version 2\" }";

        var obj = ParseData.Parse(input);
        Assert.IsTrue(obj.Ok);
        var schema = ParseSchema.Parse(schemaInput);
        Assert.IsTrue(schema.Ok);
        var result = CheckData.Check(obj.Data!, schema.Data!);
        AssertCheckOk(result);
    }

    [TestMethod]
    public void PropsWithPatternInvalidName()
    {
        string schemaInput = "{ @props(/v\\d/): string }";
        string input = "{ version1: \"version 1\", v2: \"version 2\" }";

        var obj = ParseData.Parse(input);
        Assert.IsTrue(obj.Ok);
        var schema = ParseSchema.Parse(schemaInput);
        Assert.IsTrue(schema.Ok);
        var result = CheckData.Check(obj.Data!, schema.Data!);
        AssertCheckError(result, "'version1' name doesn't match pattern '/v\\d/'");
    }

    [TestMethod]
    public void PropsWithPatternInvalidType()
    {
        string schemaInput = "{ @props(/v\\d/): int }";
        string input = "{ v1: \"version 1\", v2: \"version 2\" }";

        var obj = ParseData.Parse(input);
        Assert.IsTrue(obj.Ok);
        var schema = ParseSchema.Parse(schemaInput);
        Assert.IsTrue(schema.Ok);
        var result = CheckData.Check(obj.Data!, schema.Data!);
        Assert.IsFalse(result.Ok);
        Assert.IsNotNull(result.Errors);
        Assert.HasCount(2, result.Errors!);
    }

    [TestMethod]
    public void MultipleValidatorsOnInt()
    {
        string schemaInput = "{ age: int min(18) max(100) }";
        string input = "{ age: 25 }";

        var obj = ParseData.Parse(input);
        Assert.IsTrue(obj.Ok);
        var schema = ParseSchema.Parse(schemaInput);
        Assert.IsTrue(schema.Ok);
        var result = CheckData.Check(obj.Data!, schema.Data!);
        AssertCheckOk(result);
    }

    [TestMethod]
    public void MultipleValidatorsOnIntInvalidMin()
    {
        string schemaInput = "{ age: int min(18) max(100) }";
        string input = "{ age: 15 }";

        var obj = ParseData.Parse(input);
        Assert.IsTrue(obj.Ok);
        var schema = ParseSchema.Parse(schemaInput);
        Assert.IsTrue(schema.Ok);
        var result = CheckData.Check(obj.Data!, schema.Data!);
        AssertCheckError(result, "'age' must be at least 18");
    }

    [TestMethod]
    public void MultipleValidatorsOnIntInvalidMax()
    {
        string schemaInput = "{ age: int min(18) max(100) }";
        string input = "{ age: 120 }";

        var obj = ParseData.Parse(input);
        Assert.IsTrue(obj.Ok);
        var schema = ParseSchema.Parse(schemaInput);
        Assert.IsTrue(schema.Ok);
        var result = CheckData.Check(obj.Data!, schema.Data!);
        AssertCheckError(result, "'age' cannot be more than 100");
    }

    [TestMethod]
    public void MultipleValidatorsOnString()
    {
        string schemaInput = "{ username: string minlen(3) maxlen(20) pattern(/^[a-z]+$/) }";
        string input = "{ username: \"alice\" }";

        var obj = ParseData.Parse(input);
        Assert.IsTrue(obj.Ok);
        var schema = ParseSchema.Parse(schemaInput);
        Assert.IsTrue(schema.Ok);
        var result = CheckData.Check(obj.Data!, schema.Data!);
        AssertCheckOk(result);
    }

    [TestMethod]
    public void MultipleValidatorsOnStringInvalidMin()
    {
        string schemaInput = "{ username: string minlen(3) maxlen(20) pattern(/^[a-z]+$/) }";
        string input = "{ username: \"al\" }";

        var obj = ParseData.Parse(input);
        Assert.IsTrue(obj.Ok);
        var schema = ParseSchema.Parse(schemaInput);
        Assert.IsTrue(schema.Ok);
        var result = CheckData.Check(obj.Data!, schema.Data!);
        AssertCheckError(result, "'username' must be at least 3 characters");
    }

    [TestMethod]
    public void MultipleValidatorsOnStringInvalidRegex()
    {
        string schemaInput = "{ username: string minlen(3) maxlen(20) pattern(/^[a-z]+$/) }";
        string input = "{ username: \"Alice123\" }";

        var obj = ParseData.Parse(input);
        Assert.IsTrue(obj.Ok);
        var schema = ParseSchema.Parse(schemaInput);
        Assert.IsTrue(schema.Ok);
        var result = CheckData.Check(obj.Data!, schema.Data!);
        Assert.IsFalse(result.Ok);
        Assert.IsNotNull(result.Errors);
        Assert.HasCount(1, result.Errors!);
        StringAssert.Contains(result.Errors[0].Message, "doesn't match pattern");
    }

    [TestMethod]
    public void BoolFixedValueValid()
    {
        string schemaInput = "{ accepted: true }";
        string input = "{ accepted: true }";

        var obj = ParseData.Parse(input);
        Assert.IsTrue(obj.Ok);
        var schema = ParseSchema.Parse(schemaInput);
        Assert.IsTrue(schema.Ok);
        var result = CheckData.Check(obj.Data!, schema.Data!);
        AssertCheckOk(result);
    }

    [TestMethod]
    public void BoolFixedValueInvalid()
    {
        string schemaInput = "{ accepted: true }";
        string input = "{ accepted: false }";

        var obj = ParseData.Parse(input);
        Assert.IsTrue(obj.Ok);
        var schema = ParseSchema.Parse(schemaInput);
        Assert.IsTrue(schema.Ok);
        var result = CheckData.Check(obj.Data!, schema.Data!);
        AssertCheckError(result, "'accepted' must be 'true'");
    }

    [TestMethod]
    public void EmptyArrayValid()
    {
        string schemaInput = "{ items: [string] }";
        string input = "{ items: [] }";

        var obj = ParseData.Parse(input);
        Assert.IsTrue(obj.Ok);
        var schema = ParseSchema.Parse(schemaInput);
        Assert.IsTrue(schema.Ok);
        var result = CheckData.Check(obj.Data!, schema.Data!);
        AssertCheckOk(result);
    }

    [TestMethod]
    public void EmptyObjectValid()
    {
        string schemaInput = "{ data: {} }";
        string input = "{ data: {} }";

        var obj = ParseData.Parse(input);
        Assert.IsTrue(obj.Ok);
        var schema = ParseSchema.Parse(schemaInput);
        Assert.IsTrue(schema.Ok);
        var result = CheckData.Check(obj.Data!, schema.Data!);
        AssertCheckOk(result);
    }

    [TestMethod]
    public void DeeplyNestedValid()
    {
        string schemaInput = "{ data: { user: { profile: { name: string, age: int } } } }";
        string input = "{ data: { user: { profile: { name: \"Alice\", age: 30 } } } }";

        var obj = ParseData.Parse(input);
        Assert.IsTrue(obj.Ok);
        var schema = ParseSchema.Parse(schemaInput);
        Assert.IsTrue(schema.Ok);
        var result = CheckData.Check(obj.Data!, schema.Data!);
        AssertCheckOk(result);
    }

    [TestMethod]
    public void DeeplyNestedInvalid()
    {
        string schemaInput = "{ data: { user: { profile: { name: string, age: int } } } }";
        string input = "{ data: { user: { profile: { name: 123, age: 30 } } } }";

        var obj = ParseData.Parse(input);
        Assert.IsTrue(obj.Ok);
        var schema = ParseSchema.Parse(schemaInput);
        Assert.IsTrue(schema.Ok);
        var result = CheckData.Check(obj.Data!, schema.Data!);
        AssertCheckError(result, "'name' must be a string value");
    }

    [TestMethod]
    public void ArrayWithNestedObjectsValid()
    {
        string schemaInput = "{ users: [ { name: string, age: int } ] }";
        string input = "{ users: [ { name: \"Alice\", age: 30 }, { name: \"Bob\", age: 25 } ] }";

        var obj = ParseData.Parse(input);
        Assert.IsTrue(obj.Ok);
        var schema = ParseSchema.Parse(schemaInput);
        Assert.IsTrue(schema.Ok);
        var result = CheckData.Check(obj.Data!, schema.Data!);
        AssertCheckOk(result);
    }

    [TestMethod]
    public void ArrayWithNestedObjectsPartialInvalid()
    {
        string schemaInput = "{ users: [ { name: string, age: int } ] }";
        string input = "{ users: [ { name: \"Alice\", age: 30 }, { name: 45, age: 25 } ] }";

        var obj = ParseData.Parse(input);
        Assert.IsTrue(obj.Ok);
        var schema = ParseSchema.Parse(schemaInput);
        Assert.IsTrue(schema.Ok);
        var result = CheckData.Check(obj.Data!, schema.Data!);
        AssertCheckError(result, "'name' must be a string value");
    }

    [TestMethod]
    public void UnionWithArrayValid()
    {
        string schemaInput = "{ items: string | [string] }";
        string input = "{ items: [\"a\", \"b\"] }";

        var obj = ParseData.Parse(input);
        Assert.IsTrue(obj.Ok);
        var schema = ParseSchema.Parse(schemaInput);
        Assert.IsTrue(schema.Ok);
        var result = CheckData.Check(obj.Data!, schema.Data!);
        AssertCheckOk(result);
    }

    [TestMethod]
    public void UnionWithArrayInvalid()
    {
        string schemaInput = "{ items: string | [string] }";
        string input = "{ items: [\"a\", 5] }";

        var obj = ParseData.Parse(input);
        Assert.IsTrue(obj.Ok);
        var schema = ParseSchema.Parse(schemaInput);
        Assert.IsTrue(schema.Ok);
        var result = CheckData.Check(obj.Data!, schema.Data!);
        Assert.IsFalse(result.Ok);
        Assert.IsNotNull(result.Errors);
        Assert.HasCount(1, result.Errors!);
    }

    [TestMethod]
    public void UnionWithObjectValid()
    {
        string schemaInput = "{ item: { name: string } | string }";
        string input = "{ item: { name: \"a\" } }";

        var obj = ParseData.Parse(input);
        Assert.IsTrue(obj.Ok);
        var schema = ParseSchema.Parse(schemaInput);
        Assert.IsTrue(schema.Ok);
        var result = CheckData.Check(obj.Data!, schema.Data!);
        AssertCheckOk(result);
    }

    [TestMethod]
    public void UnionWithObjectInvalid()
    {
        string schemaInput = "{ item: { name: string } | string }";
        string input = "{ item: { name: 5 } }";

        var obj = ParseData.Parse(input);
        Assert.IsTrue(obj.Ok);
        var schema = ParseSchema.Parse(schemaInput);
        Assert.IsTrue(schema.Ok);
        var result = CheckData.Check(obj.Data!, schema.Data!);
        Assert.IsFalse(result.Ok);
        Assert.IsNotNull(result.Errors);
        Assert.HasCount(1, result.Errors!);
    }

    [TestMethod]
    [Ignore("Array validators not yet implemented in schema parser")]
    public void ArrayMinlenValid()
    {
        string schemaInput = "{ guesses: [ num ] minlen(3) }";
        string input = "{ guesses: [ 8, 3, 4, 6 ] }";

        var obj = ParseData.Parse(input);
        Assert.IsTrue(obj.Ok);
        var schema = ParseSchema.Parse(schemaInput);
        Assert.IsTrue(schema.Ok);
        var result = CheckData.Check(obj.Data!, schema.Data!);
        AssertCheckOk(result);
    }

    [TestMethod]
    [Ignore("Array validators not yet implemented in schema parser")]
    public void ArrayMinlenInvalid()
    {
        string schemaInput = "{ guesses: [ num ] minlen(3) }";
        string input = "{ guesses: [ 8, 3 ] }";

        var obj = ParseData.Parse(input);
        Assert.IsTrue(obj.Ok);
        var schema = ParseSchema.Parse(schemaInput);
        Assert.IsTrue(schema.Ok);
        var result = CheckData.Check(obj.Data!, schema.Data!);
        AssertCheckError(result, "'guesses' must contain at least 3 items");
    }

    [TestMethod]
    [Ignore("Array validators not yet implemented in schema parser")]
    public void ArrayMaxlenValid()
    {
        string schemaInput = "{ guesses: [ num ] maxlen(3) }";
        string input = "{ guesses: [ 8, 3 ] }";

        var obj = ParseData.Parse(input);
        Assert.IsTrue(obj.Ok);
        var schema = ParseSchema.Parse(schemaInput);
        Assert.IsTrue(schema.Ok);
        var result = CheckData.Check(obj.Data!, schema.Data!);
        AssertCheckOk(result);
    }

    [TestMethod]
    [Ignore("Array validators not yet implemented in schema parser")]
    public void ArrayMaxlenInvalid()
    {
        string schemaInput = "{ guesses: [ num ] maxlen(3) }";
        string input = "{ guesses: [ 8, 3, 4, 6 ] }";

        var obj = ParseData.Parse(input);
        Assert.IsTrue(obj.Ok);
        var schema = ParseSchema.Parse(schemaInput);
        Assert.IsTrue(schema.Ok);
        var result = CheckData.Check(obj.Data!, schema.Data!);
        AssertCheckError(result, "'guesses' cannot contain more than 3 items");
    }

    [TestMethod]
    [Ignore("Array validators not yet implemented in schema parser")]
    public void ArrayUniqueValid()
    {
        string schemaInput = "{ guesses: [ num ] unique }";
        string input = "{ guesses: [ 8, 3 ] }";

        var obj = ParseData.Parse(input);
        Assert.IsTrue(obj.Ok);
        var schema = ParseSchema.Parse(schemaInput);
        Assert.IsTrue(schema.Ok);
        var result = CheckData.Check(obj.Data!, schema.Data!);
        AssertCheckOk(result);
    }

    [TestMethod]
    [Ignore("Array validators not yet implemented in schema parser")]
    public void ArrayUniqueInvalid()
    {
        string schemaInput = "{ guesses: [ num ] unique }";
        string input = "{ guesses: [ 8, 3, 4, 3 ] }";

        var obj = ParseData.Parse(input);
        Assert.IsTrue(obj.Ok);
        var schema = ParseSchema.Parse(schemaInput);
        Assert.IsTrue(schema.Ok);
        var result = CheckData.Check(obj.Data!, schema.Data!);
        AssertCheckError(result, "'guesses' value '3' is not unique");
    }
}
