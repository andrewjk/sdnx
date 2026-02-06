/* --------------------------------------------------------------------------------------------
 * Copyright (c) Microsoft Corporation. All rights reserved.
 * Licensed under the MIT License. See License.txt in the project root for license information.
 * ------------------------------------------------------------------------------------------ */

import * as vscode from 'vscode';
import * as assert from 'assert';
import { getDocUri, activate } from './helper';

suite('Should show hover', () => {
	const docUri = getDocUri('hover.sdn');

	test('Shows description from linked schema on hover', async () => {
		await testHover(
			docUri,
			new vscode.Position(3, 2), // Position on the 'skills' field
			'This is a test description for the skills field'
		);
	});
});

async function testHover(
	docUri: vscode.Uri,
	position: vscode.Position,
	expectedContent: string
) {
	await activate(docUri);

	// Executing the command `vscode.executeHoverProvider` to simulate hover
	const hovers = (await vscode.commands.executeCommand(
		'vscode.executeHoverProvider',
		docUri,
		position
	)) as vscode.Hover[];

	assert.ok(hovers.length > 0, 'Expected at least one hover result');
	
	// Check if any hover contains the expected description
	const hasExpectedContent = hovers.some(hover => {
		const contents = hover.contents;
		return contents.some(content => {
			if (typeof content === 'string') {
				return content.includes(expectedContent);
			} else if ('value' in content) {
				return content.value.includes(expectedContent);
			}
			return false;
		});
	});

	assert.ok(
		hasExpectedContent,
		`Expected hover to contain "${expectedContent}" but got: ${JSON.stringify(hovers)}`
	);
}
