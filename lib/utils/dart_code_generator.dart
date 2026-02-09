import '../models/app_models.dart';

class DartCodeGenerator {
  static String generate(ProjectData project, PageData page) {
    return generatePageSource(
      project,
      page,
      includeMain: true,
      useNamedRoutes: false,
    );
  }

  static String generatePageSource(
    ProjectData project,
    PageData page, {
    required bool includeMain,
    required bool useNamedRoutes,
    String? classNameOverride,
    Map<String, String>? routeByPageId,
    Map<String, String>? classByPageId,
    Map<String, String>? fileByPageId,
  }) {
    final className = classNameOverride ?? '${_toPascal(page.name)}Page';
    final isStateful = page.type == 'StatefulWidget';

    final usedBlockTypes = <String>{};
    final targetPageIds = <String>{};

    void collect(List<ActionBlock> actions) {
      for (final action in actions) {
        usedBlockTypes.add(action.type);
        if (action.type == 'navigate' && action.data['targetPageId'] != null) {
          targetPageIds.add(action.data['targetPageId'].toString());
        }
      }
    }

    collect(page.onCreate);
    for (final logic in page.logic.values) {
      collect(logic.onClicked);
      collect(logic.onLongPressed);
    }

    final imports = <String>["import 'package:flutter/material.dart';"];
    if (usedBlockTypes.contains('toast')) {
      imports.add("import 'package:fluttertoast/fluttertoast.dart';");
    }

    if (!useNamedRoutes) {
      for (final id in targetPageIds) {
        final targetPage = project.pages.firstWhere(
          (p) => p.id == id,
          orElse: () => PageData(id: '', name: 'unknown'),
        );
        if (targetPage.id.isNotEmpty) {
          final fileName =
              fileByPageId?[targetPage.id] ??
              '${_toSnake(targetPage.name)}_page.dart';
          imports.add("import '$fileName';");
        }
      }
    }

    final importStr = imports.toSet().join('\n');
    final widgets = page.widgets
        .map(
          (widget) => _generateWidgetCode(
            project,
            widget,
            logicById: page.logic,
            indent: '            ',
            useNamedRoutes: useNamedRoutes,
            routeByPageId: routeByPageId,
            classByPageId: classByPageId,
          ),
        )
        .join('\n');

    final initStateCode = generateActionBlocksOnly(
      project,
      page.onCreate,
      indent: '    ',
      useNamedRoutes: useNamedRoutes,
      routeByPageId: routeByPageId,
      classByPageId: classByPageId,
    );

    final body =
        '''
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
$widgets
          ],
        ),
      ),
''';

    final classCode = isStateful
        ? '''
class $className extends StatefulWidget {
  const $className({super.key});

  @override
  State<$className> createState() => _${className}State();
}

class _${className}State extends State<$className> {
  @override
  void initState() {
    super.initState();
${initStateCode.isEmpty ? '    // Sahifa yuklanganda bajariladigan kodlar' : initStateCode}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("${_escapeDartString(page.name)}"),
        centerTitle: true,
        backgroundColor: Color(${project.colorPrimary}),
        foregroundColor: Colors.white,
      ),
$body
    );
  }
}
'''
        : '''
class $className extends StatelessWidget {
  const $className({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("${_escapeDartString(page.name)}"),
        centerTitle: true,
        backgroundColor: Color(${project.colorPrimary}),
        foregroundColor: Colors.white,
      ),
$body
    );
  }
}
''';

    if (!includeMain) {
      return '$importStr\n\n$classCode';
    }

    return '''
$importStr

void main() => runApp(const MaterialApp(home: $className()));

$classCode
''';
  }

  static Map<String, String> generateFlutterProjectFiles(ProjectData project) {
    final pages = project.pages.isEmpty
        ? [PageData(id: 'home', name: 'Home', type: 'StatelessWidget')]
        : project.pages;

    final pageSpecs = _buildPageSpecs(pages);
    final routeByPageId = <String, String>{
      for (final spec in pageSpecs) spec.page.id: spec.routeName,
    };
    final classByPageId = <String, String>{
      for (final spec in pageSpecs) spec.page.id: spec.className,
    };
    final fileByPageId = <String, String>{
      for (final spec in pageSpecs) spec.page.id: spec.fileName,
    };

    final hasToast = _projectUsesBlockType(pages, 'toast');
    final files = <String, String>{};

    files['pubspec.yaml'] = _generatePubspec(project, hasToast: hasToast);
    files['analysis_options.yaml'] = '''
include: package:flutter_lints/flutter.yaml
''';
    files['README.md'] =
        '''
# ${project.appName}

Generated by Flutware.

## Run

1. Install Flutter SDK.
2. Open this folder in Android Studio.
3. Run `flutter pub get`.
4. If platform folders are missing, run `flutter create .`.
5. Run on device/emulator.
''';

    files['lib/main.dart'] = _generateProjectMainFile(project, pageSpecs);

    for (final spec in pageSpecs) {
      files['lib/pages/${spec.fileName}'] = generatePageSource(
        project,
        spec.page,
        includeMain: false,
        useNamedRoutes: true,
        classNameOverride: spec.className,
        routeByPageId: routeByPageId,
        classByPageId: classByPageId,
        fileByPageId: fileByPageId,
      );
    }

    return files;
  }

