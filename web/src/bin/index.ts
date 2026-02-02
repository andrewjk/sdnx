#! /usr/bin/env node
import chalk from "chalk";
import read from "../read";
import stringify from "../stringify";
import CheckError from "../types/CheckError";
import ReadError from "../types/ReadError";

const file = process.argv[2];
const schema = process.argv[3];

const result = read(file, schema);

if (result.ok) {
	console.log("\nFile read with no errors.\n");
	console.log(stringify(result.data, { ansi: true, indent: "    " }));
} else {
	printReadErrors(result.schemaErrors);
	printReadErrors(result.dataErrors);
	printCheckErrors(result.checkErrors);
}

function printReadErrors(errors: ReadError[]) {
	if (errors.length) {
		console.log(
			chalk.black.red(
				`\n${errors.length} error${errors.length === 1 ? "" : "s"} in schema file:\n`,
			),
		);
	}
	for (let error of errors) {
		console.log(`${chalk.yellow(error.index)}: ${error.message}`);
		// HACK: If I were less lazy I'd replace tabs with 4 spaces and adjust positions
		console.log(error.line.replaceAll("\t", " "));
		console.log(`${" ".repeat(error.char)}${chalk.red("~".repeat(error.length))}`);
	}
}

function printCheckErrors(errors: CheckError[]) {
	if (errors.length) {
		console.log(
			chalk.black.red(`\n${errors.length} error${errors.length === 1 ? "" : "s"} in data:\n`),
		);
	}
	for (let error of errors) {
		console.log(`${chalk.yellow(error.path.join("."))}: ${error.message}`);
	}
}
