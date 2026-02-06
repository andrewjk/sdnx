/* --------------------------------------------------------------------------------------------
 * Copyright (c) Microsoft Corporation. All rights reserved.
 * Licensed under the MIT License. See License.txt in the project root for license information.
 * ------------------------------------------------------------------------------------------ */
import {
	createConnection,
	TextDocuments,
	Diagnostic,
	DiagnosticSeverity,
	ProposedFeatures,
	InitializeParams,
	DidChangeConfigurationNotification,
	CompletionItem,
	CompletionItemKind,
	TextDocumentPositionParams,
	TextDocumentSyncKind,
	InitializeResult,
	DocumentDiagnosticReportKind,
	type DocumentDiagnosticReport,
	Hover
} from 'vscode-languageserver/node';

import {
	TextDocument
} from 'vscode-languageserver-textdocument';

import { URI } from 'vscode-uri';

import * as fs from 'fs';
import * as path from 'path';

// Import parsing functions from web package
// Using require with path resolution to handle the ES module nature of the web package
const sdnxPath = path.resolve(__dirname, '../../../web/dist/index.mjs');

// Create a connection for the server, using Node's IPC as a transport.
// Also include all preview / proposed LSP features.
const connection = createConnection(ProposedFeatures.all);

// Create a simple text document manager.
const documents = new TextDocuments(TextDocument);

let hasConfigurationCapability = false;
let hasWorkspaceFolderCapability = false;
let hasDiagnosticRelatedInformationCapability = false;

connection.onInitialize((params: InitializeParams) => {
	const capabilities = params.capabilities;

	// Does the client support the `workspace/configuration` request?
	// If not, we fall back using global settings.
	hasConfigurationCapability = !!(
		capabilities.workspace && !!capabilities.workspace.configuration
	);
	hasWorkspaceFolderCapability = !!(
		capabilities.workspace && !!capabilities.workspace.workspaceFolders
	);
	hasDiagnosticRelatedInformationCapability = !!(
		capabilities.textDocument &&
		capabilities.textDocument.publishDiagnostics &&
		capabilities.textDocument.publishDiagnostics.relatedInformation
	);

	const result: InitializeResult = {
		capabilities: {
			textDocumentSync: TextDocumentSyncKind.Incremental,
			// Tell the client that this server supports code completion.
			completionProvider: {
				resolveProvider: true
			},
			// Tell the client that this server supports hover.
			hoverProvider: true,
			diagnosticProvider: {
				interFileDependencies: false,
				workspaceDiagnostics: false
			}
		}
	};
	if (hasWorkspaceFolderCapability) {
		result.capabilities.workspace = {
			workspaceFolders: {
				supported: true
			}
		};
	}
	return result;
});

connection.onInitialized(() => {
	if (hasConfigurationCapability) {
		// Register for all configuration changes.
		connection.client.register(DidChangeConfigurationNotification.type, undefined);
	}
	if (hasWorkspaceFolderCapability) {
		connection.workspace.onDidChangeWorkspaceFolders(_event => {
			connection.console.log('Workspace folder change event received.');
		});
	}
});

// The example settings
interface ExampleSettings {
	maxNumberOfProblems: number;
}

// The global settings, used when the `workspace/configuration` request is not supported by the client.
// Please note that this is not the case when using this server with the client provided in this example
// but could happen with other clients.
const defaultSettings: ExampleSettings = { maxNumberOfProblems: 1000 };
let globalSettings: ExampleSettings = defaultSettings;

// Cache the settings of all open documents
const documentSettings = new Map<string, Thenable<ExampleSettings>>();

connection.onDidChangeConfiguration(change => {
	if (hasConfigurationCapability) {
		// Reset all cached document settings
		documentSettings.clear();
	} else {
		globalSettings = (
			(change.settings.sdnxLanguageServer || defaultSettings)
		);
	}
	// Refresh the diagnostics since the `maxNumberOfProblems` could have changed.
	// We could optimize things here and re-fetch the setting first can compare it
	// to the existing setting, but this is out of scope for this example.
	connection.languages.diagnostics.refresh();
});

function getDocumentSettings(resource: string): Thenable<ExampleSettings> {
	if (!hasConfigurationCapability) {
		return Promise.resolve(globalSettings);
	}
	let result = documentSettings.get(resource);
	if (!result) {
		result = connection.workspace.getConfiguration({
			scopeUri: resource,
			section: 'sdnxLanguageServer'
		});
		documentSettings.set(resource, result);
	}
	return result;
}

