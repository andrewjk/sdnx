using System;
using System.Runtime.InteropServices.Marshalling;
using Sdnx.Core;

namespace Sdnx.Cli;

class Program
{
	static void Main(string[] args)
	{
		string file = args.Length > 0 ? args[0] : "";
		string schema = args.Length > 1 ? args[1] : "";

		if (string.IsNullOrEmpty(file))
		{
			Console.WriteLine("Usage: sdnx <file> [schema]");
			Console.WriteLine("  file   - Path to the data file to read and check");
			Console.WriteLine("  schema - Optional: Path to schema file, or @schema directive will be used");
			Environment.Exit(1);
		}

		try
		{
			object? schemaParam = string.IsNullOrEmpty(schema) ? null : schema;
			var result = ReadData.Read(file, schemaParam);

			if (result is ReadSuccess success)
			{
				Console.WriteLine();
				Console.WriteLine("File read with no errors.");
				Console.WriteLine();
				Console.WriteLine(Stringify.Convert(success.Data, new StringifyOptions { Ansi = true, Indent = "    " }));
			}
			else if (result is ReadFailure failure)
			{
				PrintReadErrors(failure.SchemaErrors);
				PrintReadErrors(failure.DataErrors);
				PrintCheckErrors(failure.CheckErrors);
				Environment.Exit(1);
			}
		}
		catch (FileNotFoundException ex)
		{
			Console.ForegroundColor = ConsoleColor.Red;
			Console.WriteLine($"File not found: {ex.Message}");
			Console.ResetColor();
			Environment.Exit(1);
		}
		catch (InvalidOperationException ex)
		{
			Console.ForegroundColor = ConsoleColor.Red;
			Console.WriteLine(ex.Message);
			Console.ResetColor();
			Environment.Exit(1);
		}
		catch (Exception ex)
		{
			Console.ForegroundColor = ConsoleColor.Red;
			Console.WriteLine($"Error: {ex.Message}");
			Console.ResetColor();
			Environment.Exit(1);
		}
	}

	static void PrintReadErrors(System.Collections.Generic.List<ReadError>? errors)
	{
		if (errors == null || errors.Count == 0)
		{
			return;
		}

		Console.ForegroundColor = ConsoleColor.Red;
		Console.WriteLine();
		Console.WriteLine($"{errors.Count} error{(errors.Count == 1 ? "" : "s")} in {(errors[0] as ReadError)?.GetType().Name?.Replace("Error", "").ToLower() ?? "file"}:");
		Console.ResetColor();

		foreach (var error in errors)
		{
			Console.ForegroundColor = ConsoleColor.Yellow;
			Console.Write($"{error.Index}: ");
			Console.ResetColor();
			Console.WriteLine(error.Message);

			if (!string.IsNullOrEmpty(error.Line))
			{
				string line = error.Line.Replace("\t", "    ");
				Console.WriteLine(line);

				Console.ForegroundColor = ConsoleColor.Red;
				Console.Write(new string(' ', error.Char));
				Console.WriteLine(new string('~', error.Length));
				Console.ResetColor();
			}
		}
	}

	static void PrintCheckErrors(System.Collections.Generic.List<CheckError>? errors)
	{
		if (errors == null || errors.Count == 0)
		{
			return;
		}

		Console.ForegroundColor = ConsoleColor.Red;
		Console.WriteLine();
		Console.WriteLine($"{errors.Count} error{(errors.Count == 1 ? "" : "s")} in data:");
		Console.ResetColor();

		foreach (var error in errors)
		{
			Console.ForegroundColor = ConsoleColor.Yellow;
			Console.Write($"{string.Join(".", error.Path)}: ");
			Console.ResetColor();
			Console.WriteLine(error.Message);
		}
	}
}
