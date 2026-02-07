import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/app_models.dart';
import 'logic_interpreter.dart';

class JsonRenderer extends StatelessWidget {
  final PageData pageData;
  const JsonRenderer({super.key, required this.pageData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(pageData.name)),
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
            child: Text(widget.text),
          ),
        );
      default:
        return Text('Unknown widget: \${widget.type}');
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