// Only keep settings for open documents
documents.onDidClose(e => {
	documentSettings.delete(e.document.uri);
});


connection.languages.diagnostics.on(async (params) => {
	const document = documents.get(params.textDocument.uri);
	if (document !== undefined) {
		return {
			kind: DocumentDiagnosticReportKind.Full,
			items: await validateTextDocument(document)
		} satisfies DocumentDiagnosticReport;
	} else {
		// We don't know the document. We can either try to read it from disk
		// or we don't report problems for it.
		return {
			kind: DocumentDiagnosticReportKind.Full,
			items: []
		} satisfies DocumentDiagnosticReport;
	}
});

// The content of a text document has changed. This event is emitted
// when the text document first opened or when its content has changed.
documents.onDidChangeContent(change => {
	validateTextDocument(change.document);
});

async function validateTextDocument(textDocument: TextDocument): Promise<Diagnostic[]> {
	const text = textDocument.getText();
	const diagnostics: Diagnostic[] = [];

	// Determine file type and use appropriate parser
	const fileName = textDocument.uri.toLowerCase();
	try {
		// Dynamically import the sdnx module
		const sdnx = await import(sdnxPath);
		if (fileName.endsWith('.sdnx')) {
			// Parse schema file
			const parsed = sdnx.parseSchema(text);
			if (!parsed.ok) {
				for (const error of parsed.errors) {
					diagnostics.push({
						severity: DiagnosticSeverity.Error,
						range: {
							start: textDocument.positionAt(error.index),
							end: textDocument.positionAt(error.index + (error.length || 1))
						},
						message: error.message,
						source: 'sdnx'
					});
				}
				return diagnostics
			}
		} else if (fileName.endsWith('.sdn')) {
			// Parse data file
			const parsed = sdnx.parse(text, true);
			if (!parsed.ok) {
				for (const error of parsed.errors) {
					diagnostics.push({
						severity: DiagnosticSeverity.Error,
						range: {
							start: textDocument.positionAt(error.index),
							end: textDocument.positionAt(error.index + (error.length || 1))
						},
						message: error.message,
						source: 'sdn'
					});
				}
				return diagnostics
			}

			// If there's a @schema directive, try to load the schema from there
			const match = text.match(/^\s*@schema\("(.+?)"\)/);
			if (match === null) {
				return diagnostics
			}

			const filePath = path.dirname(URI.parse(textDocument.uri).path)
			const schemaFile = path.resolve(filePath, match[1]);
			if (!fs.existsSync(schemaFile)) {
				diagnostics.push({
					severity: DiagnosticSeverity.Error,
					range: {
						start: textDocument.positionAt(0),
						end: textDocument.positionAt(match[0].length)
					},
					message: `Schema not found at '${schemaFile}'`,
					source: 'sdn'
				});
				return diagnostics;
			}

			// TODO: Handle fetching from a URL
			const schemaContents = fs.readFileSync(schemaFile, "utf-8");
			const schemaParsed = sdnx.parseSchema(schemaContents);
			if (!schemaParsed.ok) {
				diagnostics.push({
					severity: DiagnosticSeverity.Error,
					range: {
						start: textDocument.positionAt(0),
						end: textDocument.positionAt(match[0].length)
					},
					message: "Schema has errors",
					source: 'sdn'
				});
				return diagnostics
			}

			const checked = sdnx.check(parsed.data, schemaParsed.data);
			if (!checked.ok) {
				for (const error of checked.errors) {
					let errorIndex = 0;
					let errorLength = 1;
					const map = parsed.mapping[error.path.join(".")];
					if (map !== undefined) {
						errorIndex = map.valueIndex;
						errorLength = map.valueLength;
					}
					diagnostics.push({
						severity: DiagnosticSeverity.Error,
						range: {
							start: textDocument.positionAt(errorIndex),
							end: textDocument.positionAt(errorIndex + (errorLength || 1))
						},
						message: error.message,
						source: 'sdnx'
					});
				}
				return diagnostics
			}
		}
	} catch (error) {
		connection.console.error(`Failed to parse document: ${error}`);
	}

	return diagnostics;
}

