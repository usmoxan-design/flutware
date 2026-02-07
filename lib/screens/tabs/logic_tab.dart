import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/app_models.dart';
import '../../providers/project_provider.dart';

class LogicTab extends ConsumerStatefulWidget {
  const LogicTab({super.key});

  @override
  ConsumerState<LogicTab> createState() => _LogicTabState();
}

class _LogicTabState extends ConsumerState<LogicTab> {
  @override
  Widget build(BuildContext context) {
    final project = ref.watch(currentProjectProvider);
    final page = ref.watch(currentPageProvider);
    final projectIndex = ref.watch(currentProjectIndexProvider);
    final pageIndex = ref.watch(currentPageIndexProvider);

    if (project == null || page == null) return const SizedBox();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sahifa initState Logikasi',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildActionSection(
            context,
            'Sahifa yuklanganda (initState)',
            page.onCreate,
            (actions) => _updatePage(
              ref,
              project,
              projectIndex!,
              pageIndex!,
              page.copyWith(onCreate: actions),
            ),
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),
          const Text(
            'Eslatma: Widgetlar logikasi (onClicked, onLongPressed) UI sahifasidagi widgetlarning o\'zida (bolt ikonkasida) o\'zgartiriladi.',
            style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
          ),
          const SizedBox(height: 32),
          Center(
            child: ElevatedButton.icon(
              onPressed: () => _showCodePreview(context, page),
              icon: const Icon(Icons.code),
              label: const Text('Sahifa Kodini Ko\'rish'),
            ),
          ),
        ],
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
              onLongPress: () {
                HapticFeedback.vibrate();
                final newActions = [...actions];
                newActions.removeAt(idx);
                onUpdate(newActions);
              },
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

  void _showCodePreview(BuildContext context, PageData page) {
    final code = _generateDartCode(page);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Dart Kodi',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.grey.shade100,
                  width: double.infinity,
                  child: SelectableText(
                    code,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _generateDartCode(PageData page) {
    // Basic generator for the read-only view
    final widgets = page.widgets
        .map((w) {
          if (w.type == 'text')
            return '        Text("${w.text}", style: TextStyle(fontSize: ${w.fontSize})),';
          if (w.type == 'button')
            return '        ElevatedButton(onPressed: () {}, child: Text("${w.text}")),';
          return '';
        })
        .join('\n');

    return '''
import 'package:flutter/material.dart';

class ${page.name}Page extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${page.name}")),
      body: Column(
        children: [
$widgets
        ],
      ),
    );
  }
}
''';
  }
}
