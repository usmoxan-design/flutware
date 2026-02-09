import 'package:flutter/material.dart';

import 'models.dart';

class BlockCatalog {
  static const List<BlockDefinition> all = [
    BlockDefinition(
      type: BlockType.ifElse,
      label: 'if / else',
      category: BlockCategory.control,
      shape: BlockShape.statement,
      color: Color(0xFFC8A82B),
    ),
    BlockDefinition(
      type: BlockType.equals,
      label: '==',
      category: BlockCategory.operator,
      shape: BlockShape.expression,
      color: Color(0xFF2FA65A),
    ),
    BlockDefinition(
      type: BlockType.lessThan,
      label: '<',
      category: BlockCategory.operator,
      shape: BlockShape.expression,
      color: Color(0xFF2FA65A),
    ),
    BlockDefinition(
      type: BlockType.greaterThan,
      label: '>',
      category: BlockCategory.operator,
      shape: BlockShape.expression,
      color: Color(0xFF2FA65A),
    ),
    BlockDefinition(
      type: BlockType.and,
      label: 'and',
      category: BlockCategory.operator,
      shape: BlockShape.expression,
      color: Color(0xFF2FA65A),
    ),
    BlockDefinition(
      type: BlockType.or,
      label: 'or',
      category: BlockCategory.operator,
      shape: BlockShape.expression,
      color: Color(0xFF2FA65A),
    ),
    BlockDefinition(
      type: BlockType.navigatePage,
      label: 'Flutter navigating page',
      category: BlockCategory.view,
      shape: BlockShape.statement,
      color: Color(0xFF1E78C9),
    ),
    BlockDefinition(
      type: BlockType.navigationPop,
      label: 'Navigation Pop()',
      category: BlockCategory.view,
      shape: BlockShape.statement,
      color: Color(0xFF1E78C9),
    ),
    BlockDefinition(
      type: BlockType.flutterToast,
      label: 'Flutter toast',
      category: BlockCategory.view,
      shape: BlockShape.statement,
      color: Color(0xFF1E78C9),
    ),
  ];

  static List<BlockDefinition> byCategory(
    BlockCategory category, {
    String query = '',
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    final items = all.where((block) => block.category == category);
    if (normalizedQuery.isEmpty) {
      return items.toList(growable: false);
    }
    return items
        .where((block) => block.label.toLowerCase().contains(normalizedQuery))
        .toList(growable: false);
  }

  static BlockDefinition definitionOf(BlockType type) {
    return all.firstWhere((block) => block.type == type);
  }
}