connection.onDidChangeWatchedFiles(_change => {
	// Monitored files have change in VSCode
	connection.console.log('We received a file change event');
});

// This handler provides the initial list of the completion items.
connection.onCompletion(
	async (textDocumentPosition: TextDocumentPositionParams): Promise<CompletionItem[]> => {
		const document = documents.get(textDocumentPosition.textDocument.uri);
		if (!document) {
			return [];
		}

		const fileName = document.uri.toLowerCase();
		
		// Only provide field completions for SDN files
		if (!fileName.endsWith('.sdn')) {
			return [];
		}

		const text = document.getText();
		
		// Find the @schema directive
		const schemaMatch = text.match(/@schema\s*\(\s*["']([^"']+)["']\s*\)/);
		if (!schemaMatch) {
			return [];
		}

		const schemaPath = schemaMatch[1];
		
		// Resolve the schema file path relative to the document
		const documentDir = path.dirname(document.uri.replace('file://', ''));
		const resolvedSchemaPath = path.resolve(documentDir, schemaPath);

		try {
			// Read and parse the schema file
			const schemaContent = fs.readFileSync(resolvedSchemaPath, 'utf-8');
			
			// Parse the sdnx file to get field names
			const sdnx = await import(sdnxPath);
			const schemaResult = sdnx.parseSchema(schemaContent);
			
			if (!schemaResult.ok) {
				return [];
			}

			// Parse the SDN file to get existing fields
			// HACK: We can't parse the SDN file because it won't be valid!
			//const sdnResult = sdnx.parse(text);
			//const existingFields = sdnResult.ok ? Object.keys(sdnResult.data) : [];
			const existingFields = text.match( /\b(.+?):/g)?.map(m => m.substring(0, m.length - 1)) ?? [];

			// Extract field names from the schema
			const schemaFields = extractFieldNamesFromSchema(schemaResult.data);
			
			// Filter out fields that already exist in the SDN file
			const availableFields = schemaFields.filter(field => !existingFields.includes(field));

			// Create completion items for each available field
			return availableFields.map(fieldName => ({
				label: fieldName,
				kind: CompletionItemKind.Property,
				detail: schemaResult.data[fieldName].description ?? 'Field from schema',
				insertText: `${fieldName}: `,
				data: fieldName
			}));
		} catch (error) {
			connection.console.error(`Failed to provide completions: ${error}`);
			return [];
		}
	}
);

// This handler resolves additional information for the item selected in
// the completion list.
connection.onCompletionResolve(
	(item: CompletionItem): CompletionItem => {
		if (item.data === 1) {
			item.detail = 'TypeScript details';
			item.documentation = 'TypeScript documentation';
		} else if (item.data === 2) {
			item.detail = 'JavaScript details';
			item.documentation = 'JavaScript documentation';
		}
		return item;
	}
);

// Hover handler to show field descriptions from linked schema files
connection.onHover((params): Hover | null => {
	const document = documents.get(params.textDocument.uri);
	if (!document) {
		return null;
	}

	const text = document.getText();
	const position = params.position;
	const offset = document.offsetAt(position);

	// Get the word at the cursor position
	const wordRange = getWordRangeAtPosition(text, offset);
	if (!wordRange) {
		return null;
	}

	const fieldName = text.substring(wordRange.start, wordRange.end);

	// Find the @schema directive
	const schemaMatch = text.match(/@schema\s*\(\s*["']([^"']+)["']\s*\)/);
	if (!schemaMatch) {
		return null;
	}

	const schemaPath = schemaMatch[1];

	// Resolve the schema file path relative to the document
	const documentDir = path.dirname(params.textDocument.uri.replace('file://', ''));
	const resolvedSchemaPath = path.resolve(documentDir, schemaPath);

	try {
		// Read the schema file
		const schemaContent = fs.readFileSync(resolvedSchemaPath, 'utf-8');

		// Find the field description and validators in the schema
		const fieldInfo = findFieldInfo(schemaContent, fieldName);

		if (fieldInfo) {
			let hoverContent = '';
			
			if (fieldInfo.description) {
				hoverContent += fieldInfo.description + '\n\n';
			}

			const hasType = fieldInfo.type !== null;
			const hasValidators = fieldInfo.validators && fieldInfo.validators.length > 0;
			if (hasType || hasValidators) {
				const parts: string[] = []
				if (fieldInfo.type) {
					parts.push(fieldInfo.type);
				}
				if (hasValidators) {
					fieldInfo.validators.forEach(validator => {
						parts.push(`${validator.name}${validator.value ? `(${validator.value})` : ""}`);
					});
				}
				hoverContent += `Type: \`${parts.join(" ")}\``
			}
			
			if (hoverContent) {
				return {
					contents: {
						kind: 'markdown',
						value: hoverContent.trim()
					}
				};
			}
		}
	} catch (error) {
		connection.console.error(`Failed to read schema file: ${error}`);
	}

	return null;
});

