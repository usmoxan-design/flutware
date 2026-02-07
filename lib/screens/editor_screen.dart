import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../models/app_models.dart';
import '../providers/project_provider.dart';
import 'tabs/ui_tab.dart';
import 'tabs/logic_tab.dart';
import 'tabs/preview_tab.dart';

class EditorScreen extends ConsumerWidget {
  const EditorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(currentProjectProvider);
    final page = ref.watch(currentPageProvider);

    if (project == null || page == null) {
      return const Scaffold(body: Center(child: Text('Yuklanmoqda...')));
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            children: [
              Text(project.appName, style: const TextStyle(fontSize: 14)),
              Text(
                page.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'UI'),
              Tab(text: 'initState'),
              Tab(text: 'Ko\'rish'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.orange),
              tooltip: 'Cacheni tozalash',
              onPressed: () => _clearBuildCache(context),
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => _showPageSettings(context, ref),
            ),
          ],
        ),
        body: const TabBarView(children: [UiTab(), LogicTab(), PreviewTab()]),
      ),
    );
  }

  void _showPageSettings(BuildContext context, WidgetRef ref) {
    final project = ref.read(currentProjectProvider);
    final projectIndex = ref.read(currentProjectIndexProvider);
    if (project == null || projectIndex == null) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Sahifalar',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ...project.pages.asMap().entries.map((entry) {
            final idx = entry.key;
            final p = entry.value;
            return ListTile(
              title: Text(p.name),
              subtitle: Text(p.type),
              selected: ref.watch(currentPageIndexProvider) == idx,
              onTap: () {
                ref.read(currentPageIndexProvider.notifier).state = idx;
                Navigator.pop(context);
              },
              trailing: project.pages.length > 1
                  ? IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        _deletePage(ref, project, projectIndex, idx);
                        Navigator.pop(context);
                      },
                    )
                  : null,
            );
          }),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('Yangi Sahifa Qo\'shish'),
            onTap: () {
              Navigator.pop(context);
              _showAddPageDialog(context, ref, project, projectIndex);
            },
          ),
        ],
      ),
    );
  }

  void _showAddPageDialog(
    BuildContext context,
    WidgetRef ref,
    ProjectData project,
    int pIdx,
  ) {
    final nameController = TextEditingController();
    String type = 'StatelessWidget';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Yangi Sahifa'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(hintText: 'Sahifa nomi'),
              ),
              const SizedBox(height: 16),
              DropdownButton<String>(
                value: type,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(
                    value: 'StatelessWidget',
                    child: Text('StatelessWidget'),
                  ),
                  DropdownMenuItem(
                    value: 'StatefulWidget',
                    child: Text('StatefulWidget'),
                  ),
                ],
                onChanged: (val) => setDialogState(() => type = val!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Bekor qilish'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  final newPage = PageData(
                    id: 'page_${project.pages.length + 1}',
                    name: nameController.text,
                    type: type,
                  );
                  final updatedProject = project.copyWith(
                    pages: [...project.pages, newPage],
                  );
                  ref
                      .read(projectProvider.notifier)
                      .updateProject(pIdx, updatedProject);
                  Navigator.pop(context);
                }
              },
              child: const Text('Qo\'shish'),
            ),
          ],
        ),
      ),
    );
  }

  void _deletePage(WidgetRef ref, ProjectData project, int pIdx, int pgIdx) {
    final pages = [...project.pages];
    pages.removeAt(pgIdx);
    ref
        .read(projectProvider.notifier)
        .updateProject(pIdx, project.copyWith(pages: pages));
    ref.read(currentPageIndexProvider.notifier).state = 0;
  }

  Future<void> _clearBuildCache(BuildContext context) async {
    try {
      final directory = await getTemporaryDirectory();
      if (directory.existsSync()) {
        final files = directory.listSync();
        int count = 0;
        for (var file in files) {
          if (file is File && file.path.endsWith('.apk')) {
            file.deleteSync();
            count++;
          }
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$count ta eski build fayllari tozalandi.')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Tozalashda xatolik: $e')));
      }
    }
  }
}
