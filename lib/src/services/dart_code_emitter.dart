import '../domain/models.dart';
import '../state/workbench_controller.dart';

class DartCodeEmitter {
  String buildEventSnippet({
    required EventReference event,
    required List<BlockInstance> blocks,
  }) {
    if (event.isLifecycle) {
      return [
        '@override',
        'void initState() {',
        '  super.initState();',
        _emitBlockList(blocks, indent: 1),
        '}',
      ].join('\n');
    }

    final callbackParameter = _callbackParameter(event.callbackName);
    final signature = callbackParameter == null
        ? '() {'
        : '($callbackParameter) {';

    return [
      '// ${event.widgetId} -> ${event.callbackName}',
      'on${event.callbackName?.substring(2)}: $signature',
      _emitBlockList(blocks, indent: 1),
      '},',
    ].join('\n');
  }

  String buildScreenPreview(WorkbenchController controller) {
    final initBlocks = controller.blocksForEvent(controller.lifecycleEvent.id);
    final onPressed = _eventBlocks(controller, 'button1', 'onPressed');
    final onLongPress = _eventBlocks(controller, 'button1', 'onLongPress');
    final onChanged = _eventBlocks(controller, 'text1', 'onChanged');
    final onSubmitted = _eventBlocks(controller, 'text1', 'onSubmitted');

    return '''
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class GeneratedScreen extends StatefulWidget {
  const GeneratedScreen({super.key});

  @override
  State<GeneratedScreen> createState() => _GeneratedScreenState();
}

class _GeneratedScreenState extends State<GeneratedScreen> {
  @override
  void initState() {
    super.initState();
${_emitBlockList(initBlocks, indent: 2)}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: () {
${_emitBlockList(onPressed, indent: 4)}
              },
              onLongPress: () {
${_emitBlockList(onLongPress, indent: 4)}
              },
              child: const Text('button1'),
            ),
            const SizedBox(height: 12),
            TextField(
              onChanged: (value) {
${_emitBlockList(onChanged, indent: 4)}
              },
              onSubmitted: (value) {
${_emitBlockList(onSubmitted, indent: 4)}
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'text1',
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 80,
              width: 80,
              color: Colors.black12,
              alignment: Alignment.center,
              child: const Text('image1'),
            ),
          ],
        ),
      ),
    );
  }
}
''';
  }

  List<BlockInstance> _eventBlocks(
    WorkbenchController controller,
    String widgetId,
    String callbackName,
  ) {
    final event = controller.findWidgetEvent(widgetId, callbackName);
    if (event == null) {
      return const <BlockInstance>[];
    }
    return controller.blocksForEvent(event.id).toList(growable: false);
  }

  String _emitBlockList(List<BlockInstance> blocks, {required int indent}) {
    final padding = _indent(indent);
    if (blocks.isEmpty) {
      return '$padding// No blocks yet';
    }
    return blocks
        .map((block) => _emitStatement(block, indent: indent))
        .join('\n');
  }

  String _emitStatement(BlockInstance block, {required int indent}) {
    final padding = _indent(indent);
    switch (block.type) {
      case BlockType.ifElse:
        final condition = _emitExpression(block.condition);
        final thenBody = _emitBlockList(block.thenBranch, indent: indent + 1);
        final elseBody = _emitBlockList(block.elseBranch, indent: indent + 1);
        return [
          '$paddingif ($condition) {',
          thenBody,
          '$padding} else {',
          elseBody,
          '$padding}',
        ].join('\n');
      case BlockType.navigatePage:
        return '$padding'
            'Navigator.of(context).push('
            'MaterialPageRoute(builder: (_) => const Placeholder()));';
      case BlockType.navigationPop:
        return '$padding'
            'Navigator.of(context).pop();';
      case BlockType.flutterToast:
        return '$padding'
            "Fluttertoast.showToast(msg: 'Hello from Flutware');";
      case BlockType.equals:
      case BlockType.lessThan:
      case BlockType.greaterThan:
      case BlockType.and:
      case BlockType.or:
        return '$padding'
            '// Expression block should be attached to an if condition.';
    }
  }

  String _emitExpression(BlockInstance? expression) {
    if (expression == null) {
      return 'true';
    }
    switch (expression.type) {
      case BlockType.equals:
        return 'left == right';
      case BlockType.lessThan:
        return 'left < right';
      case BlockType.greaterThan:
        return 'left > right';
      case BlockType.and:
        return 'left && right';
      case BlockType.or:
        return 'left || right';
      case BlockType.ifElse:
      case BlockType.navigatePage:
      case BlockType.navigationPop:
      case BlockType.flutterToast:
        return 'true';
    }
  }

  String? _callbackParameter(String? callbackName) {
    switch (callbackName) {
      case 'onChanged':
      case 'onSubmitted':
        return 'value';
      default:
        return null;
    }
  }

  String _indent(int level) => '  ' * level;
}