  static String _generateWidgetCode(
    ProjectData project,
    WidgetData widget, {
    required Map<String, WidgetLogic> logicById,
    required String indent,
    required bool useNamedRoutes,
    Map<String, String>? routeByPageId,
    Map<String, String>? classByPageId,
  }) {
    final logic = logicById[widget.id];
    final onClickedCode = generateActionBlocksOnly(
      project,
      logic?.onClicked ?? [],
      indent: '$indent    ',
      useNamedRoutes: useNamedRoutes,
      routeByPageId: routeByPageId,
      classByPageId: classByPageId,
    );
    final onLongPressedCode = generateActionBlocksOnly(
      project,
      logic?.onLongPressed ?? [],
      indent: '$indent    ',
      useNamedRoutes: useNamedRoutes,
      routeByPageId: routeByPageId,
      classByPageId: classByPageId,
    );

    final innerIndent = '$indent  ';
    final children = _childrenOf(widget);

    switch (widget.type) {
      case 'text':
        return '''
$indent Padding(
$indent   padding: const EdgeInsets.symmetric(vertical: 8.0),
$indent   child: Text(
$indent     "${_escapeDartString(widget.text)}",
$indent     style: const TextStyle(fontSize: ${widget.fontSize}),
$indent   ),
$indent ),''';
      case 'button':
        final enabled = widget.enabled;
        final onPressedBody = onClickedCode.isEmpty
            ? '$indent      // Tugma bosilganda'
            : onClickedCode;
        final onLongPressedBody = onLongPressedCode.isEmpty
            ? '$indent      // Tugma bosib turilganda'
            : onLongPressedCode;
        return '''
${indent}Padding(
$indent  padding: const EdgeInsets.symmetric(vertical: 8.0),
$indent  child: ElevatedButton(
$indent    onPressed: ${enabled ? '() {\n$onPressedBody\n$indent    }' : 'null'},
$indent    onLongPress: ${enabled ? '() {\n$onLongPressedBody\n$indent    }' : 'null'},
$indent    style: ElevatedButton.styleFrom(
$indent      padding: const EdgeInsets.symmetric(vertical: 12),
$indent    ),
$indent    child: Text("${_escapeDartString(widget.text)}"),
$indent  ),
$indent),''';
      case 'row':
        final rowChildren = children.isEmpty
            ? '$innerIndent  const SizedBox.shrink(),'
            : children
                  .map(
                    (child) => _generateWidgetCode(
                      project,
                      child,
                      logicById: logicById,
                      indent: '$innerIndent  ',
                      useNamedRoutes: useNamedRoutes,
                      routeByPageId: routeByPageId,
                      classByPageId: classByPageId,
                    ),
                  )
                  .map(
                    (code) =>
                        '$innerIndent  Expanded(\n$innerIndent    child: Column(\n$innerIndent      children: [\n$code\n$innerIndent      ],\n$innerIndent    ),\n$innerIndent  ),',
                  )
                  .join('\n');
        return '''
$indent Padding(
$indent  padding: const EdgeInsets.symmetric(vertical: 8.0),
$indent  child: Row(
$indent    crossAxisAlignment: CrossAxisAlignment.start,
$indent    children: [
$rowChildren
$indent    ],
$indent  ),
$indent),''';
      case 'column':
        final columnChildren = children.isEmpty
            ? '$innerIndent  const SizedBox.shrink(),'
            : children
                  .map(
                    (child) => _generateWidgetCode(
                      project,
                      child,
                      logicById: logicById,
                      indent: '$innerIndent  ',
                      useNamedRoutes: useNamedRoutes,
                      routeByPageId: routeByPageId,
                      classByPageId: classByPageId,
                    ),
                  )
                  .join('\n');
        return '''
$indent Padding(
$indent  padding: const EdgeInsets.symmetric(vertical: 8.0),
$indent  child: Column(
$indent    crossAxisAlignment: CrossAxisAlignment.stretch,
$indent    children: [
$columnChildren
$indent    ],
$indent  ),
$indent),''';
      default:
        return '$indent const SizedBox(), // Noma\'lum widget: ${widget.type}';
    }
  }

