import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/app_models.dart';
import 'logic_interpreter.dart';

class JsonRenderer extends StatelessWidget {
  final PageData pageData;
  final ProjectData? projectData;
  final bool isPreview;
  final String? selectedWidgetId;
  final ValueChanged<String>? onWidgetTap;

  const JsonRenderer({
    super.key,
    required this.pageData,
    this.projectData,
    this.isPreview = false,
    this.selectedWidgetId,
    this.onWidgetTap,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = _parseColor(projectData?.colorPrimary);
    final accentColor = _parseColor(projectData?.colorAccent);

    return Scaffold(
      appBar: AppBar(
        title: Text(pageData.name),
        backgroundColor: primaryColor,
        elevation: 2,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: accentColor,
        child: const Icon(Icons.add),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: pageData.widgets
              .map(
                (widget) =>
                    _buildWidget(context, widget, primaryColor, accentColor),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildWidget(
    BuildContext context,
    WidgetData widget,
    Color primaryColor,
    Color accentColor,
  ) {
    switch (widget.type) {
      case 'text':
        return _wrapSelectable(
          widget,
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              widget.text,
              style: TextStyle(
                fontSize: widget.fontSize,
                color: Colors.black87,
              ),
            ),
          ),
        );
      case 'button':
        return _wrapSelectable(
          widget,
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: ElevatedButton(
              onPressed: widget.enabled
                  ? () => _handleEvent(context, widget.id, 'onClicked')
                  : null,
              onLongPress: widget.enabled
                  ? () {
                      HapticFeedback.vibrate();
                      _handleEvent(context, widget.id, 'onLongPressed');
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(widget.text),
            ),
          ),
        );
      case 'row':
        return _wrapSelectable(
          widget,
          _buildLayoutContainer(
            context,
            widget,
            primaryColor,
            accentColor,
            axis: Axis.horizontal,
            label: 'Row',
            icon: Icons.view_column,
          ),
        );
      case 'column':
        return _wrapSelectable(
          widget,
          _buildLayoutContainer(
            context,
            widget,
            primaryColor,
            accentColor,
            axis: Axis.vertical,
            label: 'Column',
            icon: Icons.view_stream,
          ),
        );
      default:
        return _wrapSelectable(widget, Text('Unknown widget: ${widget.type}'));
    }
  }

  Widget _buildLayoutContainer(
    BuildContext context,
    WidgetData widget,
    Color primaryColor,
    Color accentColor, {
    required Axis axis,
    required String label,
    required IconData icon,
  }) {
    final children = _readChildren(widget);
    final title = widget.text.isEmpty ? label : widget.text;
    final childWidgets = children
        .map((child) => _buildWidget(context, child, primaryColor, accentColor))
        .toList();

    final header = Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade700),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Text(
          '${children.length} items',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: axis == Axis.horizontal
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                header,
                const SizedBox(height: 8),
                children.isEmpty
                    ? _emptyLayoutHint(label)
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: childWidgets
                            .map(
                              (item) => Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  child: item,
                                ),
                              ),
                            )
                            .toList(),
                      ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                header,
                const SizedBox(height: 8),
                children.isEmpty
                    ? _emptyLayoutHint(label)
                    : Column(children: childWidgets),
              ],
            ),
    );
  }

  Widget _emptyLayoutHint(String label) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        '$label ichida child yo\'q',
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      ),
    );
  }

  Widget _wrapSelectable(WidgetData widget, Widget child) {
    final selected = selectedWidgetId != null && selectedWidgetId == widget.id;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onWidgetTap == null ? null : () => onWidgetTap!(widget.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? Colors.lightBlue : Colors.transparent,
            width: 2,
          ),
          color: selected
              ? Colors.lightBlue.withValues(alpha: 0.1)
              : Colors.transparent,
        ),
        child: child,
      ),
    );
  }

  List<WidgetData> _readChildren(WidgetData widget) {
    final raw = widget.properties['children'];
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((entry) {
      return WidgetData.fromJson(Map<String, dynamic>.from(entry));
    }).toList();
  }

  Color _parseColor(String? hexString) {
    if (hexString == null || hexString.isEmpty) return Colors.blue;
    try {
      return Color(int.parse(hexString));
    } catch (_) {
      return Colors.blue;
    }
  }

  void _handleEvent(BuildContext context, String widgetId, String eventType) {
    final logic = pageData.logic[widgetId];
    if (logic != null) {
      final actions = eventType == 'onClicked'
          ? logic.onClicked
          : logic.onLongPressed;
      LogicInterpreter.run(actions, context, project: projectData);
    }
  }
}
