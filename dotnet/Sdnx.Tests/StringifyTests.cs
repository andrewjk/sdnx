using Microsoft.VisualStudio.TestTools.UnitTesting;
using Sdnx.Core;
using System.Text.RegularExpressions;

namespace Sdnx.Tests;

[TestClass]
public class StringifyTests
{
    [TestMethod]
    public void BasicObject()
    {
        var input = new Dictionary<string, object?>
        {
            ["name"] = "Alice",
            ["age"] = 25,
            ["active"] = true,
            ["rating"] = 4.5,
            ["balance"] = -100,
            ["tags"] = new List<object?> { "developer", "writer" }
        };

        var result = Stringify.Convert(input);
        var expected = @"{
	name: ""Alice"",
	age: 25,
	active: true,
	rating: 4.5,
	balance: -100,
	tags: [
		""developer"",
		""writer""
	]
}";

        Assert.AreEqual(expected, result);

        var parsed = ParseData.Parse(result);
        Assert.IsTrue(parsed.Ok);
    }

    [TestMethod]
    public void EmptyObject()
    {
        var input = new Dictionary<string, object?>();
        var result = Stringify.Convert(input);
        var expected = "{\n}";
        Assert.AreEqual(expected, result);

        var parsed = ParseData.Parse(result);
        Assert.IsTrue(parsed.Ok);
    }

    [TestMethod]
    public void EmptyArray()
    {
        var input = new Dictionary<string, object?>
        {
            ["items"] = new List<object?>()
        };
        var result = Stringify.Convert(input);
        var expected = @"{
	items: [
	]
}";

        Assert.AreEqual(expected, result);

        var parsed = ParseData.Parse(result);
        Assert.IsTrue(parsed.Ok);
    }

    [TestMethod]
    public void NestedObjects()
    {
        var input = new Dictionary<string, object?>
        {
            ["user"] = new Dictionary<string, object?>
            {
                ["name"] = "Bob",
                ["age"] = 30,
                ["address"] = new Dictionary<string, object?>
                {
                    ["city"] = "New York",
                    ["country"] = "USA"
                }
            }
        };

        var result = Stringify.Convert(input);
        var expected = @"{
	user: {
		name: ""Bob"",
		age: 30,
		address: {
			city: ""New York"",
			country: ""USA""
		}
	}
}";

        Assert.AreEqual(expected, result);

        var parsed = ParseData.Parse(result);
        Assert.IsTrue(parsed.Ok);
    }

    [TestMethod]
    public void NestedArrays()
    {
        var input = new Dictionary<string, object?>
        {
            ["matrix"] = new List<object?>
            {
                new List<object?> { 1, 2, 3 },
                new List<object?> { 4, 5, 6 },
                new List<object?> { 7, 8, 9 }
            }
        };

        var result = Stringify.Convert(input);
        var expected = @"{
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
}";

        Assert.AreEqual(expected, result);

        var parsed = ParseData.Parse(result);
        Assert.IsTrue(parsed.Ok);
    }

    [TestMethod]
    public void DateWithoutTime()
    {
        var input = new Dictionary<string, object?>
        {
            ["created_at"] = new DateTime(2025, 1, 15)
        };

        var result = Stringify.Convert(input);
        var parsed = ParseData.Parse(result);
        Assert.IsTrue(parsed.Ok);
    }

    [TestMethod]
    public void DateWithTime()
    {
        var input = new Dictionary<string, object?>
        {
            ["meeting_at"] = new DateTime(2025, 1, 15, 10, 30, 0)
        };

        var result = Stringify.Convert(input);
        var expected = @"{
	meeting_at: 2025-01-15T10:30
}";

        Assert.AreEqual(expected, result);

        var parsed = ParseData.Parse(result);
        Assert.IsTrue(parsed.Ok);
    }

    [TestMethod]
    public void DateWithTimeIncludingSeconds()
    {
        var input = new Dictionary<string, object?>
        {
            ["event_at"] = new DateTime(2025, 1, 15, 10, 30, 45)
        };

        var result = Stringify.Convert(input);
        var expected = @"{
	event_at: 2025-01-15T10:30
}";

        Assert.AreEqual(expected, result);

        var parsed = ParseData.Parse(result);
        Assert.IsTrue(parsed.Ok);
    }

    [TestMethod]
    public void BooleanValues()
    {
        var input = new Dictionary<string, object?>
        {
            ["is_active"] = true,
            ["is_deleted"] = false
        };

        var result = Stringify.Convert(input);
        var expected = @"{
	is_active: true,
	is_deleted: false
}";

        Assert.AreEqual(expected, result);

        var parsed = ParseData.Parse(result);
        Assert.IsTrue(parsed.Ok);
    }

    [TestMethod]
    public void NullValues()
    {
        var input = new Dictionary<string, object?>
        {
            ["optional"] = null,
            ["another"] = null
        };

        var result = Stringify.Convert(input);
        var expected = @"{
	optional: null,
	another: null
}";

        Assert.AreEqual(expected, result);

        var parsed = ParseData.Parse(result);
        Assert.IsTrue(parsed.Ok);
    }

    [TestMethod]
    public void Numbers()
    {
        var input = new Dictionary<string, object?>
        {
            ["integer"] = 42,
            ["float"] = 3.14,
            ["negative"] = -10,
            ["zero"] = 0,
            ["scientific"] = 1.5e10,
            ["hex"] = 0xff
        };

        var result = Stringify.Convert(input);
        var expected = @"{
	integer: 42,
	float: 3.14,
	negative: -10,
	zero: 0,
	scientific: 15000000000,
	hex: 255
}";

        Assert.AreEqual(expected, result);

        var parsed = ParseData.Parse(result);
        Assert.IsTrue(parsed.Ok);
    }

    [TestMethod]
    public void StringsWithSpecialCharacters()
    {
        var input = new Dictionary<string, object?>
        {
            ["quote"] = "She said \"Hello\"",
            ["path"] = "/usr/local/bin",
            ["regex"] = "^test.*pattern$"
        };

        var result = Stringify.Convert(input);
        var expected = @"{
	quote: ""She said ""Hello"""",
	path: ""/usr/local/bin"",
	regex: ""^test.*pattern$""
}";

        Assert.AreEqual(expected, result);

        // Can't parse because quotes aren't escaped properly
        var parsed = ParseData.Parse(result);
        Assert.IsFalse(parsed.Ok);
    }

    [TestMethod]
    public void LargeDataset()
    {
        var input = new Dictionary<string, object?>
        {
            ["users"] = new List<object?>
            {
                new Dictionary<string, object?> { ["id"] = 1, ["name"] = "Alice", ["active"] = true },
                new Dictionary<string, object?> { ["id"] = 2, ["name"] = "Bob", ["active"] = false },
                new Dictionary<string, object?> { ["id"] = 3, ["name"] = "Charlie", ["active"] = true }
            },
            ["stats"] = new Dictionary<string, object?>
            {
                ["total"] = 3,
                ["active"] = 2,
                ["inactive"] = 1,
                ["rating"] = 4.5
            }
        };

        var result = Stringify.Convert(input);
        var expected = @"{
	users: [
		{
			id: 1,
			name: ""Alice"",
			active: true
		},
		{
			id: 2,
			name: ""Bob"",
			active: false
		},
		{
			id: 3,
			name: ""Charlie"",
			active: true
		}
	],
	stats: {
		total: 3,
		active: 2,
		inactive: 1,
		rating: 4.5
	}
}";

        Assert.AreEqual(expected, result);

        var parsed = ParseData.Parse(result);
        Assert.IsTrue(parsed.Ok);
    }

    [TestMethod]
    public void AnsiColorModeEnabled()
    {
        var input = new Dictionary<string, object?>
        {
            ["name"] = "Alice",
            ["age"] = 25,
            ["active"] = true
        };

        var result = Stringify.Convert(input, new StringifyOptions { Ansi = true });
        var stripped = Regex.Replace(result, @"\u001b\[[0-9]+m", "");

        var expected = @"{
	name: ""Alice"",
	age: 25,
	active: true
}";

        Assert.AreEqual(expected, stripped);

        StringAssert.Contains(result, "\u001b[32m"); // Green for strings
        StringAssert.Contains(result, "\u001b[33m"); // Yellow for numbers
        StringAssert.Contains(result, "\u001b[34m"); // Blue for booleans
        StringAssert.Contains(result, "\u001b[0m"); // Reset
    }

    [TestMethod]
    public void AnsiColorModeDisabled()
    {
        var input = new Dictionary<string, object?>
        {
            ["name"] = "Alice",
            ["age"] = 25,
            ["active"] = true
        };

        var result = Stringify.Convert(input, new StringifyOptions { Ansi = false });
        var expected = @"{
	name: ""Alice"",
	age: 25,
	active: true
}";

        Assert.AreEqual(expected, result);
        Assert.DoesNotContain(result, "\u001b[");
    }

    [TestMethod]
    public void AnsiColorsForDates()
    {
        var input = new Dictionary<string, object?>
        {
            ["date"] = new DateTime(2025, 1, 15)
        };

        var result = Stringify.Convert(input, new StringifyOptions { Ansi = true });
        var stripped = Regex.Replace(result, @"\u001b\[[0-9]+m", "");

        var parsed = ParseData.Parse(stripped);
        Assert.IsTrue(parsed.Ok);
        StringAssert.Contains(result, "\u001b[35m"); // Magenta for dates
    }

    [TestMethod]
    public void ArrayOfObjects()
    {
        var input = new Dictionary<string, object?>
        {
            ["items"] = new List<object?>
            {
                new Dictionary<string, object?> { ["name"] = "Item 1", ["count"] = 5 },
                new Dictionary<string, object?> { ["name"] = "Item 2", ["count"] = 10 },
                new Dictionary<string, object?> { ["name"] = "Item 3", ["count"] = 15 }
            }
        };

        var result = Stringify.Convert(input);
        var expected = @"{
	items: [
		{
			name: ""Item 1"",
			count: 5
		},
		{
			name: ""Item 2"",
			count: 10
		},
		{
			name: ""Item 3"",
			count: 15
		}
	]
}";

        Assert.AreEqual(expected, result);

        var parsed = ParseData.Parse(result);
        Assert.IsTrue(parsed.Ok);
    }

    [TestMethod]
    public void CustomIndentText()
    {
        var input = new Dictionary<string, object?>
        {
            ["name"] = "Alice",
            ["children"] = new List<object?> { "Jez", "Bez" },
            ["active"] = true
        };

        var result = Stringify.Convert(input, new StringifyOptions { Indent = "  " });
        var expected = @"{
  name: ""Alice"",
  children: [
    ""Jez"",
    ""Bez""
  ],
  active: true
}";

        Assert.AreEqual(expected, result);
    }

    [TestMethod]
    public void DeeplyNestedStructures()
    {
        var input = new Dictionary<string, object?>
        {
            ["level1"] = new Dictionary<string, object?>
            {
                ["level2"] = new Dictionary<string, object?>
                {
                    ["level3"] = new Dictionary<string, object?>
                    {
                        ["deep"] = "value"
                    }
                }
            },
            ["nested_array"] = new List<object?>
            {
                new List<object?>
                {
                    new List<object?> { 1, 2 },
                    new List<object?> { 3, 4 }
                },
                new List<object?>
                {
                    new List<object?> { 5, 6 },
                    new List<object?> { 7, 8 }
                }
            }
        };

        var result = Stringify.Convert(input);
        var expected = @"{
	level1: {
		level2: {
			level3: {
				deep: ""value""
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
}";

        Assert.AreEqual(expected, result);

        var parsed = ParseData.Parse(result);
        Assert.IsTrue(parsed.Ok);
    }
}