  static List<WidgetData> _childrenOf(WidgetData widget) {
    final raw = widget.properties['children'];
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((entry) {
      return WidgetData.fromJson(Map<String, dynamic>.from(entry));
    }).toList();
  }

  static String generateActionBlocksOnly(
    ProjectData project,
    List<ActionBlock> actions, {
    String indent = '',
    bool useNamedRoutes = false,
    Map<String, String>? routeByPageId,
    Map<String, String>? classByPageId,
  }) {
    if (actions.isEmpty) return '';

    return actions
        .map((action) {
          switch (action.type) {
            case 'toast':
              return '$indent  Fluttertoast.showToast(msg: "${_escapeDartString(action.data['message']?.toString() ?? '')}");';
            case 'snackbar':
              return '''
$indent  ScaffoldMessenger.of(context).showSnackBar(
$indent    const SnackBar(
$indent      content: Text("${_escapeDartString(action.data['message']?.toString() ?? '')}"),
$indent      backgroundColor: Colors.green,
$indent      behavior: SnackBarBehavior.floating,
$indent    ),
$indent  );''';
            case 'navigate':
              final targetPageId = action.data['targetPageId']?.toString();
              if (targetPageId == null || targetPageId.isEmpty) {
                return '$indent  // Navigate target topilmadi';
              }
              if (useNamedRoutes) {
                final routeName = routeByPageId?[targetPageId] ?? '/';
                return '$indent  Navigator.pushNamed(context, \'$routeName\');';
              }
              final targetPage = project.pages.firstWhere(
                (p) => p.id == targetPageId,
                orElse: () => PageData(id: '', name: 'Unknown'),
              );
              final targetClassName =
                  classByPageId?[targetPage.id] ??
                  '${_toPascal(targetPage.name)}Page';
              return '''
$indent  Navigator.push(
$indent    context,
$indent    MaterialPageRoute(builder: (context) => const $targetClassName()),
$indent  );''';
            case 'if':
              final condition = action.data['condition']?.toString() ?? 'true';
              final innerCode = generateActionBlocksOnly(
                project,
                action.innerActions,
                indent: '$indent  ',
                useNamedRoutes: useNamedRoutes,
                routeByPageId: routeByPageId,
                classByPageId: classByPageId,
              );
              return '''
$indent  if ($condition) {
${innerCode.isEmpty ? '$indent    // Bo\'sh' : innerCode}
$indent  }''';
            case 'if_else':
              final condition = action.data['condition']?.toString() ?? 'true';
              final innerCode = generateActionBlocksOnly(
                project,
                action.innerActions,
                indent: '$indent  ',
                useNamedRoutes: useNamedRoutes,
                routeByPageId: routeByPageId,
                classByPageId: classByPageId,
              );
              final elseCode = generateActionBlocksOnly(
                project,
                action.elseActions,
                indent: '$indent  ',
                useNamedRoutes: useNamedRoutes,
                routeByPageId: routeByPageId,
                classByPageId: classByPageId,
              );
              return '''
$indent  if ($condition) {
${innerCode.isEmpty ? '$indent    // Bo\'sh' : innerCode}
$indent  } else {
${elseCode.isEmpty ? '$indent    // Bo\'sh' : elseCode}
$indent  }''';
            case 'set_variable':
              return '$indent  final ${action.data['name'] ?? 'value'} = ${action.data['value'] ?? 'null'};';
            case 'equals':
              return '$indent  final _isEqual = (${action.data['a'] ?? '0'}) == (${action.data['b'] ?? '0'});';
            case 'set_enabled':
              return '$indent  // setEnabled(${action.data['widgetId'] ?? 'widget'}, ${action.data['enabled'] ?? 'true'})';
            case 'request_focus':
              return '$indent  final FocusNode _focusNode = FocusNode();\n$indent  FocusScope.of(context).requestFocus(_focusNode);';
            case 'get_width':
              return '$indent  final _width = MediaQuery.of(context).size.width; // ${action.data['widgetId'] ?? 'widget'}';
            case 'get_height':
              return '$indent  final _height = MediaQuery.of(context).size.height; // ${action.data['widgetId'] ?? 'widget'}';
            case 'back':
              return '$indent  Navigator.of(context).pop();';
            default:
              return '$indent  // Action: ${action.type}';
          }
        })
        .join('\n');
  }

