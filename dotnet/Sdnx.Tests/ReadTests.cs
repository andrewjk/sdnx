using Microsoft.VisualStudio.TestTools.UnitTesting;
using Sdnx.Core;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;

namespace Sdnx.Tests;

[TestClass]
public class ReadTests
{
	private static int index = 1;
	private static string tmpDir = Path.Combine(Path.GetTempPath(), "sdnx-read-test-" + DateTime.Now.Ticks);

	private static List<string> SetupTestFiles(Dictionary<string, string> files)
	{
		var subTmpDir = Path.Combine(tmpDir, (index++).ToString());
		var paths = new List<string>();
		foreach (var kvp in files)
		{
			string name = kvp.Key;
			string content = kvp.Value;
			string filePath = Path.Combine(subTmpDir, name);
			string? fileDir = Path.GetDirectoryName(filePath);
			if (fileDir != null && !Directory.Exists(fileDir))
			{
				Directory.CreateDirectory(fileDir);
			}
			File.WriteAllText(filePath, content);
			paths.Add(filePath);
		}
		return paths;
	}

	private static void CleanupTestFiles()
	{
		if (Directory.Exists(tmpDir))
		{
			Directory.Delete(tmpDir, true);
		}
	}

	[ClassCleanup]
	public static void TestCleanup()
	{
		CleanupTestFiles();
	}

	[TestMethod]
	public void Read_SuccessfulWithSchemaDirective()
	{
		string schema = "{ name: string, age: int }";
		string data = "@schema(\"./schema.sdnx\")\n{ name: \"Alice\", age: 30 }";

		var paths = SetupTestFiles(new Dictionary<string, string>
		{
			{ "schema.sdnx", schema },
			{ "data.sdn", data }
		});

		var result = ReadData.Read(paths[1]);

		Assert.IsTrue(result is ReadSuccess);
		if (result is ReadSuccess success)
		{
			Assert.AreEqual("Alice", success.Data["name"]);
			Assert.AreEqual(30, success.Data["age"]);
		}
	}

	[TestMethod]
	public void Read_SuccessfulWithExplicitSchemaPath()
	{
		string schema = "{ name: string, age: int }";
		string data = "{ name: \"Bob\", age: 25 }";

		var paths = SetupTestFiles(new Dictionary<string, string>
		{
			{ "schema.sdnx", schema },
			{ "data.sdn", data }
		});

		var result = ReadData.Read(paths[1], paths[0]);

		Assert.IsTrue(result is ReadSuccess);
		if (result is ReadSuccess success)
		{
			Assert.AreEqual("Bob", success.Data["name"]);
			Assert.AreEqual(25, success.Data["age"]);
		}
	}

	[TestMethod]
	public void Read_SuccessfulWithSchemaObject()
	{
		var schemaResult = ParseSchema.Parse("{ name: string, age: int }");
		Assert.IsTrue(schemaResult.Ok);

		string data = "{ name: \"Charlie\", age: 35 }";
		var paths = SetupTestFiles(new Dictionary<string, string>
		{
			{ "data.sdn", data }
		});

		var result = ReadData.Read(paths[0], schemaResult.Data);

		Assert.IsTrue(result is ReadSuccess);
		if (result is ReadSuccess success)
		{
			Assert.AreEqual("Charlie", success.Data["name"]);
			Assert.AreEqual(35, success.Data["age"]);
		}
	}

	[TestMethod]
	public void Read_FailsWithDataParseErrors()
	{
		string schema = "{ name: string, age: int }";
		string data = "@schema(\"./schema.sdnx\")\n{ name: \"Alice\", age: }";

		var paths = SetupTestFiles(new Dictionary<string, string>
		{
			{ "schema.sdnx", schema },
			{ "data.sdn", data }
		});

		var result = ReadData.Read(paths[1]);

		Assert.IsFalse(result is ReadSuccess);
		if (result is ReadFailure failure)
		{
			Assert.HasCount(0, failure.SchemaErrors);
			Assert.IsNotEmpty(failure.DataErrors);
			Assert.HasCount(0, failure.CheckErrors);
			Assert.IsNotNull(failure.DataErrors[0].Message);
		}
	}

