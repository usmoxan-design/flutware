import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/app_models.dart';
import '../../providers/project_provider.dart';
import '../../renderer/json_renderer.dart';
import '../../utils/apk_builder.dart';

class PreviewTab extends ConsumerStatefulWidget {
  const PreviewTab({super.key});

  @override
  ConsumerState<PreviewTab> createState() => _PreviewTabState();
}

class _PreviewTabState extends ConsumerState<PreviewTab> {
  String? _lastApkPath;

  @override
  Widget build(BuildContext context) {
    final project = ref.watch(currentProjectProvider);
    final page = ref.watch(currentPageProvider);

    if (project == null || page == null) return const SizedBox();

    return Column(
      children: [
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: JsonRenderer(pageData: page, isPreview: true),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: CircleAvatar(
                      backgroundColor: Colors.black54,
                      child: IconButton(
                        icon: const Icon(Icons.fullscreen, color: Colors.white),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Scaffold(
                              appBar: AppBar(title: Text(page.name)),
                              body: JsonRenderer(pageData: page),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            children: [
              ElevatedButton.icon(
                onPressed: () => _handleRun(context, project, page),
                icon: const Icon(Icons.play_arrow),
                label: const Text('RUN (Build & Install)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
              if (_lastApkPath != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Share.shareXFiles([
                          XFile(_lastApkPath!),
                        ], text: '${project.appName} APK'),
                        icon: const Icon(Icons.share),
                        label: const Text('Ulashish'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showLogs(context),
                        icon: const Icon(Icons.list_alt),
                        label: const Text('Loglar'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _handleExportCode(context, page),
                  icon: const Icon(Icons.file_download),
                  label: const Text('Kod (Export)'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    final code = _generateFullDartCode(page);
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (context) => DraggableScrollableSheet(
                        initialChildSize: 0.8,
                        expand: false,
                        builder: (context, scrollController) =>
                            SingleChildScrollView(
                              controller: scrollController,
                              padding: const EdgeInsets.all(16),
                              child: SelectableText(
                                code,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                ),
                              ),
                            ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.code),
                  label: const Text('Kod (Preview)'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _handleRun(
    BuildContext context,
    ProjectData project,
    PageData page,
  ) async {
    final statusNotifier = ValueNotifier<String>("Boshlanmoqda...");

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            ValueListenableBuilder<String>(
              valueListenable: statusNotifier,
              builder: (context, status, _) =>
                  Text(status, textAlign: TextAlign.center),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => _showLogs(context),
              child: const Text('Logs (Batafsil)'),
            ),
          ],
        ),
      ),
    );

    try {
      final path = await ApkBuilder.buildApk(
        project,
        onProgress: (msg) => statusNotifier.value = msg,
      );

      if (context.mounted) Navigator.pop(context);

      if (path != null) {
        setState(() => _lastApkPath = path);
        await ApkBuilder.installApk(path);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Xatolik: APK fayli yaratilmadi.')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Tizim xatosi: $e')));
      }
    } finally {
      statusNotifier.dispose();
    }
  }

  void _showLogs(BuildContext context) {
    final allLogs = ApkBuilder.logs.join('\n');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Build Loglari'),
            IconButton(
              icon: const Icon(Icons.copy_all, size: 20),
              tooltip: 'Nusxalash',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: allLogs));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Loglar nusxalandi')),
                );
              },
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(
              allLogs.isEmpty ? "Hozircha loglar yo'q." : allLogs,
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Yopish'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleExportCode(BuildContext context, PageData page) async {
    final code = _generateFullDartCode(page);
    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/${page.name}_page.dart');
      await file.writeAsString(code);

      await Share.shareXFiles([
        XFile(file.path),
      ], text: '${page.name} Dart kodi');
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Eksportda xatolik: \$e')));
    }
  }

  String _generateFullDartCode(PageData page) {
    final widgets = page.widgets
        .map((w) {
          if (w.type == 'text')
            return '            Text("${w.text}", style: TextStyle(fontSize: ${w.fontSize})),';
          if (w.type == 'button') {
            return '''
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Button clicked!")));
              },
              child: Text("${w.text}"),
            ),''';
          }
          return '';
        })
        .join('\n');

    return '''
import 'package:flutter/material.dart';

void main() => runApp(MaterialApp(home: ${page.name}Page()));

class ${page.name}Page extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${page.name}")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
$widgets
          ],
        ),
      ),
    );
  }
}
''';
  }
}
