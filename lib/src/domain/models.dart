import 'package:flutter/material.dart';

enum EventOwnerType { lifecycle, widgetCallback }

enum WidgetBlueprintType { button, textField, image }

enum BlockCategory { variable, control, operator, view }

enum BlockShape { statement, expression }

enum BlockType {
  ifElse,
  equals,
  lessThan,
  greaterThan,
  and,
  or,
  navigatePage,
  navigationPop,
  flutterToast,
}

class WidgetCallbackDefinition {
  const WidgetCallbackDefinition({
    required this.name,
    required this.label,
  });

  final String name;
  final String label;
}

class WidgetBlueprint {
  const WidgetBlueprint({
    required this.id,
    required this.type,
    required this.displayName,
  });

  final String id;
  final WidgetBlueprintType type;
  final String displayName;

  List<WidgetCallbackDefinition> get callbacks {
    switch (type) {
      case WidgetBlueprintType.button:
        return const [
          WidgetCallbackDefinition(name: 'onPressed', label: 'onPressed'),
          WidgetCallbackDefinition(name: 'onLongPress', label: 'onLongPress'),
        ];
      case WidgetBlueprintType.textField:
        return const [
          WidgetCallbackDefinition(name: 'onChanged', label: 'onChanged'),
          WidgetCallbackDefinition(name: 'onSubmitted', label: 'onSubmitted'),
        ];
      case WidgetBlueprintType.image:
        return const [];
    }
  }

  String get typeLabel {
    switch (type) {
      case WidgetBlueprintType.button:
        return 'Button';
      case WidgetBlueprintType.textField:
        return 'TextField';
      case WidgetBlueprintType.image:
        return 'Image';
    }
  }
}

class EventReference {
  const EventReference({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.headerLabel,
    required this.ownerType,
    this.widgetId,
    this.callbackName,
  });

  final String id;
  final String title;
  final String subtitle;
  final String headerLabel;
  final EventOwnerType ownerType;
  final String? widgetId;
  final String? callbackName;

  bool get isLifecycle => ownerType == EventOwnerType.lifecycle;
}

class BlockDefinition {
  const BlockDefinition({
    required this.type,
    required this.label,
    required this.category,
    required this.shape,
    required this.color,
  });

  final BlockType type;
  final String label;
  final BlockCategory category;
  final BlockShape shape;
  final Color color;
}

class BlockInstance {
  const BlockInstance({
    required this.id,
    required this.type,
    this.condition,
    this.thenBranch = const <BlockInstance>[],
    this.elseBranch = const <BlockInstance>[],
  });

  final String id;
  final BlockType type;
  final BlockInstance? condition;
  final List<BlockInstance> thenBranch;
  final List<BlockInstance> elseBranch;

  bool get isIfElse => type == BlockType.ifElse;
}

