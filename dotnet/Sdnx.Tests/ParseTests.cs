using Microsoft.VisualStudio.TestTools.UnitTesting;
using Sdnx.Core;

namespace Sdnx.Tests;

[TestClass]
public class ParseTests
{
    [TestMethod]
    public void BasicTest()
    {
        string input = @"{
	active: true,
	name: ""Darren"",
	age: 25,
	rating: 4.2,
	# strings can be multiline
	skills: ""
		very good at
		  - reading
		  - writing
		  - selling"",
	started_at: 2025-01-01,
	meeting_at: 2026-01-01T10:00,
	children: [{
		name: ""Rocket"",
		age: 5,
	}],
	has_license: true,
	license_num: ""112"",
}";

        var result = ParseData.Parse(input);
        Assert.IsTrue(result.Ok, result.Ok ? "" : string.Join("\n", result.Errors?.Select(e => e.Message) ?? new List<string>()));
        Assert.IsNotNull(result.Data);
        Assert.HasCount(10, result.Data!);

        // Test with spaced input
        string spacedInput = TestHelpers.Space(input).Replace("10 : 00", "10:00");
        var spacedResult = ParseData.Parse(spacedInput);
        Assert.IsTrue(spacedResult.Ok, spacedResult.Ok ? "" : string.Join("\n", spacedResult.Errors?.Select(e => e.Message) ?? new List<string>()));
        Assert.IsNotNull(spacedResult.Data);

