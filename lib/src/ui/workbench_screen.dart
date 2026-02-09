import 'package:flutter/material.dart';

import '../domain/models.dart';
import '../state/workbench_controller.dart';
import 'block_editor_screen.dart';
import 'code_preview_screen.dart';

class WorkbenchScreen extends StatefulWidget {
  const WorkbenchScreen({super.key});

  @override
  State<WorkbenchScreen> createState() => _WorkbenchScreenState();
}

class _WorkbenchScreenState extends State<WorkbenchScreen>
    with SingleTickerProviderStateMixin {
  late final WorkbenchController _controller;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _controller = WorkbenchController.bootstrap();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutware / Flutterware'),
        actions: [
          IconButton(
            onPressed: _openCodePreview,
            icon: const Icon(Icons.code),
            tooltip: 'Generated code preview',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Event'),
            Tab(text: 'View'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _EventTab(
            controller: _controller,
            onOpenInitState: _openInitStateEditor,
          ),
          _ViewTab(
            controller: _controller,
            onOpenWidgetEvent: _openWidgetEventEditor,
          ),
        ],
      ),
    );
  }

  void _openInitStateEditor() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlockEditorScreen(
          controller: _controller,
          eventId: _controller.lifecycleEvent.id,
        ),
      ),
    );
  }

  void _openWidgetEventEditor(EventReference event) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlockEditorScreen(
          controller: _controller,
          eventId: event.id,
        ),
      ),
    );
  }

  void _openCodePreview() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CodePreviewScreen(controller: _controller),
      ),
    );
  }
}

class _EventTab extends StatelessWidget {
  const _EventTab({
    required this.controller,
    required this.onOpenInitState,
  });

  final WorkbenchController controller;
  final VoidCallback onOpenInitState;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final event = controller.lifecycleEvent;
        final blockCount = controller.blocksForEvent(event.id).length;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 10,
                    offset: Offset(0, 4),
                    color: Color(0x12000000),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Lifecycle Event',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(event.title),
                    subtitle: Text(
                      '${event.subtitle}\nBlocks: $blockCount',
                    ),
                    isThreeLine: true,
                    trailing: const Icon(Icons.arrow_forward_ios_rounded),
                    onTap: onOpenInitState,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ViewTab extends StatelessWidget {
  const _ViewTab({
    required this.controller,
    required this.onOpenWidgetEvent,
  });

  final WorkbenchController controller;
  final ValueChanged<EventReference> onOpenWidgetEvent;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: controller.widgets.length,
      itemBuilder: (context, index) {
        final widgetNode = controller.widgets[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                blurRadius: 8,
                offset: Offset(0, 4),
                color: Color(0x10000000),
              ),
            ],
          ),
          child: ListTile(
            title: Text(widgetNode.displayName),
            subtitle: Text(widgetNode.typeLabel),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _openWidgetInspector(context, widgetNode),
          ),
        );
      },
    );
  }

  void _openWidgetInspector(BuildContext context, WidgetBlueprint widgetNode) {
    final events = controller.eventsForWidget(widgetNode.id);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widgetNode.displayName} (${widgetNode.typeLabel})',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Properties',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFFF1F5FB),
                ),
                child: const Text('Property editor section (extensible).'),
              ),
              const SizedBox(height: 18),
              const Text(
                'Events (callbacks)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              ...events.map(
                (event) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(event.callbackName ?? event.title),
                  subtitle: const Text('Opens independent block canvas'),
                  trailing: const Icon(Icons.play_arrow_rounded),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    onOpenWidgetEvent(event);
                  },
                ),
              ),
              if (events.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('No callback events for this widget.'),
                ),
            ],
          ),
        );
      },
    );
  }
}

