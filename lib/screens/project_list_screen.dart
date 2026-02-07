import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/project_provider.dart';
import 'editor_screen.dart';

class ProjectListScreen extends ConsumerWidget {
  const ProjectListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Projectlar')),
      body: projects.isEmpty
          ? const Center(child: Text('Hozircha projectlar yo\'q'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: projects.length,
              itemBuilder: (context, index) {
                final project = projects[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(
                      project.appName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('${project.pages.length} ta sahifa'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      ref.read(currentProjectIndexProvider.notifier).state =
                          index;
                      ref.read(currentPageIndexProvider.notifier).state =
                          0; // Default to first page
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EditorScreen(),
                        ),
                      );
                    },
                    onLongPress: () =>
                        _showDeleteDialog(context, ref, index, project.appName),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context, ref),
        label: const Text('Yangi Project'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yangi Project'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Project nomi'),
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
                ref.read(projectProvider.notifier).addProject(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Yaratish'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    int index,
    String name,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Projectni o\'chirish'),
        content: Text('"$name" projectini o\'chirishni xohlaysizmi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Yo\'q'),
          ),
          TextButton(
            onPressed: () {
              ref.read(projectProvider.notifier).deleteProject(index);
              Navigator.pop(context);
            },
            child: const Text('Ha', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
