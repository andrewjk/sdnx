using Microsoft.VisualStudio.TestTools.UnitTesting;
using Sdnx.Core;

namespace Sdnx.Tests;

[TestClass]
public class ParseSchemaTests
{
    [TestMethod]
    public void BasicTest()
    {
        string input = @"{
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
}";

        var result = ParseSchema.Parse(input);
        Assert.IsTrue(result.Ok, result.Ok ? "" : string.Join("\n", result.Errors?.Select(e => e.Message) ?? new List<string>()));
        Assert.IsNotNull(result.Data);
        
        // Verify the schema was parsed correctly
        Assert.HasCount(8, result.Data!.Fields);
        Assert.IsTrue(result.Data.Fields.ContainsKey("active"));
        Assert.IsTrue(result.Data.Fields.ContainsKey("name"));
        Assert.IsTrue(result.Data.Fields.ContainsKey("children"));

        // Test with spaced input
        string spacedInput = TestHelpers.Space(input);
        var spacedResult = ParseSchema.Parse(spacedInput);
        Assert.IsTrue(spacedResult.Ok, spacedResult.Ok ? "" : string.Join("\n", spacedResult.Errors?.Select(e => e.Message) ?? new List<string>()));
        Assert.IsNotNull(spacedResult.Data);
        Assert.HasCount(8, spacedResult.Data!.Fields);

