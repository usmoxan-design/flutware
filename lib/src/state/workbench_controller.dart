import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../domain/models.dart';

class WorkbenchController extends ChangeNotifier {
  WorkbenchController._({
    required this.widgets,
    required this.lifecycleEvent,
    required Map<String, EventReference> allEvents,
  }) : _allEvents = allEvents {
    for (final event in _allEvents.values) {
      _canvasByEvent[event.id] = <BlockInstance>[];
    }
  }

  final List<WidgetBlueprint> widgets;
  final EventReference lifecycleEvent;
  final Map<String, EventReference> _allEvents;
  final Map<String, List<BlockInstance>> _canvasByEvent = {};

  int _idCounter = 0;

  factory WorkbenchController.bootstrap() {
    final widgets = <WidgetBlueprint>[
      const WidgetBlueprint(
        id: 'button1',
        type: WidgetBlueprintType.button,
        displayName: 'button1',
      ),
      const WidgetBlueprint(
        id: 'text1',
        type: WidgetBlueprintType.textField,
        displayName: 'text1',
      ),
      const WidgetBlueprint(
        id: 'image1',
        type: WidgetBlueprintType.image,
        displayName: 'image1',
      ),
    ];

    const initStateEvent = EventReference(
      id: 'lifecycle:initState',
      title: 'initState',
      subtitle: 'State lifecycle event',
      headerLabel: 'QACHONKI initState ISHGA TUSHGANDA',
      ownerType: EventOwnerType.lifecycle,
    );

    final allEvents = <String, EventReference>{
      initStateEvent.id: initStateEvent,
    };

    for (final widget in widgets) {
      for (final callback in widget.callbacks) {
        final id = 'widget:${widget.id}:${callback.name}';
        allEvents[id] = EventReference(
          id: id,
          title: '${widget.id} • ${callback.label}',
          subtitle: '${widget.typeLabel} callback event',
          headerLabel: _callbackHeader(widget.id, callback.name),
          ownerType: EventOwnerType.widgetCallback,
          widgetId: widget.id,
          callbackName: callback.name,
        );
      }
    }

    return WorkbenchController._(
      widgets: widgets,
      lifecycleEvent: initStateEvent,
      allEvents: allEvents,
    );
  }

  Iterable<EventReference> get allEvents => _allEvents.values;

  EventReference eventById(String eventId) => _allEvents[eventId]!;

  EventReference? findWidgetEvent(String widgetId, String callbackName) {
    for (final event in _allEvents.values) {
      if (event.widgetId == widgetId && event.callbackName == callbackName) {
        return event;
      }
    }
    return null;
  }

  List<EventReference> eventsForWidget(String widgetId) {
    final events = _allEvents.values
        .where((event) => event.widgetId == widgetId)
        .toList(growable: false);
    events.sort((a, b) => a.title.compareTo(b.title));
    return events;
  }

  UnmodifiableListView<BlockInstance> blocksForEvent(String eventId) {
    return UnmodifiableListView(_canvasByEvent[eventId] ?? <BlockInstance>[]);
  }

  void appendRootBlock({
    required String eventId,
    required BlockType type,
  }) {
    final blocks = _canvasByEvent.putIfAbsent(eventId, () => <BlockInstance>[]);
    blocks.add(_makeBlock(type));
    notifyListeners();
  }

  void appendBranchBlock({
    required String eventId,
    required String parentBlockId,
    required bool elseBranch,
    required BlockType type,
  }) {
    final blocks = _canvasByEvent[eventId];
    if (blocks == null) {
      return;
    }

    final inserted = _makeBlock(type);
    _canvasByEvent[eventId] = _rewriteTree(
      blocks,
      targetId: parentBlockId,
      patch: (target) {
        if (!target.isIfElse) {
          return target;
        }
        return BlockInstance(
          id: target.id,
          type: target.type,
          condition: target.condition,
          thenBranch: elseBranch
              ? target.thenBranch
              : [...target.thenBranch, inserted],
          elseBranch: elseBranch
              ? [...target.elseBranch, inserted]
              : target.elseBranch,
        );
      },
    );
    notifyListeners();
  }

  void setConditionBlock({
    required String eventId,
    required String parentBlockId,
    required BlockType type,
  }) {
    final blocks = _canvasByEvent[eventId];
    if (blocks == null) {
      return;
    }

    _canvasByEvent[eventId] = _rewriteTree(
      blocks,
      targetId: parentBlockId,
      patch: (target) {
        if (!target.isIfElse) {
          return target;
        }
        return BlockInstance(
          id: target.id,
          type: target.type,
          condition: _makeBlock(type),
          thenBranch: target.thenBranch,
          elseBranch: target.elseBranch,
        );
      },
    );
    notifyListeners();
  }

  Map<String, List<BlockInstance>> canvasSnapshot() {
    return {
      for (final entry in _canvasByEvent.entries)
        entry.key: List<BlockInstance>.from(entry.value),
    };
  }

  List<BlockInstance> _rewriteTree(
    List<BlockInstance> nodes, {
    required String targetId,
    required BlockInstance Function(BlockInstance target) patch,
  }) {
    return nodes
        .map((node) => _rewriteNode(node, targetId: targetId, patch: patch))
        .toList(growable: false);
  }

  BlockInstance _rewriteNode(
    BlockInstance node, {
    required String targetId,
    required BlockInstance Function(BlockInstance target) patch,
  }) {
    var updated = BlockInstance(
      id: node.id,
      type: node.type,
      condition: node.condition == null
          ? null
          : _rewriteNode(node.condition!, targetId: targetId, patch: patch),
      thenBranch: node.thenBranch
          .map((child) => _rewriteNode(child, targetId: targetId, patch: patch))
          .toList(growable: false),
      elseBranch: node.elseBranch
          .map((child) => _rewriteNode(child, targetId: targetId, patch: patch))
          .toList(growable: false),
    );

    if (updated.id == targetId) {
      updated = patch(updated);
    }
    return updated;
  }

  BlockInstance _makeBlock(BlockType type) {
    final id = 'block_${_idCounter++}';
    return BlockInstance(id: id, type: type);
  }

  static String _callbackHeader(String widgetId, String callbackName) {
    switch (callbackName) {
      case 'onPressed':
        return 'QACHONKI $widgetId BOSILGANDA';
      case 'onLongPress':
        return 'QACHONKI $widgetId UZOQ BOSILGANDA';
      case 'onChanged':
        return 'QACHONKI $widgetId MATNI OZGARGANDA';
      case 'onSubmitted':
        return 'QACHONKI $widgetId SUBMIT QILINGANDA';
      default:
        return 'QACHONKI $widgetId $callbackName';
    }
  }
}

