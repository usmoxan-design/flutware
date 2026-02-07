import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/app_models.dart';
import '../../providers/project_provider.dart';

class UiTab extends ConsumerWidget {
  const UiTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(currentProjectProvider);
    final page = ref.watch(currentPageProvider);
    final projectIndex = ref.watch(currentProjectIndexProvider);
    final pageIndex = ref.watch(currentPageIndexProvider);

    if (project == null || page == null) return const SizedBox();

    return Column(
      children: [
        Expanded(
          child: ReorderableListView(
            padding: const EdgeInsets.all(16),
            onReorder: (oldIndex, newIndex) {
              if (newIndex > oldIndex) newIndex -= 1;
              final widgets = [...page.widgets];
              final item = widgets.removeAt(oldIndex);
              widgets.insert(newIndex, item);
              _updatePage(
                ref,
                project,
                projectIndex!,
                pageIndex!,
                page.copyWith(widgets: widgets),
              );
            },
            children: page.widgets.asMap().entries.map((entry) {
              final idx = entry.key;
              final w = entry.value;
              return Card(
                key: ValueKey(w.id),
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(
                    w.type == 'button' ? Icons.smart_button : Icons.text_fields,
                  ),
                  title: Text(w.text),
                  subtitle: Text('ID: ${w.id}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (w.type == 'button')
                        IconButton(
                          icon: const Icon(
                            Icons.bolt,
                            color: Colors.blueAccent,
                          ),
                          onPressed: () => _showLogicDialog(
                            context,
                            ref,
                            project,
                            projectIndex!,
                            pageIndex!,
                            page,
                            w.id,
                          ),
                        ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.grey),
                        onPressed: () => _removeWidget(
                          ref,
                          project,
                          projectIndex!,
                          pageIndex!,
                          page,
                          idx,
                        ),
                      ),
                    ],
                  ),
                  onLongPress: () {
                    HapticFeedback.vibrate();
                  },
                ),
              );
            }).toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: () => _showAddWidgetDialog(
              context,
              ref,
              project,
              projectIndex!,
              pageIndex!,
              page,
            ),
            icon: const Icon(Icons.add),
            label: const Text('Widget qo\'shish'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ),
      ],
    );
  }

  void _showAddWidgetDialog(
    BuildContext context,
    WidgetRef ref,
    ProjectData project,
    int pIdx,
    int pgIdx,
    PageData page,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.text_fields),
            title: const Text('Text'),
            onTap: () {
              Navigator.pop(context);
              _showWidgetPropsDialog(
                context,
                ref,
                project,
                pIdx,
                pgIdx,
                page,
                'text',
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.smart_button),
            title: const Text('Button'),
            onTap: () {
              Navigator.pop(context);
              _showWidgetPropsDialog(
                context,
                ref,
                project,
                pIdx,
                pgIdx,
                page,
                'button',
              );
            },
          ),
        ],
      ),
    );
  }

  void _showLogicDialog(
    BuildContext context,
    WidgetRef ref,
    ProjectData project,
    int pIdx,
    int pgIdx,
    PageData page,
    String wId,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final logic = page.logic[wId] ?? WidgetLogic();
          return DraggableScrollableSheet(
            initialChildSize: 0.7,
            expand: false,
            builder: (context, scrollController) => Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                controller: scrollController,
                children: [
                  Text(
                    'ID: $wId - Logika',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildActionSection(
                    context,
                    'Bosilganda (onClicked)',
                    logic.onClicked,
                    (actions) {
                      _updateWidgetLogic(
                        ref,
                        project,
                        pIdx,
                        pgIdx,
                        page,
                        wId,
                        onClicked: actions,
                      );
                      setDialogState(() {});
                    },
                  ),
                  const SizedBox(height: 24),
                  _buildActionSection(
                    context,
                    'Uzoq bosib turilganda (onLongPressed)',
                    logic.onLongPressed,
                    (actions) {
                      _updateWidgetLogic(
                        ref,
                        project,
                        pIdx,
                        pgIdx,
                        page,
                        wId,
                        onLongPressed: actions,
                      );
                      setDialogState(() {});
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionSection(
    BuildContext context,
    String title,
    List<ActionBlock> actions,
    Function(List<ActionBlock>) onUpdate,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blueAccent,
          ),
        ),
        const SizedBox(height: 8),
        ...actions.asMap().entries.map((entry) {
          final idx = entry.key;
          final action = entry.value;
          return Card(
            color: Colors.blue.shade50,
            margin: const EdgeInsets.only(bottom: 4),
            child: ListTile(
              title: Text('Toast: ${action.data['message']}'),
              trailing: IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () {
                  final newActions = [...actions];
                  newActions.removeAt(idx);
                  onUpdate(newActions);
                },
              ),
            ),
          );
        }),
        TextButton.icon(
          onPressed: () => _showAddBlockDialog(context, actions, onUpdate),
          icon: const Icon(Icons.add_box_outlined),
          label: const Text('Blok Qo\'shish'),
        ),
      ],
    );
  }

  void _showAddBlockDialog(
    BuildContext context,
    List<ActionBlock> actions,
    Function(List<ActionBlock>) onUpdate,
  ) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Toast qo\'shish'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Toast xabari'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Bekor qilish'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                onUpdate([...actions, ActionBlock.toast(controller.text)]);
                Navigator.pop(context);
              }
            },
            child: const Text('Qo\'shish'),
          ),
        ],
      ),
    );
  }

  void _updateWidgetLogic(
    WidgetRef ref,
    ProjectData project,
    int pIdx,
    int pgIdx,
    PageData page,
    String wId, {
    List<ActionBlock>? onClicked,
    List<ActionBlock>? onLongPressed,
  }) {
    final currentLogic = page.logic[wId] ?? WidgetLogic();
    final newLogic = WidgetLogic(
      onClicked: onClicked ?? currentLogic.onClicked,
      onLongPressed: onLongPressed ?? currentLogic.onLongPressed,
    );
    final newLogicMap = {...page.logic, wId: newLogic};
    _updatePage(ref, project, pIdx, pgIdx, page.copyWith(logic: newLogicMap));
  }

  void _showWidgetPropsDialog(
    BuildContext context,
    WidgetRef ref,
    ProjectData project,
    int pIdx,
    int pgIdx,
    PageData page,
    String type,
  ) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(type == 'text' ? 'Text qo\'shish' : 'Button qo\'shish'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: type == 'text' ? 'Text tarkibi' : 'Button yozuvi',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Bekor qilish'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                final id = '${type.substring(0, 3)}_${page.widgets.length + 1}';
                final newWidget = WidgetData(
                  id: id,
                  type: type,
                  properties: {
                    type == 'text' ? 'text' : 'label': controller.text,
                    if (type == 'text') 'fontSize': 18.0,
                  },
                );
                final updatedPage = page.copyWith(
                  widgets: [...page.widgets, newWidget],
                );
                _updatePage(ref, project, pIdx, pgIdx, updatedPage);
                Navigator.pop(context);
              }
            },
            child: const Text('Qo\'shish'),
          ),
        ],
      ),
    );
  }

  void _removeWidget(
    WidgetRef ref,
    ProjectData project,
    int pIdx,
    int pgIdx,
    PageData page,
    int widgetIdx,
  ) {
    final widgets = [...page.widgets];
    widgets.removeAt(widgetIdx);
    _updatePage(ref, project, pIdx, pgIdx, page.copyWith(widgets: widgets));
  }

  void _updatePage(
    WidgetRef ref,
    ProjectData project,
    int pIdx,
    int pgIdx,
    PageData newPage,
  ) {
    final pages = [...project.pages];
    pages[pgIdx] = newPage;
    ref
        .read(projectProvider.notifier)
        .updateProject(pIdx, project.copyWith(pages: pages));
  }
}