        // Test with unspaced input
        string unspacedInput = TestHelpers.Unspace(input)
            .Replace("min(", " min(")
            .Replace("max(", " max(")
            .Replace("len(", " len(")
            .Replace("min len(", " minlen(");
        var unspacedResult = ParseSchema.Parse(unspacedInput);
        Assert.IsTrue(unspacedResult.Ok, unspacedResult.Ok ? "" : string.Join("\n", unspacedResult.Errors?.Select(e => e.Message) ?? new List<string>()));
        Assert.IsNotNull(unspacedResult.Data);
        Assert.HasCount(8, unspacedResult.Data!.Fields);
    }

    [TestMethod]
    public void SimpleType()
    {
        string input = @"{
	name: string,
}";

        var result = ParseSchema.Parse(input);
        Assert.IsTrue(result.Ok);
        Assert.IsNotNull(result.Data);
        Assert.HasCount(1, result.Data!.Fields);
        Assert.IsTrue(result.Data.Fields.ContainsKey("name"));

        // Test with spaced input
        string spacedInput = TestHelpers.Space(input);
        var spacedResult = ParseSchema.Parse(spacedInput);
        Assert.IsTrue(spacedResult.Ok);
        Assert.HasCount(1, spacedResult.Data!.Fields);

        // Test with unspaced input
        string unspacedInput = TestHelpers.Unspace(input);
        var unspacedResult = ParseSchema.Parse(unspacedInput);
        Assert.IsTrue(unspacedResult.Ok);
        Assert.HasCount(1, unspacedResult.Data!.Fields);
    }

    [TestMethod]
    public void TypeWithDescription()
    {
        string input = @"{
	## This is a name
	name: string,
}";

        var result = ParseSchema.Parse(input);
        Assert.IsTrue(result.Ok);
        Assert.IsNotNull(result.Data);
        Assert.HasCount(1, result.Data!.Fields);

        // Test with spaced input
        string spacedInput = TestHelpers.Space(input);
        var spacedResult = ParseSchema.Parse(spacedInput);
        Assert.IsTrue(spacedResult.Ok);

        // Test with unspaced input
        string unspacedInput = TestHelpers.Unspace(input);
        var unspacedResult = ParseSchema.Parse(unspacedInput);
        Assert.IsTrue(unspacedResult.Ok);
    }

    [TestMethod]
    public void UnionType()
    {
        string input = @"{
	value: string | int,
}";

        var result = ParseSchema.Parse(input);
        Assert.IsTrue(result.Ok);
        Assert.IsNotNull(result.Data);
        Assert.HasCount(1, result.Data!.Fields);
        Assert.IsInstanceOfType(result.Data.Fields["value"], typeof(UnionSchema));

        // Test with spaced input
        string spacedInput = TestHelpers.Space(input);
        var spacedResult = ParseSchema.Parse(spacedInput);
        Assert.IsTrue(spacedResult.Ok);

        // Test with unspaced input
        string unspacedInput = TestHelpers.Unspace(input);
        var unspacedResult = ParseSchema.Parse(unspacedInput);
        Assert.IsTrue(unspacedResult.Ok);
    }

    [TestMethod]
    public void TypeWithParameter()
    {
        string input = @"{
	age: int min(0),
}";

        var result = ParseSchema.Parse(input);
        Assert.IsTrue(result.Ok);
        Assert.IsNotNull(result.Data);
        Assert.HasCount(1, result.Data!.Fields);

        // Test with spaced input
        string spacedInput = TestHelpers.Space(input);
        var spacedResult = ParseSchema.Parse(spacedInput);
        Assert.IsTrue(spacedResult.Ok);

        // Test with unspaced input
        string unspacedInput = TestHelpers.Unspace(input).Replace("min(", " min(");
        var unspacedResult = ParseSchema.Parse(unspacedInput);
        Assert.IsTrue(unspacedResult.Ok);
    }

    [TestMethod]
    public void ObjectType()
    {
        string input = @"{
	dob: { year: int, month: int, day: int }
}";

        var result = ParseSchema.Parse(input);
        Assert.IsTrue(result.Ok);
        Assert.IsNotNull(result.Data);
        Assert.HasCount(1, result.Data!.Fields);
        Assert.IsInstanceOfType(result.Data.Fields["dob"], typeof(ObjectSchema));

        // Test with spaced input
        string spacedInput = TestHelpers.Space(input);
        var spacedResult = ParseSchema.Parse(spacedInput);
        Assert.IsTrue(spacedResult.Ok);

        // Test with unspaced input
        string unspacedInput = TestHelpers.Unspace(input);
        var unspacedResult = ParseSchema.Parse(unspacedInput);
        Assert.IsTrue(unspacedResult.Ok);
    }

    [TestMethod]
    public void ArrayType()
    {
        string input = @"{
	children: [ string ]
}";

        var result = ParseSchema.Parse(input);
        Assert.IsTrue(result.Ok);
        Assert.IsNotNull(result.Data);
        Assert.HasCount(1, result.Data!.Fields);
        Assert.IsInstanceOfType(result.Data.Fields["children"], typeof(ArraySchema));

        // Test with spaced input
        string spacedInput = TestHelpers.Space(input);
        var spacedResult = ParseSchema.Parse(spacedInput);
        Assert.IsTrue(spacedResult.Ok);

        // Test with unspaced input
        string unspacedInput = TestHelpers.Unspace(input);
        var unspacedResult = ParseSchema.Parse(unspacedInput);
        Assert.IsTrue(unspacedResult.Ok);
    }

    [TestMethod]
    public void MixMacro()
    {
        string input = @"{
	name: string minlen(2),
	@mix({
		age: int min(16),
		rating: num max(5),
	}),
	active: bool,
}";

        var result = ParseSchema.Parse(input);
        Assert.IsTrue(result.Ok);
        Assert.IsNotNull(result.Data);

        // Test with spaced input
        string spacedInput = TestHelpers.Space(input);
        var spacedResult = ParseSchema.Parse(spacedInput);
        Assert.IsTrue(spacedResult.Ok);

        // Test with unspaced input
        string unspacedInput = TestHelpers.Unspace(input)
            .Replace("min(", " min(")
            .Replace("max(", " max(")
            .Replace("len(", " len(")
            .Replace("min len(", " minlen(");
        var unspacedResult = ParseSchema.Parse(unspacedInput);
        Assert.IsTrue(unspacedResult.Ok);
    }

    [TestMethod]
    public void DefMacro()
    {
        string input = @"{
	@def(child): {
		name: string,
		age: int,
	},
	name: string minlen(2),
	@mix(child),
	active: bool,
}";

        var result = ParseSchema.Parse(input);
        Assert.IsTrue(result.Ok);
        Assert.IsNotNull(result.Data);
        Assert.IsTrue(result.Data!.Fields.ContainsKey("def$1"));
        Assert.IsTrue(result.Data.Fields.ContainsKey("mix$1"));

        // Test with spaced input
        string spacedInput = TestHelpers.Space(input);
        var spacedResult = ParseSchema.Parse(spacedInput);
        Assert.IsTrue(spacedResult.Ok);

        // Test with unspaced input
        string unspacedInput = TestHelpers.Unspace(input)
            .Replace("min(", " min(")
            .Replace("max(", " max(")
            .Replace("len(", " len(")
            .Replace("min len(", " minlen(");
        var unspacedResult = ParseSchema.Parse(unspacedInput);
        Assert.IsTrue(unspacedResult.Ok);
    }

    [TestMethod]
    public void PropsMacro()
    {
        string input = @"{
	name: string minlen(2),
	@props(): int min(16),
	active: bool,
}";

        var result = ParseSchema.Parse(input);
        Assert.IsTrue(result.Ok);
        Assert.IsNotNull(result.Data);
        Assert.IsTrue(result.Data!.Fields.ContainsKey("props$1"));

        // Test with spaced input
        string spacedInput = TestHelpers.Space(input);
        var spacedResult = ParseSchema.Parse(spacedInput);
        Assert.IsTrue(spacedResult.Ok);

        // Test with unspaced input
        string unspacedInput = TestHelpers.Unspace(input)
            .Replace("min(", " min(")
            .Replace("max(", " max(")
            .Replace("len(", " len(")
            .Replace("min len(", " minlen(");
        var unspacedResult = ParseSchema.Parse(unspacedInput);
        Assert.IsTrue(unspacedResult.Ok);
    }

    [TestMethod]
    public void PropsMacroWithPattern()
    {
        string input = @"{
	@props(/v\d/): string,
}";

        var result = ParseSchema.Parse(input);
        Assert.IsTrue(result.Ok);
        Assert.IsNotNull(result.Data);

        // Test with spaced input
        string spacedInput = TestHelpers.Space(input);
        var spacedResult = ParseSchema.Parse(spacedInput);
        Assert.IsTrue(spacedResult.Ok);

        // Test with unspaced input
        string unspacedInput = TestHelpers.Unspace(input);
        var unspacedResult = ParseSchema.Parse(unspacedInput);
        Assert.IsTrue(unspacedResult.Ok);
    }

    [TestMethod]
    public void TypeWithMultipleParameters()
    {
        string input = @"{
	rating: num min(0) max(5),
}";

        var result = ParseSchema.Parse(input);
        Assert.IsTrue(result.Ok);
        Assert.IsNotNull(result.Data);

        // Test with spaced input
        string spacedInput = TestHelpers.Space(input);
        var spacedResult = ParseSchema.Parse(spacedInput);
        Assert.IsTrue(spacedResult.Ok);

        // Test with unspaced input
        string unspacedInput = TestHelpers.Unspace(input).Replace("min(", " min(").Replace("max(", " max(");
        var unspacedResult = ParseSchema.Parse(unspacedInput);
        Assert.IsTrue(unspacedResult.Ok);
    }

    [TestMethod]
    public void NestedObject()
    {
        string input = @"{
	address: {
		street: string,
		city: string,
		zip: string,
	},
}";

        var result = ParseSchema.Parse(input);
        Assert.IsTrue(result.Ok);
        Assert.IsNotNull(result.Data);
        Assert.IsInstanceOfType(result.Data!.Fields["address"], typeof(ObjectSchema));

        // Test with spaced input
        string spacedInput = TestHelpers.Space(input);
        var spacedResult = ParseSchema.Parse(spacedInput);
        Assert.IsTrue(spacedResult.Ok);

        // Test with unspaced input
        string unspacedInput = TestHelpers.Unspace(input);
        var unspacedResult = ParseSchema.Parse(unspacedInput);
        Assert.IsTrue(unspacedResult.Ok);
    }

    [TestMethod]
    public void ArrayOfObjects()
    {
        string input = @"{
	items: [{ id: int, name: string }],
}";

        var result = ParseSchema.Parse(input);
        Assert.IsTrue(result.Ok);
        Assert.IsNotNull(result.Data);
        Assert.IsInstanceOfType(result.Data!.Fields["items"], typeof(ArraySchema));

        // Test with spaced input
        string spacedInput = TestHelpers.Space(input);
        var spacedResult = ParseSchema.Parse(spacedInput);
        Assert.IsTrue(spacedResult.Ok);

        // Test with unspaced input
        string unspacedInput = TestHelpers.Unspace(input);
        var unspacedResult = ParseSchema.Parse(unspacedInput);
        Assert.IsTrue(unspacedResult.Ok);
    }

    [TestMethod]
    public void ArrayOfArrays()
    {
        string input = @"{
	matrix: [[ int ]],
}";

        var result = ParseSchema.Parse(input);
        Assert.IsTrue(result.Ok);
        Assert.IsNotNull(result.Data);
        Assert.IsInstanceOfType(result.Data!.Fields["matrix"], typeof(ArraySchema));

        // Test with spaced input
        string spacedInput = TestHelpers.Space(input);
        var spacedResult = ParseSchema.Parse(spacedInput);
        Assert.IsTrue(spacedResult.Ok);

        // Test with unspaced input
        string unspacedInput = TestHelpers.Unspace(input);
        var unspacedResult = ParseSchema.Parse(unspacedInput);
        Assert.IsTrue(unspacedResult.Ok);
    }

    [TestMethod]
    public void UnionOfThreeTypes()
    {
        string input = @"{
	value: string | int | bool,
}";

        var result = ParseSchema.Parse(input);
        Assert.IsTrue(result.Ok);
        Assert.IsNotNull(result.Data);
        Assert.IsInstanceOfType(result.Data!.Fields["value"], typeof(UnionSchema));
        var union = (UnionSchema)result.Data.Fields["value"];
        Assert.HasCount(3, union.Inner);

        // Test with spaced input
        string spacedInput = TestHelpers.Space(input);
        var spacedResult = ParseSchema.Parse(spacedInput);
        Assert.IsTrue(spacedResult.Ok);

        // Test with unspaced input
        string unspacedInput = TestHelpers.Unspace(input);
        var unspacedResult = ParseSchema.Parse(unspacedInput);
        Assert.IsTrue(unspacedResult.Ok);
    }

    [TestMethod]
    public void MultipleMixMacros()
    {
        string input = @"{
	@mix({
		role: ""admin"",
		level: int min(1),
	}),
	@mix({
		role: ""user"",
		plan: string,
	}),
}";

        var result = ParseSchema.Parse(input);
        Assert.IsTrue(result.Ok);
        Assert.IsNotNull(result.Data);
        Assert.IsTrue(result.Data!.Fields.ContainsKey("mix$1"));
        Assert.IsTrue(result.Data.Fields.ContainsKey("mix$2"));

        // Test with spaced input
        string spacedInput = TestHelpers.Space(input);
        var spacedResult = ParseSchema.Parse(spacedInput);
        Assert.IsTrue(spacedResult.Ok);

        // Test with unspaced input
        string unspacedInput = TestHelpers.Unspace(input).Replace("min(", " min(");
        var unspacedResult = ParseSchema.Parse(unspacedInput);
        Assert.IsTrue(unspacedResult.Ok);
    }

    [TestMethod]
    public void MixWithMultipleAlternatives()
    {
        string input = @"{
	@mix({
		minor: false
	} | {
		minor: true,
		guardian: string
	} | {
		minor: true,
		age: int min(18)
	}),
}";

        var result = ParseSchema.Parse(input);
        Assert.IsTrue(result.Ok);
        Assert.IsNotNull(result.Data);

        // Test with spaced input
        string spacedInput = TestHelpers.Space(input);
        var spacedResult = ParseSchema.Parse(spacedInput);
        Assert.IsTrue(spacedResult.Ok);

        // Test with unspaced input
        string unspacedInput = TestHelpers.Unspace(input).Replace("min(", " min(");
        var unspacedResult = ParseSchema.Parse(unspacedInput);
        Assert.IsTrue(unspacedResult.Ok);
    }

    [TestMethod]
    public void EmptyObject()
    {
        string input = "{}";

        var result = ParseSchema.Parse(input);
        Assert.IsTrue(result.Ok);
        Assert.IsNotNull(result.Data);
        Assert.HasCount(0, result.Data!.Fields);

        // Test with spaced input
        string spacedInput = TestHelpers.Space(input);
        var spacedResult = ParseSchema.Parse(spacedInput);
        Assert.IsTrue(spacedResult.Ok);

        // Test with unspaced input
        string unspacedInput = TestHelpers.Unspace(input);
        var unspacedResult = ParseSchema.Parse(unspacedInput);
        Assert.IsTrue(unspacedResult.Ok);
    }

    [TestMethod]
    public void ArrayWithUnionType()
    {
        string input = @"{
	values: [ string | int ],
}";

        var result = ParseSchema.Parse(input);
        Assert.IsTrue(result.Ok);
        Assert.IsNotNull(result.Data);

        // Test with spaced input
        string spacedInput = TestHelpers.Space(input);
        var spacedResult = ParseSchema.Parse(spacedInput);
        Assert.IsTrue(spacedResult.Ok);

        // Test with unspaced input
        string unspacedInput = TestHelpers.Unspace(input);
        var unspacedResult = ParseSchema.Parse(unspacedInput);
        Assert.IsTrue(unspacedResult.Ok);
    }

    [TestMethod]
    public void UnionWithArrayFirst()
    {
        string input = @" {
	values: [ string ] | string,
 }";

        var result = ParseSchema.Parse(input);
        Assert.IsTrue(result.Ok);
        Assert.IsNotNull(result.Data);

        // Test with spaced input
        string spacedInput = TestHelpers.Space(input);
        var spacedResult = ParseSchema.Parse(spacedInput);
        Assert.IsTrue(spacedResult.Ok);

        // Test with unspaced input
        string unspacedInput = TestHelpers.Unspace(input);
        var unspacedResult = ParseSchema.Parse(unspacedInput);
        Assert.IsTrue(unspacedResult.Ok);
    }

    [TestMethod]
    public void UnionWithArraySecond()
    {
        string input = @" {
	values: string | [ string ],
 }";

        var result = ParseSchema.Parse(input);
        Assert.IsTrue(result.Ok);
        Assert.IsNotNull(result.Data);

        // Test with spaced input
        string spacedInput = TestHelpers.Space(input);
        var spacedResult = ParseSchema.Parse(spacedInput);
        Assert.IsTrue(spacedResult.Ok);

        // Test with unspaced input
        string unspacedInput = TestHelpers.Unspace(input);
        var unspacedResult = ParseSchema.Parse(unspacedInput);
        Assert.IsTrue(unspacedResult.Ok);
    }

    [TestMethod]
    public void UnionWithObjectFirst()
    {
        string input = @" {
	values: { name: string } | string,
 }";

        var result = ParseSchema.Parse(input);
        Assert.IsTrue(result.Ok);
        Assert.IsNotNull(result.Data);

        // Test with spaced input
        string spacedInput = TestHelpers.Space(input);
        var spacedResult = ParseSchema.Parse(spacedInput);
        Assert.IsTrue(spacedResult.Ok);

        // Test with unspaced input
        string unspacedInput = TestHelpers.Unspace(input);
        var unspacedResult = ParseSchema.Parse(unspacedInput);
        Assert.IsTrue(unspacedResult.Ok);
    }

    [TestMethod]
    public void UnionWithObjectSecond()
    {
        string input = @" {
	values: string | { name: string },
 }";

        var result = ParseSchema.Parse(input);
        Assert.IsTrue(result.Ok);
        Assert.IsNotNull(result.Data);

        // Test with spaced input
        string spacedInput = TestHelpers.Space(input);
        var spacedResult = ParseSchema.Parse(spacedInput);
        Assert.IsTrue(spacedResult.Ok);

        // Test with unspaced input
        string unspacedInput = TestHelpers.Unspace(input);
        var unspacedResult = ParseSchema.Parse(unspacedInput);
        Assert.IsTrue(unspacedResult.Ok);
    }

    [TestMethod]
    public void DeeplyNestedStructure()
    {
        string input = @"{
	data: {
		user: {
			profile: {
				name: string,
				contacts: [{ type: string, value: string }],
			},
		},
	},
}";

        var result = ParseSchema.Parse(input);
        Assert.IsTrue(result.Ok);
        Assert.IsNotNull(result.Data);

        // Test with spaced input
        string spacedInput = TestHelpers.Space(input);
        var spacedResult = ParseSchema.Parse(spacedInput);
        Assert.IsTrue(spacedResult.Ok);

        // Test with unspaced input
        string unspacedInput = TestHelpers.Unspace(input);
        var unspacedResult = ParseSchema.Parse(unspacedInput);
        Assert.IsTrue(unspacedResult.Ok);
    }
}