// Helper function to get the word at a position
function getWordRangeAtPosition(text: string, offset: number): { start: number; end: number } | null {
	// Find the start of the word
	let start = offset;
	while (start > 0 && /[a-zA-Z0-9_]/.test(text[start - 1])) {
		start--;
	}

	// Find the end of the word
	let end = offset;
	while (end < text.length && /[a-zA-Z0-9_]/.test(text[end])) {
		end++;
	}

	if (start === end) {
		return null;
	}

	return { start, end };
}

// Helper function to find field description in schema content
function findFieldDescription(schemaContent: string, fieldName: string): string | null {
	const fieldInfo = findFieldInfo(schemaContent, fieldName);
	return fieldInfo?.description ?? null;
}

// Helper function to find field info (description, type, and validators) in schema content
function findFieldInfo(schemaContent: string, fieldName: string): { description: string | null; type: string | null; validators: { name: string; value: string | null }[] } | null {
	const lines = schemaContent.split('\n');

	for (let i = 0; i < lines.length; i++) {
		const line = lines[i];

		// Check if this line defines the field we're looking for
		const fieldMatch = line.match(new RegExp(`^\\s*${fieldName}\\s*:`));
		if (fieldMatch) {
			let description: string | null = null;
			let fieldType: string | null = null;
			const validators: { name: string; value: string | null }[] = [];

			// Look for a description comment on the previous line
			if (i > 0) {
				const prevLine = lines[i - 1];
				const descMatch = prevLine.match(/^\s*##\s*(.+)$/);
				if (descMatch) {
					description = descMatch[1].trim();
				}
			}

			// Parse type and validators from the field definition line
			// Field format: fieldName: type validatorName(value) validatorName2
			const afterColon = line.substring(line.indexOf(':') + 1);
			
			// First, try to extract the type (bool, int, num, date, string, null, undef)
			const typeMatch = afterColon.match(/^\s*(bool|int|num|date|string|null|undef)\b/);
			if (typeMatch) {
				fieldType = typeMatch[1];
			}
			
			// Also check for union types (e.g., "null | string")
			const unionMatch = afterColon.match(/\|\s*(bool|int|num|date|string|null|undef)\b/);
			if (unionMatch && fieldType) {
				fieldType += ` | ${unionMatch[1]}`;
			} else if (unionMatch && !fieldType) {
				fieldType = unionMatch[1];
			}
			
			// Match validators with optional values
			// Examples: min(18), max(65), minlen(2), pattern(/regex/), optional validators without parentheses
			const validatorRegex = /\b(min|max|minlen|maxlen|pattern|true|false)\b(?:\(([^)]*)\))?/g;
			let validatorMatch;
			
			while ((validatorMatch = validatorRegex.exec(afterColon)) !== null) {
				const validatorName = validatorMatch[1];
				const validatorValue = validatorMatch[2] || null;
				
				validators.push({
					name: validatorName,
					value: validatorValue
				});
			}

			return { description, type: fieldType, validators };
		}
	}

	return null;
}

// Helper function to extract field names from parsed schema
function extractFieldNamesFromSchema(schema: any): string[] {
	const fields: string[] = [];
	
	if (typeof schema !== 'object' || schema === null) {
		return fields;
	}
	
	for (const [key, value] of Object.entries(schema)) {
		// Skip internal definitions and mix/props
		if (key.startsWith('def$') || key.startsWith('mix$') || key.startsWith('props$') || key.startsWith('any$')) {
			continue;
		}
		
		// Skip special schema types like @mix results
		if (key === 'type' && typeof value === 'string') {
			continue;
		}
		
		fields.push(key);
	}
	
	return fields;
}

// Make the text document manager listen on the connection
// for open, change and close text document events
documents.listen(connection);

// Listen on the connection
connection.listen();