	[TestMethod]
	public void Read_FailsWithSchemaParseErrors()
	{
		string schema = "{ name: string, age: }";
		string data = "@schema(\"./schema.sdnx\")\n{ name: \"Alice\", age: 30 }";

		var paths = SetupTestFiles(new Dictionary<string, string>
		{
			{ "schema.sdnx", schema },
			{ "data.sdn", data }
		});

		var result = ReadData.Read(paths[1]);

		Assert.IsFalse(result is ReadSuccess);
		if (result is ReadFailure failure)
		{
			Assert.IsNotEmpty(failure.SchemaErrors);
			Assert.HasCount(0, failure.DataErrors);
			Assert.HasCount(0, failure.CheckErrors);
		}
	}

	[TestMethod]
	public void Read_FailsWithValidationErrors()
	{
		string schema = "{ name: string, age: int min(18) }";
		string data = "@schema(\"./schema.sdnx\")\n{ name: \"Alice\", age: 15 }";

		var paths = SetupTestFiles(new Dictionary<string, string>
		{
			{ "schema.sdnx", schema },
			{ "data.sdn", data }
		});

		var result = ReadData.Read(paths[1]);

		Assert.IsFalse(result is ReadSuccess);
		if (result is ReadFailure failure)
		{
			Assert.HasCount(0, failure.SchemaErrors);
			Assert.HasCount(0, failure.DataErrors);
			Assert.IsNotEmpty(failure.CheckErrors);
			StringAssert.Contains(failure.CheckErrors[0].Message, "least");
		}
	}

	[TestMethod]
	public void Read_ThrowsErrorWhenFileNotFound()
	{
		try
		{
			ReadData.Read("/nonexistent/path/to/file.sdn");
			Assert.Fail("Expected FileNotFoundException to be thrown");
		}
		catch (FileNotFoundException)
		{
			// Expected exception
		}
	}

	[TestMethod]
	public void Read_ThrowsErrorWhenSchemaDirectiveMissingAndSchemaNotProvided()
	{
		string data = "{ name: \"Alice\", age: 30 }";
		var paths = SetupTestFiles(new Dictionary<string, string>
		{
			{ "data.sdn", data }
		});

		try
		{
			ReadData.Read(paths[0]);
			Assert.Fail("Expected InvalidOperationException to be thrown");
		}
		catch (InvalidOperationException)
		{
			// Expected exception
		}
	}

	[TestMethod]
	public void Read_ResolvesRelativeSchemaPathCorrectly()
	{
		string schema = "{ name: string }";
		string data = "@schema(\"./schema.sdnx\")\n{ name: \"Alice\" }";

		var paths = SetupTestFiles(new Dictionary<string, string>
		{
			{ "schema.sdnx", schema },
			{ "data.sdn", data }
		});

		var result = ReadData.Read(paths[1]);

		Assert.IsTrue(result is ReadSuccess);
		if (result is ReadSuccess success)
		{
			Assert.AreEqual("Alice", success.Data["name"]);
		}
	}

	[TestMethod]
	public void Read_HandlesNestedSchemaPath()
	{
		string schema = "{ name: string }";
		string data = "@schema(\"./schemas/schema.sdnx\")\n{ name: \"Alice\" }";

		var paths = SetupTestFiles(new Dictionary<string, string>
		{
			{ "schemas/schema.sdnx", schema },
			{ "data.sdn", data }
		});

		var result = ReadData.Read(paths[1]);

		Assert.IsTrue(result is ReadSuccess);
		if (result is ReadSuccess success)
		{
			Assert.AreEqual("Alice", success.Data["name"]);
		}
	}

	[TestMethod]
	public void Read_HandlesComplexNestedData()
	{
		string schema = @"{
	name: string,
	age: int,
	address: { street: string, city: string },
	tags: [string]
}";

		string data = @"@schema(""./schema.sdnx"")
{
	name: ""Alice"",
	age: 30,
	address: { street: ""123 Main St"", city: ""NYC"" },
	tags: [""developer"", ""engineer""]
}";

		var paths = SetupTestFiles(new Dictionary<string, string>
		{
			{ "schema.sdnx", schema },
			{ "data.sdn", data }
		});

		var result = ReadData.Read(paths[1]);

