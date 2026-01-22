import fs from "node:fs";
import { expect, test } from "vitest";
import { parseSchema } from "../src";
import check from "../src/check";
import parse from "../src/parse";
import stringify from "../src/stringify";

const ONLY_TEST = 0;

// Could do this more efficiently
const path = "../SPEC.md";
const lines = fs.readFileSync(path, "utf-8").split("\n");

let tests: {
	schema: string;
	input: string;
	expected: string;
	header: string;
}[] = [];
for (let i = 0; i < lines.length; i++) {
	if (lines[i].startsWith("```````````````````````````````` example")) {
		let example: string[] = [];
		for (let j = i + 1; j < lines.length; j++) {
			if (lines[j].startsWith("````````````````````````````````")) {
				let [schema, input, expected] = example
					.join("\n")
					.replaceAll("→", "\t")
					.split("\n.")
					.map((p) => p.trim());
				//expected ??= "OK";
				let header = `spec example ${tests.length + 1}, line ${i + 1}: '${input.replaceAll(/\s+/g, " ")}'`;
				tests.push({ schema, input, expected, header });
				i = j;
				break;
			} else {
				example.push(lines[j]);
			}
		}
	}
}

for (let run of tests) {
	if (ONLY_TEST && !run.header.includes(`Example ${ONLY_TEST},`)) {
		continue;
	}

	// To diagnose infinite loops; run with `npx vitest --disable-console-intercept`
	//console.log("DOING", test.header);

	let result = "OK";
	//let failed = false;

	try {
		const schema = parseSchema(run.schema);
		const input = parse(run.input);
		const checkResult = check(input, schema);
		if (checkResult.ok) {
			if (run.expected) {
				result = stringify(input);
			} else {
				run.expected = "OK";
			}
		} else {
			result = `Error: ${checkResult.errors.map((e) => e.message).join("")}`;
		}
	} catch (ex) {
		//console.log("ERROR:", test.header);
		result = `${ex}`.replace(/ \[\d+\]/, "");
		//failed = true;
	}

	//if (failed) {
	test(run.header, () => {
		expect(result).toBe(run.expected);
	});
	//}

	/*
	if (failed) {
		console.log("FAILED: " + test.header);
		console.log(test.input.replaceAll("\n", "↵"));
		console.log("---------|".repeat(Math.ceil(test.input.length / 10)));
		console.log("\nEXPECTED");
		console.log(test.expected.replaceAll(" ", "•"));
		console.log("\nACTUAL");
		console.log(html.replaceAll(" ", "•"));
		console.log("\nAST");
		console.log(JSON.stringify(tidyFields(parse(test.input), OUTPUT_FIELDS), null, 2));
		console.log("\n");
		break;
	} else if (ONLY_TEST) {
		console.log("\nSUCCEEDED: " + test.header);
		console.log(test.input.replaceAll("\n", "↵"));
		console.log("---------|".repeat(Math.ceil(test.input.length / 10)));
		console.log("\nOUTPUT");
		console.log(html.replaceAll(" ", "•"));
		console.log("\nAST");
		console.log(JSON.stringify(tidyFields(parse(test.input), OUTPUT_FIELDS), null, 2));
		console.log("\n");
		break;
	}
	*/
}
