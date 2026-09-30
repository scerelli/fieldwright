#!/usr/bin/env node
// Deterministic JSON Schema -> Dart generator for the IBIS protocol format.
//
// Reads schema/protocol.schema.json and emits app/lib/protocol/protocol.dart.
// Running it twice produces byte-identical output and no external codegen tool
// is required, so the committed Dart types can always be re-derived here.
//
// Usage:
//   node scripts/gen-dart.mjs [--out <path>]

import { execFileSync } from 'node:child_process';
import { mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const schemaPath = resolve(here, '../schema/protocol.schema.json');
const defaultOutput = resolve(here, '../../../app/lib/protocol/protocol.dart');
const rootClassName = 'ProtocolDocument';

const dartKeywords = new Set([
  'abstract', 'as', 'assert', 'async', 'await', 'break', 'case', 'catch',
  'class', 'const', 'continue', 'covariant', 'default', 'deferred', 'do',
  'dynamic', 'else', 'enum', 'export', 'extends', 'extension', 'external',
  'factory', 'false', 'final', 'finally', 'for', 'function', 'get', 'hide',
  'if', 'implements', 'import', 'in', 'interface', 'is', 'late', 'library',
  'mixin', 'new', 'null', 'on', 'operator', 'part', 'required', 'rethrow',
  'return', 'set', 'show', 'static', 'super', 'switch', 'sync', 'this',
  'throw', 'true', 'try', 'typedef', 'var', 'void', 'while', 'with', 'yield',
]);

function pascalCase(name) {
  return name.charAt(0).toUpperCase() + name.slice(1);
}

function identifier(name) {
  return dartKeywords.has(name) ? `${name}Value` : name;
}

function docComment(description, indent) {
  if (!description) {
    return '';
  }
  const text = description.replace(/\s+/g, ' ').trim();
  return `${indent}/// ${text}\n`;
}

function readOption(args, name) {
  const index = args.indexOf(name);
  if (index === -1) {
    return undefined;
  }
  const value = args[index + 1];
  if (value === undefined) {
    throw new Error(`Missing value for ${name}`);
  }
  return value;
}

const helperDefinitions = {
  _string: [
    'String _string(Map<String, dynamic> json, String key) {',
    '  final value = json[key];',
    '  if (value is String) {',
    '    return value;',
    '  }',
    '  throw FormatException(\'Expected a string at "$key"\');',
    '}',
  ].join('\n'),
  _int: [
    'int _int(Map<String, dynamic> json, String key) {',
    '  final value = json[key];',
    '  if (value is int) {',
    '    return value;',
    '  }',
    '  throw FormatException(\'Expected an integer at "$key"\');',
    '}',
  ].join('\n'),
  _double: [
    'double _double(Map<String, dynamic> json, String key) {',
    '  final value = json[key];',
    '  if (value is num) {',
    '    return value.toDouble();',
    '  }',
    '  throw FormatException(\'Expected a number at "$key"\');',
    '}',
  ].join('\n'),
  _bool: [
    'bool _bool(Map<String, dynamic> json, String key) {',
    '  final value = json[key];',
    '  if (value is bool) {',
    '    return value;',
    '  }',
    '  throw FormatException(\'Expected a boolean at "$key"\');',
    '}',
  ].join('\n'),
  _object: [
    'Map<String, dynamic> _object(Map<String, dynamic> json, String key) {',
    '  final value = json[key];',
    '  if (value is Map<String, dynamic>) {',
    '    return value;',
    '  }',
    '  throw FormatException(\'Expected an object at "$key"\');',
    '}',
  ].join('\n'),
  _stringList: [
    'List<String> _stringList(Map<String, dynamic> json, String key) {',
    '  final value = json[key];',
    '  if (value is! List) {',
    '    throw FormatException(\'Expected a list at "$key"\');',
    '  }',
    '  return value.map((item) {',
    '    if (item is String) {',
    '      return item;',
    '    }',
    '    throw FormatException(\'Expected a string in "$key"\');',
    '  }).toList();',
    '}',
  ].join('\n'),
  _objectList: [
    'List<T> _objectList<T>(',
    '  Map<String, dynamic> json,',
    '  String key,',
    '  T Function(Map<String, dynamic>) parse,',
    ') {',
    '  final value = json[key];',
    '  if (value is! List) {',
    '    throw FormatException(\'Expected a list at "$key"\');',
    '  }',
    '  return value.map<T>((item) {',
    '    if (item is Map<String, dynamic>) {',
    '      return parse(item);',
    '    }',
    '    throw FormatException(\'Expected an object in "$key"\');',
    '  }).toList();',
    '}',
  ].join('\n'),
  _enumList: [
    'List<T> _enumList<T>(',
    '  Map<String, dynamic> json,',
    '  String key,',
    '  T Function(String) parse,',
    ') {',
    '  final value = json[key];',
    '  if (value is! List) {',
    '    throw FormatException(\'Expected a list at "$key"\');',
    '  }',
    '  return value.map<T>((item) {',
    '    if (item is String) {',
    '      return parse(item);',
    '    }',
    '    throw FormatException(\'Expected a string in "$key"\');',
    '  }).toList();',
    '}',
  ].join('\n'),
};

function generate(schema) {
  const defs = schema.$defs ?? {};
  const enums = [];
  const usedHelpers = new Set();

  function registerEnum(name, values) {
    let entry = enums.find((candidate) => candidate.name === name);
    if (!entry) {
      entry = {
        name,
        values: values.map((wire) => ({
          identifier: identifier(wire),
          wire,
        })),
      };
      enums.push(entry);
    }
    return entry.name;
  }

  function resolveType(node, contextName) {
    if (node.$ref) {
      const refName = node.$ref.split('/').pop();
      const def = defs[refName];
      if (!def) {
        throw new Error(`Unknown $ref: ${node.$ref}`);
      }
      if (def.enum) {
        return { kind: 'enum', name: registerEnum(refName, def.enum) };
      }
      if (def.type === 'object') {
        return { kind: 'class', name: def.title ?? refName };
      }
      if (def.type === 'array') {
        return { kind: 'list', item: resolveType(def.items, contextName) };
      }
      return resolveType(def, contextName);
    }
    if (node.enum) {
      return { kind: 'enum', name: registerEnum(contextName, node.enum) };
    }
    switch (node.type) {
      case 'string':
        return { kind: 'string' };
      case 'integer':
        return { kind: 'int' };
      case 'number':
        return { kind: 'double' };
      case 'boolean':
        return { kind: 'bool' };
      case 'array':
        return { kind: 'list', item: resolveType(node.items, contextName) };
      default:
        throw new Error(`Unsupported schema node: ${JSON.stringify(node)}`);
    }
  }

  function dartType(descriptor) {
    switch (descriptor.kind) {
      case 'string':
        return 'String';
      case 'int':
        return 'int';
      case 'double':
        return 'double';
      case 'bool':
        return 'bool';
      case 'enum':
      case 'class':
        return descriptor.name;
      case 'list':
        return `List<${dartType(descriptor.item)}>`;
      default:
        throw new Error(`Unsupported descriptor: ${descriptor.kind}`);
    }
  }

  function parseExpr(descriptor, key) {
    switch (descriptor.kind) {
      case 'string':
        usedHelpers.add('_string');
        return `_string(json, '${key}')`;
      case 'int':
        usedHelpers.add('_int');
        return `_int(json, '${key}')`;
      case 'double':
        usedHelpers.add('_double');
        return `_double(json, '${key}')`;
      case 'bool':
        usedHelpers.add('_bool');
        return `_bool(json, '${key}')`;
      case 'enum':
        usedHelpers.add('_string');
        return `${descriptor.name}.fromJson(_string(json, '${key}'))`;
      case 'class':
        usedHelpers.add('_object');
        return `${descriptor.name}.fromJson(_object(json, '${key}'))`;
      case 'list':
        return listParseExpr(descriptor.item, key);
      default:
        throw new Error(`Unsupported descriptor: ${descriptor.kind}`);
    }
  }

  function listParseExpr(item, key) {
    switch (item.kind) {
      case 'string':
        usedHelpers.add('_stringList');
        return `_stringList(json, '${key}')`;
      case 'class':
        usedHelpers.add('_objectList');
        return `_objectList<${item.name}>(json, '${key}', ${item.name}.fromJson)`;
      case 'enum':
        usedHelpers.add('_enumList');
        return `_enumList<${item.name}>(json, '${key}', ${item.name}.fromJson)`;
      default:
        throw new Error(`Unsupported list item kind: ${item.kind}`);
    }
  }

  function toJsonExpr(descriptor, ref, nullable) {
    const marker = nullable ? '?' : '';
    switch (descriptor.kind) {
      case 'string':
      case 'int':
      case 'double':
      case 'bool':
        return `${marker}${ref}`;
      case 'enum':
      case 'class':
        return nullable ? `${marker}${ref}?.toJson()` : `${ref}.toJson()`;
      case 'list':
        if (
          descriptor.item.kind === 'string' ||
          descriptor.item.kind === 'int' ||
          descriptor.item.kind === 'double' ||
          descriptor.item.kind === 'bool'
        ) {
          return `${marker}${ref}`;
        }
        return nullable
          ? `${marker}${ref}?.map((value) => value.toJson()).toList()`
          : `${ref}.map((value) => value.toJson()).toList()`;
      default:
        throw new Error(`Unsupported descriptor: ${descriptor.kind}`);
    }
  }

  function buildClass(name, classSchema) {
    const required = new Set(classSchema.required ?? []);
    const properties = classSchema.properties ?? {};
    const fields = Object.entries(properties).map(([key, propSchema]) => {
      const descriptor = resolveType(propSchema, `${name}${pascalCase(key)}`);
      return {
        name: identifier(key),
        key,
        descriptor,
        required: required.has(key),
        description: propSchema.description,
      };
    });
    fields.sort((a, b) => Number(b.required) - Number(a.required));
    return { name, description: classSchema.description, fields };
  }

  const classes = [buildClass(rootClassName, schema)];
  for (const [defName, defSchema] of Object.entries(defs)) {
    if (defSchema.enum) {
      registerEnum(defName, defSchema.enum);
    } else if (defSchema.type === 'object') {
      classes.push(buildClass(defSchema.title ?? defName, defSchema));
    }
  }

  function renderEnum(entry) {
    const lines = [];
    lines.push(`enum ${entry.name} {`);
    entry.values.forEach((value, index) => {
      const separator = index === entry.values.length - 1 ? ';' : ',';
      lines.push(`  ${value.identifier}('${value.wire}')${separator}`);
    });
    lines.push('');
    lines.push(`  const ${entry.name}(this.wireValue);`);
    lines.push('');
    lines.push('  final String wireValue;');
    lines.push('');
    lines.push(`  static ${entry.name} fromJson(String value) {`);
    lines.push('    for (final candidate in values) {');
    lines.push('      if (candidate.wireValue == value) {');
    lines.push('        return candidate;');
    lines.push('      }');
    lines.push('    }');
    lines.push(`    throw FormatException('Unknown ${entry.name}: $value');`);
    lines.push('  }');
    lines.push('');
    lines.push('  String toJson() => wireValue;');
    lines.push('}');
    return lines.join('\n');
  }

  function renderClass(model) {
    const lines = [];
    const doc = docComment(model.description, '');
    if (doc) {
      lines.push(doc.trimEnd());
    }
    lines.push(`class ${model.name} {`);
    lines.push(`  const ${model.name}({`);
    for (const field of model.fields) {
      const modifier = field.required ? 'required ' : '';
      lines.push(`    ${modifier}this.${field.name},`);
    }
    lines.push('  });');
    lines.push('');
    for (const field of model.fields) {
      const fieldDoc = docComment(field.description, '  ');
      if (fieldDoc) {
        lines.push(fieldDoc.trimEnd());
      }
      const type = field.required
        ? dartType(field.descriptor)
        : `${dartType(field.descriptor)}?`;
      lines.push(`  final ${type} ${field.name};`);
    }
    lines.push('');
    lines.push(`  factory ${model.name}.fromJson(Map<String, dynamic> json) {`);
    lines.push(`    return ${model.name}(`);
    for (const field of model.fields) {
      const expr = parseExpr(field.descriptor, field.key);
      if (field.required) {
        lines.push(`      ${field.name}: ${expr},`);
      } else {
        lines.push(
          `      ${field.name}: json['${field.key}'] == null ? null : ${expr},`,
        );
      }
    }
    lines.push('    );');
    lines.push('  }');
    lines.push('');
    lines.push('  Map<String, dynamic> toJson() => {');
    for (const field of model.fields) {
      lines.push(
        `    '${field.key}': ` +
          `${toJsonExpr(field.descriptor, field.name, !field.required)},`,
      );
    }
    lines.push('  };');
    lines.push('}');
    return lines.join('\n');
  }

  const header = [
    '// GENERATED CODE - DO NOT MODIFY.',
    '//',
    '// Generated by packages/protocol/scripts/gen-dart.mjs from',
    '// packages/protocol/schema/protocol.schema.json.',
    '// Run `node packages/protocol/scripts/gen-dart.mjs` to regenerate.',
  ].join('\n');

  const renderedClasses = classes.map(renderClass);
  const helpers = Object.keys(helperDefinitions)
    .filter((name) => usedHelpers.has(name))
    .map((name) => helperDefinitions[name]);

  const blocks = [
    header,
    enums.map(renderEnum).join('\n\n'),
    helpers.join('\n\n'),
    renderedClasses.join('\n\n'),
  ].filter((block) => block.length > 0);

  return `${blocks.join('\n\n')}\n`;
}

function formatDart(path) {
  try {
    execFileSync('dart', ['format', path], { stdio: 'pipe' });
  } catch (error) {
    if (error.code === 'ENOENT') {
      throw new Error(
        'The Dart SDK (`dart`) is required to format the generated code; ' +
          'install Flutter or Dart and put it on PATH, then retry.',
      );
    }
    throw error;
  }
}

function main() {
  const args = process.argv.slice(2);
  const output = readOption(args, '--out') ?? defaultOutput;
  const schema = JSON.parse(readFileSync(schemaPath, 'utf8'));
  mkdirSync(dirname(output), { recursive: true });
  writeFileSync(output, generate(schema));
  formatDart(output);
}

main();
