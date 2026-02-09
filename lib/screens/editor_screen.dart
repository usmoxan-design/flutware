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
    final projectIndex = ref.watch(currentProjectIndexProvider);

    if (project == null || page == null) {
      return const Scaffold(body: Center(child: Text('Yuklanmoqda...')));
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Flutterware', style: TextStyle(fontSize: 18)),
              Text(
                project.appName,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          bottom: TabBar(
            tabs: [
              const Tab(text: 'View'),
              const Tab(text: 'Event'),
              const Tab(text: 'Build APK'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.undo),
              tooltip: 'Undo',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Undo hozircha mavjud emas')),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.redo),
              tooltip: 'Redo',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Redo hozircha mavjud emas')),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.save_outlined),
              tooltip: 'Save',
              onPressed: () {
                if (projectIndex != null) {
                  ref
                      .read(projectProvider.notifier)
                      .updateProject(projectIndex, project);
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Loyiha saqlandi')),
                );
              },
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                switch (value) {
                  case 'pages':
                    _showPageSettings(context, ref);
                    break;
                  case 'cache':
                    _clearBuildCache(context);
                    break;
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'pages', child: Text('Sahifalar')),
                PopupMenuItem(
                  value: 'cache',
                  child: Text('Build cache tozalash'),
                ),
              ],
            ),
          ],
        ),
        body: TabBarView(
          children: [const UiTab(), const LogicTab(), const PreviewTab()],
        ),
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
        builder: (context, setDialogState) {
          String? errorText;

          bool validateName(String name) {
            if (name.isEmpty) return false;
            // Faqat harflar va pastki chiziq, raqamlar mumkin emas
            // UpperCamelCase yoki under_line qoidasiga mosligini tekshirish (faqat formatni emas, taqiqlangan belgilarni)
            final validPattern = RegExp(r'^[a-zA-Z_]+$');
            if (!validPattern.hasMatch(name)) return false;
            if (RegExp(r'\d').hasMatch(name))
              return false; // Raqamlar taqiqlangan
            return true;
          }

          return AlertDialog(
            title: const Text('Yangi Sahifa'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: 'Sahifa nomi (masalan: HomePage)',
                    errorText: errorText,
                    helperText: 'Faqat harflar va _ (raqamlar mumkin emas)',
                  ),
                  onChanged: (val) {
                    setDialogState(() {
                      if (!validateName(val)) {
                        errorText = 'Nom noto\'g\'ri formatda';
                      } else {
                        errorText = null;
                      }
                    });
                  },
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
                  final name = nameController.text.trim();
                  if (validateName(name)) {
                    final newPage = PageData(
                      id: 'page_${DateTime.now().millisecondsSinceEpoch}',
                      name: name,
                      type: type,
                    );
                    final updatedProject = project.copyWith(
                      pages: [...project.pages, newPage],
                    );
                    ref
                        .read(projectProvider.notifier)
                        .updateProject(pIdx, updatedProject);
                    Navigator.pop(context);
                  } else {
                    setDialogState(() {
                      errorText = 'Nom qoidalarga mos emas!';
                    });
                  }
                },
                child: const Text('Qo\'shish'),
              ),
            ],
          );
        },
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
