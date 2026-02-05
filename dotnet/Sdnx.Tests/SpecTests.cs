using Microsoft.VisualStudio.TestTools.UnitTesting;
using Sdnx.Core;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;

namespace Sdnx.Tests;

[TestClass]
public class SpecTests
{
    private const int OnlyTest = 0; // Set to test number to run only that test, 0 to run all

    private static List<SpecTestCase> _testCases = new List<SpecTestCase>();

    [ClassInitialize]
    public static void ClassInitialize(TestContext context)
    {
        // Parse SPEC.md file
        var specPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "..", "..", "..", "..", "..", "SPEC.md");
        specPath = Path.GetFullPath(specPath);

        if (!File.Exists(specPath))
        {
            // Try alternative path
            specPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "..", "..", "..", "..", "SPEC.md");
            specPath = Path.GetFullPath(specPath);
        }

        Assert.IsTrue(File.Exists(specPath), $"SPEC.md not found at {specPath}");

        var lines = File.ReadAllLines(specPath);
        _testCases = ParseSpecTests(lines);
    }

    [DynamicData(nameof(GetTestCases), DynamicDataSourceType.Method)]
    [TestMethod]
    public void RunSpecTest(SpecTestCase testCase)
    {
        if (OnlyTest > 0 && testCase.TestNumber != OnlyTest)
        {
            return;
        }

        string result = "OK";

        try
        {
            var schemaResult = ParseSchema.Parse(testCase.Schema);
            if (!schemaResult.Ok)
            {
                throw new InvalidOperationException(schemaResult.Errors?.FirstOrDefault()?.Message ?? "Schema parse error");
            }

            var inputResult = ParseData.Parse(testCase.Input);
            if (!inputResult.Ok)
            {
                throw new InvalidOperationException(inputResult.Errors?.FirstOrDefault()?.Message ?? "Input parse error");
            }

            var checkResult = CheckData.Check(inputResult.Data!, schemaResult.Data!);
            if (checkResult.Ok)
            {
                // Success - if expected was provided, stringify the result to compare
                // Otherwise the result should be "OK"
                if (!string.IsNullOrEmpty(testCase.Expected))
                {
                    result = Stringify.Convert(inputResult.Data!);
                }
                else
                {
                    result = "OK";
                }
            }
            else
            {
                result = $"Error: {string.Join("", checkResult.Errors?.Select(e => e.Message) ?? new List<string>())}";
            }
        }
        catch (Exception ex)
        {
            var message = ex.Message.Replace(" [", ""); // Remove line number info like " [42]"
            // If the message doesn't already start with "Error: ", add it
            if (!message.StartsWith("Error: "))
            {
                message = $"Error: {message}";
            }
            result = message;
        }

        // Default expected to "OK" if not provided
        var expectedValue = testCase.Expected ?? "OK";
        Assert.AreEqual(expectedValue, result, $"Test case at line {testCase.LineNumber}");
    }

    public static IEnumerable<object[]> GetTestCases()
    {
        foreach (var testCase in _testCases)
        {
            yield return new object[] { testCase };
        }
    }

    private static List<SpecTestCase> ParseSpecTests(string[] lines)
    {
        var tests = new List<SpecTestCase>();
        var exampleStartPattern = new Regex(@"^```````````````````````````````` example");
        var exampleEndPattern = new Regex(@"^````````````````````````````````");

        for (int i = 0; i < lines.Length; i++)
        {
            if (exampleStartPattern.IsMatch(lines[i]))
            {
                var exampleLines = new List<string>();
                int startLine = i + 1;

                for (int j = i + 1; j < lines.Length; j++)
                {
                    if (exampleEndPattern.IsMatch(lines[j]))
                    {
                        var example = string.Join("\n", exampleLines);
                        
                        // Replace tab markers (→) with actual tabs
                        example = example.Replace("→", "\t");

                        // Split by newlines starting with '.'
                        var parts = example.Split(new[] { "\n." }, StringSplitOptions.None)
                            .Select(p => p.Trim())
                            .ToList();

                        if (parts.Count >= 2)
                        {
                            var schema = parts[0];
                            var input = parts[1];
                            var expected = parts.Count > 2 ? parts[2] : null;

                            tests.Add(new SpecTestCase
                            {
                                TestNumber = tests.Count + 1,
                                LineNumber = startLine,
                                Schema = schema,
                                Input = input,
                                Expected = expected,
                                Header = $"spec example {tests.Count + 1}, line {startLine}: '{input.Replace("\n", " ")}'"
                            });
                        }

                        i = j;
                        break;
                    }
                    else
                    {
                        exampleLines.Add(lines[j]);
                    }
                }
            }
        }

        return tests;
    }

    public class SpecTestCase
    {
        public int TestNumber { get; set; }
        public int LineNumber { get; set; }
        public string Schema { get; set; } = "";
        public string Input { get; set; } = "";
        public string Expected { get; set; } = "";
        public string Header { get; set; } = "";

        public override string ToString()
        {
            return Header;
        }
    }
}