        // Test with unspaced input
        string unspacedInput = TestHelpers.Unspace(input);
        var unspacedResult = ParseData.Parse(unspacedInput);
        Assert.IsTrue(unspacedResult.Ok, unspacedResult.Ok ? "" : string.Join("\n", unspacedResult.Errors?.Select(e => e.Message) ?? new List<string>()));
        Assert.IsNotNull(unspacedResult.Data);
    }

    [TestMethod]
    public void EmptyObject()
    {
        string input = "{}";

        var result = ParseData.Parse(input);
        Assert.IsTrue(result.Ok);
        Assert.IsNotNull(result.Data);
        Assert.HasCount(0, result.Data!);

        // Test with spaced input
        string spacedInput = TestHelpers.Space(input);
        var spacedResult = ParseData.Parse(spacedInput);
        Assert.IsTrue(spacedResult.Ok);

        // Test with unspaced input
        string unspacedInput = TestHelpers.Unspace(input);
        var unspacedResult = ParseData.Parse(unspacedInput);
        Assert.IsTrue(unspacedResult.Ok);
    }

    [TestMethod]
    public void NegativeNumbers()
    {
        string input = "{temp: -10, balance: -3.14}";

        var result = ParseData.Parse(input);
        Assert.IsTrue(result.Ok);
        Assert.IsNotNull(result.Data);
        Assert.AreEqual(-10, result.Data!["temp"]);
        Assert.AreEqual(-3.14, result.Data["balance"]);

        // Test with spaced input
        string spacedInput = TestHelpers.Space(input);
        var spacedResult = ParseData.Parse(spacedInput);
        Assert.IsTrue(spacedResult.Ok);

        // Test with unspaced input
        string unspacedInput = TestHelpers.Unspace(input);
        var unspacedResult = ParseData.Parse(unspacedInput);
        Assert.IsTrue(unspacedResult.Ok);
    }

    [TestMethod]
    public void PositiveNumbersWithPlusPrefix()
    {
        string input = "{count: +42, score: +4.5}";

        var result = ParseData.Parse(input);
        Assert.IsTrue(result.Ok);
        Assert.IsNotNull(result.Data);
        Assert.AreEqual(42, result.Data!["count"]);
        Assert.AreEqual(4.5, result.Data["score"]);

        // Test with spaced input
        string spacedInput = TestHelpers.Space(input);
        var spacedResult = ParseData.Parse(spacedInput);
        Assert.IsTrue(spacedResult.Ok);

        // Test with unspaced input
        string unspacedInput = TestHelpers.Unspace(input);
        var unspacedResult = ParseData.Parse(unspacedInput);
        Assert.IsTrue(unspacedResult.Ok);
    }

    [TestMethod]
    public void HexadecimalIntegers()
    {
        string input = "{color: 0xFF00FF, alpha: 0xAB}";

        var result = ParseData.Parse(input);
        Assert.IsTrue(result.Ok);
        Assert.IsNotNull(result.Data);
        Assert.AreEqual(0xFF00FF, result.Data!["color"]);
        Assert.AreEqual(0xAB, result.Data["alpha"]);

        // Test with spaced input
        string spacedInput = TestHelpers.Space(input);
        var spacedResult = ParseData.Parse(spacedInput);
        Assert.IsTrue(spacedResult.Ok);

        // Test with unspaced input
        string unspacedInput = TestHelpers.Unspace(input);
        var unspacedResult = ParseData.Parse(unspacedInput);
        Assert.IsTrue(unspacedResult.Ok);
    }

    [TestMethod]
    public void ScientificNotation()
    {
        string input = "{distance: 1.5e10, tiny: 1.5e-5}";

        var result = ParseData.Parse(input);
        Assert.IsTrue(result.Ok);
        Assert.IsNotNull(result.Data);
        Assert.AreEqual(1.5e10, result.Data!["distance"]);
        Assert.AreEqual(1.5e-5, result.Data["tiny"]);

        // Test with spaced input
        string spacedInput = TestHelpers.Space(input);
        var spacedResult = ParseData.Parse(spacedInput);
        Assert.IsTrue(spacedResult.Ok);

        // Test with unspaced input
        string unspacedInput = TestHelpers.Unspace(input);
        var unspacedResult = ParseData.Parse(unspacedInput);
        Assert.IsTrue(unspacedResult.Ok);
    }

    [TestMethod]
    public void NumbersWithUnderscoreSeparators()
    {
        string input = "{population: 1_000_000, big_number: 1_000_000.123}";

        var result = ParseData.Parse(input);
        Assert.IsTrue(result.Ok);
        Assert.IsNotNull(result.Data);
        Assert.AreEqual(1000000, result.Data!["population"]);
        Assert.AreEqual(1000000.123, result.Data["big_number"]);

        // Test with spaced input
        string spacedInput = TestHelpers.Space(input);
        var spacedResult = ParseData.Parse(spacedInput);
        Assert.IsTrue(spacedResult.Ok);

        // Test with unspaced input
        string unspacedInput = TestHelpers.Unspace(input);
        var unspacedResult = ParseData.Parse(unspacedInput);
        Assert.IsTrue(unspacedResult.Ok);
    }

    [TestMethod]
    public void StringWithEscapedQuotes()
    {
        // SDN uses "" to escape quotes within strings
        string input = "{quote: \"She said \"\"Hello\"\"\"}";

        var result = ParseData.Parse(input);
        Assert.IsTrue(result.Ok, result.Ok ? "" : string.Join("\n", result.Errors?.Select(e => e.Message) ?? new List<string>()));
        Assert.IsNotNull(result.Data);
        Assert.AreEqual("She said \"Hello\"", result.Data!["quote"]);

        // Test with spaced input
        string spacedInput = TestHelpers.Space(input);
        var spacedResult = ParseData.Parse(spacedInput);
        Assert.IsTrue(spacedResult.Ok, spacedResult.Ok ? "" : string.Join("\n", spacedResult.Errors?.Select(e => e.Message) ?? new List<string>()));

        // Test with unspaced input
        string unspacedInput = TestHelpers.Unspace(input);
        var unspacedResult = ParseData.Parse(unspacedInput);
        Assert.IsTrue(unspacedResult.Ok, unspacedResult.Ok ? "" : string.Join("\n", unspacedResult.Errors?.Select(e => e.Message) ?? new List<string>()));
    }

    [TestMethod]
    public void MultilineString()
    {
        string input = @"{
	# strings can be multiline
	skills: ""
		very good at
		  - reading
		  - writing
		  - selling"",
}";

        var result = ParseData.Parse(input);
        Assert.IsTrue(result.Ok);
        Assert.IsNotNull(result.Data);
        Assert.IsTrue(result.Data!.ContainsKey("skills"));

        // Test with spaced input
        string spacedInput = TestHelpers.Space(input);
        var spacedResult = ParseData.Parse(spacedInput);
        Assert.IsTrue(spacedResult.Ok);

        // Test with unspaced input
        string unspacedInput = TestHelpers.Unspace(input);
        var unspacedResult = ParseData.Parse(unspacedInput);
        Assert.IsTrue(unspacedResult.Ok);
    }

    [TestMethod]
    public void QuotedFieldName()
    {
        string input = @"{""field-with-dash"": ""value"", ""with spaces"": ""test""}";

        var result = ParseData.Parse(input);
        Assert.IsTrue(result.Ok);
        Assert.IsNotNull(result.Data);
        Assert.IsTrue(result.Data!.ContainsKey("\"field-with-dash\""));
        Assert.IsTrue(result.Data.ContainsKey("\"with spaces\""));

        // Test with spaced input
        string spacedInput = TestHelpers.Space(input);
        var spacedResult = ParseData.Parse(spacedInput);
        Assert.IsTrue(spacedResult.Ok);

        // Test with unspaced input
        string unspacedInput = TestHelpers.Unspace(input);
        var unspacedResult = ParseData.Parse(unspacedInput);
        Assert.IsTrue(unspacedResult.Ok);
    }

    [TestMethod]
    public void FieldNamesWithNumbersAndUnderscores()
    {
        string input = @"{field1: ""a"", field_2: ""b"", _private: ""c"", field_3_name: ""d""}";

        var result = ParseData.Parse(input);
        Assert.IsTrue(result.Ok);
        Assert.IsNotNull(result.Data);
        Assert.HasCount(4, result.Data!);

        // Test with spaced input
        string spacedInput = TestHelpers.Space(input);
        var spacedResult = ParseData.Parse(spacedInput);
        Assert.IsTrue(spacedResult.Ok);

        // Test with unspaced input
        string unspacedInput = TestHelpers.Unspace(input);
        var unspacedResult = ParseData.Parse(unspacedInput);
        Assert.IsTrue(unspacedResult.Ok);
    }

    [TestMethod]
    public void TimeOnly()
    {
        string input = "{meeting_time: 14:30, alarm_time: 07:15:30}";

        var result = ParseData.Parse(input);
        Assert.IsTrue(result.Ok);
        Assert.IsNotNull(result.Data);
        Assert.IsInstanceOfType(result.Data!["meeting_time"], typeof(DateTime));
        Assert.IsInstanceOfType(result.Data["alarm_time"], typeof(DateTime));

        // Test with spaced input
        string spacedInput = TestHelpers.Space(input).Replace("14 : 30", "14:30").Replace("07 : 15 : 30", "07:15:30");
        var spacedResult = ParseData.Parse(spacedInput);
        Assert.IsTrue(spacedResult.Ok);

        // Test with unspaced input
        string unspacedInput = TestHelpers.Unspace(input);
        var unspacedResult = ParseData.Parse(unspacedInput);
        Assert.IsTrue(unspacedResult.Ok);
    }

    [TestMethod]
    public void DatetimeWithTimezoneOffset()
    {
        string input = "{event_time: 2025-01-15T14:30+02:00}";

        var result = ParseData.Parse(input);
        Assert.IsTrue(result.Ok);
        Assert.IsNotNull(result.Data);
        Assert.IsInstanceOfType(result.Data!["event_time"], typeof(DateTime));

        // Test with spaced input
        string spacedInput = TestHelpers.Space(input).Replace("14 : 30+02 : 00", "14:30+02:00");
        var spacedResult = ParseData.Parse(spacedInput);
        Assert.IsTrue(spacedResult.Ok);

        // Test with unspaced input
        string unspacedInput = TestHelpers.Unspace(input);
        var unspacedResult = ParseData.Parse(unspacedInput);
        Assert.IsTrue(unspacedResult.Ok);
    }

    [TestMethod]
    public void MultipleConsecutiveComments()
    {
        string input = @"# First comment
# Second comment
# Third comment
{
	name: ""Alice""
}";

        var result = ParseData.Parse(input);
        Assert.IsTrue(result.Ok);
        Assert.IsNotNull(result.Data);
        Assert.AreEqual("Alice", result.Data!["name"]);

        // Test with spaced input
        string spacedInput = TestHelpers.Space(input);
        var spacedResult = ParseData.Parse(spacedInput);
        Assert.IsTrue(spacedResult.Ok);

        // Test with unspaced input
        string unspacedInput = TestHelpers.Unspace(input);
        var unspacedResult = ParseData.Parse(unspacedInput);
        Assert.IsTrue(unspacedResult.Ok);
    }

    [TestMethod]
    public void InlineComments()
    {
        string input = @"{name: ""Bob"", # inline comment
age: 30}";

        var result = ParseData.Parse(input);
        Assert.IsTrue(result.Ok);
        Assert.IsNotNull(result.Data);
        Assert.AreEqual("Bob", result.Data!["name"]);
        Assert.AreEqual(30, result.Data["age"]);

        // Test with spaced input
        string spacedInput = TestHelpers.Space(input);
        var spacedResult = ParseData.Parse(spacedInput);
        Assert.IsTrue(spacedResult.Ok);

        // Test with unspaced input
        string unspacedInput = TestHelpers.Unspace(input);
        var unspacedResult = ParseData.Parse(unspacedInput);
        Assert.IsTrue(unspacedResult.Ok);
    }

    [TestMethod]
    public void CommentsBetweenFields()
    {
        string input = @"{name: ""Alice"", # name field
# separator
age: 25 # age field
}";

        var result = ParseData.Parse(input);
        Assert.IsTrue(result.Ok);
        Assert.IsNotNull(result.Data);
        Assert.AreEqual("Alice", result.Data!["name"]);
        Assert.AreEqual(25, result.Data["age"]);

        // Test with spaced input
        string spacedInput = TestHelpers.Space(input);
        var spacedResult = ParseData.Parse(spacedInput);
        Assert.IsTrue(spacedResult.Ok);

        // Test with unspaced input
        string unspacedInput = TestHelpers.Unspace(input);
        var unspacedResult = ParseData.Parse(unspacedInput);
        Assert.IsTrue(unspacedResult.Ok);
    }

    [TestMethod]
    public void DeeplyNestedStructures()
    {
        string input = @"{
	level1: {
		level2: {
			level3: {
				deep: ""value""
			}
		}
	},
	nested_array: [[[1, 2], [3, 4]], [[5, 6], [7, 8]]]
}";

        var result = ParseData.Parse(input);
        Assert.IsTrue(result.Ok);
        Assert.IsNotNull(result.Data);
        Assert.IsTrue(result.Data!.ContainsKey("level1"));
        Assert.IsTrue(result.Data.ContainsKey("nested_array"));

        // Test with spaced input
        string spacedInput = TestHelpers.Space(input);
        var spacedResult = ParseData.Parse(spacedInput);
        Assert.IsTrue(spacedResult.Ok);

        // Test with unspaced input
        string unspacedInput = TestHelpers.Unspace(input);
        var unspacedResult = ParseData.Parse(unspacedInput);
        Assert.IsTrue(unspacedResult.Ok);
    }

    [TestMethod]
    public void SingleFieldObject()
    {
        string input = @"{name: ""Alice""}";

        var result = ParseData.Parse(input);
        Assert.IsTrue(result.Ok);
        Assert.IsNotNull(result.Data);
        Assert.HasCount(1, result.Data!);
        Assert.AreEqual("Alice", result.Data["name"]);

        // Test with spaced input
        string spacedInput = TestHelpers.Space(input);
        var spacedResult = ParseData.Parse(spacedInput);
        Assert.IsTrue(spacedResult.Ok);

        // Test with unspaced input
        string unspacedInput = TestHelpers.Unspace(input);
        var unspacedResult = ParseData.Parse(unspacedInput);
        Assert.IsTrue(unspacedResult.Ok);
    }

    [TestMethod]
    public void LargeDataset()
    {
        string input = @"{
	users: [
		{ id: 1, name: ""Alice"", active: true },
		{ id: 2, name: ""Bob"", active: false },
		{ id: 3, name: ""Charlie"", active: true },
		{ id: 4, name: ""Diana"", active: true },
		{ id: 5, name: ""Eve"", active: false }
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
		tags: [""production"", ""api"", ""v1""]
	}
}";

        var result = ParseData.Parse(input);
        Assert.IsTrue(result.Ok);
        Assert.IsNotNull(result.Data);
        Assert.IsTrue(result.Data!.ContainsKey("users"));
        Assert.IsTrue(result.Data.ContainsKey("stats"));
        Assert.IsTrue(result.Data.ContainsKey("metadata"));

        var users = result.Data["users"] as List<object?>;
        Assert.IsNotNull(users);
        Assert.HasCount(5, users!);

        // Test with spaced input
        string spacedInput = TestHelpers.Space(input).Replace("10 : 30 : 00", "10:30:00");
        var spacedResult = ParseData.Parse(spacedInput);
        Assert.IsTrue(spacedResult.Ok);

        // Test with unspaced input
        string unspacedInput = TestHelpers.Unspace(input);
        var unspacedResult = ParseData.Parse(unspacedInput);
        Assert.IsTrue(unspacedResult.Ok);
    }
}