		Assert.IsTrue(result is ReadSuccess);
		if (result is ReadSuccess success)
		{
			Assert.AreEqual("Alice", success.Data["name"]);
			Assert.AreEqual(30, success.Data["age"]);
			var address = success.Data["address"] as Dictionary<string, object?>;
			Assert.IsNotNull(address);
			Assert.AreEqual("123 Main St", address!["street"]);
			Assert.AreEqual("NYC", address!["city"]);
			var tags = success.Data["tags"] as List<object?>;
			Assert.IsNotNull(tags);
			Assert.HasCount(2, tags!);
			Assert.AreEqual("developer", tags![0]);
			Assert.AreEqual("engineer", tags![1]);
		}
	}

	[TestMethod]
	public void Read_IncludesLineAndCharInfoInParseErrors()
	{
		string schema = "{ name: string }";
		string data = "@schema(\"./schema.sdnx\")\n{ name: \"Alice\",\nage: invalid}";

		var paths = SetupTestFiles(new Dictionary<string, string>
		{
			{ "schema.sdnx", schema },
			{ "data.sdn", data }
		});

		var result = ReadData.Read(paths[1]);

		Assert.IsFalse(result is ReadSuccess);
		if (result is ReadFailure failure)
		{
			Assert.IsNotEmpty(failure.DataErrors);
			var error = failure.DataErrors[0];
			Assert.IsNotNull(error.Line);
			Assert.IsGreaterThanOrEqualTo(0, error.Char);
			Assert.IsGreaterThanOrEqualTo(0, error.Index);
			Assert.IsGreaterThanOrEqualTo(0, error.Length);
			Assert.IsNotNull(error.Message);
		}
	}

	[TestMethod]
	public void Read_HandlesEmptyDataFile()
	{
		string schema = "{ name: string }";
		string data = "@schema(\"./schema.sdnx\")\n{}";

		var paths = SetupTestFiles(new Dictionary<string, string>
		{
			{ "schema.sdnx", schema },
			{ "data.sdn", data }
		});

		var result = ReadData.Read(paths[1]);

		Assert.IsFalse(result is ReadSuccess);
		if (result is ReadFailure failure)
		{
			Assert.IsNotEmpty(failure.CheckErrors);
		}
	}

	[TestMethod]
	public void Read_HandlesSchemaWithUnionTypes()
	{
		string schema = "{ value: int | string }";
		string data = "@schema(\"./schema.sdnx\")\n{ value: 42 }";

		var paths = SetupTestFiles(new Dictionary<string, string>
		{
			{ "schema.sdnx", schema },
			{ "data.sdn", data }
		});

		var result = ReadData.Read(paths[1]);
//		if (result is ReadFailure f) {
//Console.Write("COUNT: " + f.SchemaErrors.Count);
//		}
		Assert.IsTrue(result is ReadSuccess);
		if (result is ReadSuccess success)
		{
			Assert.AreEqual(42, success.Data["value"]);
		}
	}

	[TestMethod]
	public void Read_HandlesSchemaWithArrayOfObjects()
	{
		string schema = "{ users: [{ name: string, age: int }] }";
		string data = @"@schema(""./schema.sdnx"")
{
	users: [
		{ name: ""Alice"", age: 30 },
		{ name: ""Bob"", age: 25 }
	]
}";

		var paths = SetupTestFiles(new Dictionary<string, string>
		{
			{ "schema.sdnx", schema },
			{ "data.sdn", data }
		});

		var result = ReadData.Read(paths[1]);

		Assert.IsTrue(result is ReadSuccess);
		if (result is ReadSuccess success)
		{
			var users = success.Data["users"] as List<object?>;
			Assert.IsNotNull(users);
			Assert.HasCount(2, users!);
		}
	}

	[TestMethod]
	public void Read_HandlesFilePathFromCwd()
	{
		string schema = "{ name: string }";
		string data = "@schema(\"./schema.sdnx\")\n{ name: \"Alice\" }";

		var paths = SetupTestFiles(new Dictionary<string, string>
		{
			{ "schema.sdnx", schema },
			{ "data.sdn", data }
		});

		string oldCwd = Directory.GetCurrentDirectory();
		Directory.SetCurrentDirectory(Path.GetDirectoryName(paths[0])!);

		try
		{
			var result = ReadData.Read("data.sdn");

			Assert.IsTrue(result is ReadSuccess);
			if (result is ReadSuccess success)
			{
				Assert.AreEqual("Alice", success.Data["name"]);
			}
		}
		finally
		{
			Directory.SetCurrentDirectory(oldCwd);
		}
	}
}
