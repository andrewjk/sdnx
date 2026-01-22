#! /usr/bin/env node
import chalk from "chalk";
import read from "../read";

const file = process.argv[2];
const schema = process.argv[3];

const result = read(file, schema);

if (result.ok) {
	console.log(chalk.black.bgGreen(" OK! "));
	console.log(result.data);
} else {
	console.log(chalk.black.bgRed(" ERROR "));
	console.log(result.errors);
}

//console.log(JSON.stringify(result, null, 2));
