import 'package:flutter/material.dart';

enum BlockCategory {
  variable(Color(0xFFFF7043), Icons.data_object),
  control(Color(0xFFF4B400), Icons.account_tree),
  operator(Color(0xFF00A65A), Icons.functions),
  view(Color(0xFF1E88E5), Icons.visibility);

  final Color color;
  final IconData icon;
  const BlockCategory(this.color, this.icon);
}

class BlockParameter {
  final String label;
  final String key;
  final String type;
  final dynamic defaultValue;

  const BlockParameter({
    required this.label,
    required this.key,
    required this.type,
    this.defaultValue,
  });
}

class BlockDefinition {
  final String type;
  final String name;
  final BlockCategory category;
  final List<BlockParameter> parameters;

  const BlockDefinition({
    required this.type,
    required this.name,
    required this.category,
    this.parameters = const [],
  });
}

class BlockRegistry {
  static const List<BlockDefinition> blocks = [
    BlockDefinition(
      type: 'set_variable',
      name: 'set variable',
      category: BlockCategory.variable,
      parameters: [
        BlockParameter(
          label: 'name',
          key: 'name',
          type: 'text',
          defaultValue: 'value',
        ),
        BlockParameter(
          label: 'value',
          key: 'value',
          type: 'text',
          defaultValue: '0',
        ),
      ],
    ),
    BlockDefinition(
      type: 'if',
      name: 'if (condition)',
      category: BlockCategory.control,
      parameters: [
        BlockParameter(
          label: 'condition',
          key: 'condition',
          type: 'text',
          defaultValue: 'true',
        ),
      ],
    ),
    BlockDefinition(
      type: 'if_else',
      name: 'if / else',
      category: BlockCategory.control,
      parameters: [
        BlockParameter(
          label: 'condition',
          key: 'condition',
          type: 'text',
          defaultValue: 'true',
        ),
      ],
    ),
    BlockDefinition(
      type: 'equals',
      name: 'a == b',
      category: BlockCategory.operator,
      parameters: [
        BlockParameter(label: 'a', key: 'a', type: 'text', defaultValue: '1'),
        BlockParameter(label: 'b', key: 'b', type: 'text', defaultValue: '1'),
      ],
    ),
    BlockDefinition(
      type: 'set_enabled',
      name: 'setEnabled(widget)',
      category: BlockCategory.view,
      parameters: [
        BlockParameter(
          label: 'widgetId',
          key: 'widgetId',
          type: 'text',
          defaultValue: 'button1',
        ),
        BlockParameter(
          label: 'enabled',
          key: 'enabled',
          type: 'text',
          defaultValue: 'true',
        ),
      ],
    ),
    BlockDefinition(
      type: 'request_focus',
      name: 'requestFocus(widget)',
      category: BlockCategory.view,
      parameters: [
        BlockParameter(
          label: 'widgetId',
          key: 'widgetId',
          type: 'text',
          defaultValue: 'text1',
        ),
      ],
    ),
    BlockDefinition(
      type: 'get_width',
      name: 'getWidth(widget)',
      category: BlockCategory.view,
      parameters: [
        BlockParameter(
          label: 'widgetId',
          key: 'widgetId',
          type: 'text',
          defaultValue: 'view1',
        ),
      ],
    ),
    BlockDefinition(
      type: 'get_height',
      name: 'getHeight(widget)',
      category: BlockCategory.view,
      parameters: [
        BlockParameter(
          label: 'widgetId',
          key: 'widgetId',
          type: 'text',
          defaultValue: 'view1',
        ),
      ],
    ),
  ];

  static BlockDefinition? get(String type) {
    try {
      return blocks.firstWhere((b) => b.type == type);
    } catch (_) {
      return null;
    }
  }
}
