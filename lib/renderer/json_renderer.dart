import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/app_models.dart';
import 'logic_interpreter.dart';

class JsonRenderer extends StatelessWidget {
  final PageData pageData;
  final bool isPreview;

  const JsonRenderer({
    super.key,
    required this.pageData,
    this.isPreview = false,
  });

  @override
  Widget build(BuildContext context) {
    // Run onCreate logic once when page builds (if not in a simple preview list)
    // Note: In a real app, logic execution should be managed better (e.g. initState)
    // For this minimal case, we'll simplify.

    return Scaffold(
      appBar: AppBar(
        title: Text(pageData.name),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: pageData.widgets
              .map((w) => _buildWidget(context, w))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildWidget(BuildContext context, WidgetData widget) {
    switch (widget.type) {
      case 'text':
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(widget.text, style: TextStyle(fontSize: widget.fontSize)),
        );
      case 'button':
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: ElevatedButton(
            onPressed: () => _handleEvent(context, widget.id, 'onClicked'),
            onLongPress: () {
              HapticFeedback.vibrate();
              _handleEvent(context, widget.id, 'onLongPressed');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(widget.text),
          ),
        );
      default:
        return Text('Unknown widget: ${widget.type}');
    }
  }

  void _handleEvent(BuildContext context, String widgetId, String eventType) {
    final logic = pageData.logic[widgetId];
    if (logic != null) {
      final actions = eventType == 'onClicked'
          ? logic.onClicked
          : logic.onLongPressed;
      LogicInterpreter.run(actions, context);
    }
  }
}