  static List<_PageSpec> _buildPageSpecs(List<PageData> pages) {
    final specs = <_PageSpec>[];
    final usedFiles = <String>{};
    final usedClasses = <String>{};
    final usedRoutes = <String>{};

    for (var i = 0; i < pages.length; i++) {
      final page = pages[i];
      final fileBase = _toSnake(page.name).isEmpty
          ? 'page_$i'
          : _toSnake(page.name);
      final classBase = _toPascal(page.name).isEmpty
          ? 'Page$i'
          : _toPascal(page.name);
      final routeBase = '/$fileBase';

      var fileName = '${fileBase}_page.dart';
      var className = '${classBase}Page';
      var routeName = routeBase;

      var suffix = 2;
      while (usedFiles.contains(fileName)) {
        fileName = '${fileBase}_$suffix.dart';
        suffix++;
      }

      suffix = 2;
      while (usedClasses.contains(className)) {
        className = '${classBase}Page$suffix';
        suffix++;
      }

      suffix = 2;
      while (usedRoutes.contains(routeName)) {
        routeName = '$routeBase$suffix';
        suffix++;
      }

      usedFiles.add(fileName);
      usedClasses.add(className);
      usedRoutes.add(routeName);
      specs.add(
        _PageSpec(
          page: page,
          fileName: fileName,
          className: className,
          routeName: routeName,
        ),
      );
    }

    return specs;
  }

  static String _generateProjectMainFile(
    ProjectData project,
    List<_PageSpec> specs,
  ) {
    final appClass = '${_toPascal(project.appName)}App';
    final imports = specs
        .map((spec) => "import 'pages/${spec.fileName}';")
        .join('\n');
    final routes = specs
        .map(
          (spec) =>
              "        '${spec.routeName}': (context) => const ${spec.className}(),",
        )
        .join('\n');

    return '''
import 'package:flutter/material.dart';
$imports

void main() => runApp(const $appClass());

class $appClass extends StatelessWidget {
  const $appClass({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '${_escapeDartString(project.appName)}',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Color(${project.colorPrimary})),
        useMaterial3: true,
      ),
      initialRoute: '${specs.first.routeName}',
      routes: {
$routes
      },
    );
  }
}
''';
  }

  static String _generatePubspec(
    ProjectData project, {
    required bool hasToast,
  }) {
    final deps = <String>[
      'dependencies:',
      '  flutter:',
      '    sdk: flutter',
      '  cupertino_icons: ^1.0.8',
    ];
    if (hasToast) {
      deps.add('  fluttertoast: ^8.2.2');
    }

    return '''
name: ${_toSnake(project.appName)}
description: Generated by Flutware
publish_to: 'none'
version: ${project.versionName}+${project.versionCode}

environment:
  sdk: ">=3.0.0 <4.0.0"

${deps.join('\n')}

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0

flutter:
  uses-material-design: true
''';
  }

  static bool _projectUsesBlockType(List<PageData> pages, String type) {
    bool hasType(List<ActionBlock> actions) {
      for (final action in actions) {
        if (action.type == type) return true;
        if (hasType(action.innerActions)) return true;
        if (hasType(action.elseActions)) return true;
      }
      return false;
    }

    for (final page in pages) {
      if (hasType(page.onCreate)) return true;
      for (final logic in page.logic.values) {
        if (hasType(logic.onClicked)) return true;
        if (hasType(logic.onLongPressed)) return true;
      }
    }
    return false;
  }

  static String _toSnake(String value) {
    var cleaned = value
        .trim()
        .replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '')
        .toLowerCase();
    if (cleaned.isEmpty) return 'app';
    if (RegExp(r'^[0-9]').hasMatch(cleaned)) {
      cleaned = 'app_$cleaned';
    }
    return cleaned;
  }

  static String _toPascal(String value) {
    final words = value
        .trim()
        .split(RegExp(r'[^a-zA-Z0-9]+'))
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) return 'App';
    var result = words
        .map(
          (word) =>
              '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join();
    if (RegExp(r'^[0-9]').hasMatch(result)) {
      result = 'P$result';
    }
    return result;
  }

  static String _escapeDartString(String value) {
    return value
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\n', '\\n');
  }
}

class _PageSpec {
  final PageData page;
  final String fileName;
  final String className;
  final String routeName;

  const _PageSpec({
    required this.page,
    required this.fileName,
    required this.className,
    required this.routeName,
  });
}
