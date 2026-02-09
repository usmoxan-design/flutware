import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/app_models.dart';
import '../../models/block_definitions.dart';
import '../../providers/project_provider.dart';
import '../../widgets/visual_block.dart';

class LogicTab extends ConsumerStatefulWidget {
  const LogicTab({super.key});

  @override
  ConsumerState<LogicTab> createState() => _LogicTabState();
}

class _LogicTabState extends ConsumerState<LogicTab> {
  BlockCategory _selectedCategory = BlockCategory.view;
  final Set<String> _seededPages = <String>{};

  @override
  Widget build(BuildContext context) {
    final project = ref.watch(currentProjectProvider);
    final page = ref.watch(currentPageProvider);
    final projectIndex = ref.watch(currentProjectIndexProvider);
    final pageIndex = ref.watch(currentPageIndexProvider);

    if (project == null ||
        page == null ||
        projectIndex == null ||
        pageIndex == null) {
      return const SizedBox();
    }

    _seedInitBlocksIfNeeded(project, projectIndex, page, pageIndex);

    final actions = page.onCreate;
    final blocks = BlockRegistry.blocks
        .where((item) => item.category == _selectedCategory)
        .toList();

    return Stack(
      children: [
        Container(
          color: const Color(0xFFF1F4F9),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 220),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'onCreate (initState)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  children: [
                    VisualBlockWidget(
                      action: ActionBlock(
                        type: 'event',
                        data: const {'label': 'onCreate'},
                      ),
                      isHat: true,
                    ),
                    const SizedBox(height: 4),
                    for (var i = 0; i < actions.length; i++)
                      _buildActionItem(
                        project,
                        projectIndex,
                        page,
                        pageIndex,
                        actions[i],
                        i,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: 215,
            decoration: BoxDecoration(
              color: const Color(0xFFDCE4EE),
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                    children: [
                      for (final block in blocks)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: InkWell(
                            onTap: () => _appendBlock(
                              project,
                              projectIndex,
                              page,
                              pageIndex,
                              block,
                            ),
                            child: VisualBlockWidget(
                              action: _createPreviewAction(block),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Container(width: 1, color: Colors.grey.shade300),
                SizedBox(
                  width: 126,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(10, 10, 10, 6),
                        child: Text(
                          'Search...',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                          children: [
                            for (final category in BlockCategory.values)
                              _buildCategoryItem(category),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionItem(
    ProjectData project,
    int projectIndex,
    PageData page,
    int pageIndex,
    ActionBlock action,
    int index,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: VisualBlockWidget(
        action: action,
        onDelete: () {
          final list = [...page.onCreate]..removeAt(index);
          _saveOnCreate(project, projectIndex, page, pageIndex, list);
        },
      ),
    );
  }

  Widget _buildCategoryItem(BlockCategory category) {
    final selected = _selectedCategory == category;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => setState(() => _selectedCategory = category),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? category.color.withValues(alpha: 0.18)
              : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? category.color : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                color: category.color,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                category.name[0].toUpperCase() + category.name.substring(1),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _seedInitBlocksIfNeeded(
    ProjectData project,
    int projectIndex,
    PageData page,
    int pageIndex,
  ) {
    if (page.onCreate.isNotEmpty) return;
    if (_seededPages.contains(page.id)) return;
    _seededPages.add(page.id);

    final seeded = <ActionBlock>[
      ActionBlock(type: 'if', data: const {'condition': 'true'}),
      ActionBlock(
        type: 'set_enabled',
        data: const {'widgetId': 'button1', 'enabled': 'true'},
      ),
      ActionBlock(type: 'request_focus', data: const {'widgetId': 'text1'}),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _saveOnCreate(project, projectIndex, page, pageIndex, seeded);
    });
  }

  void _appendBlock(
    ProjectData project,
    int projectIndex,
    PageData page,
    int pageIndex,
    BlockDefinition block,
  ) {
    final next = [...page.onCreate, _createPreviewAction(block)];
    _saveOnCreate(project, projectIndex, page, pageIndex, next);
    HapticFeedback.selectionClick();
  }

  ActionBlock _createPreviewAction(BlockDefinition def) {
    final data = <String, dynamic>{};
    for (final parameter in def.parameters) {
      if (parameter.defaultValue != null) {
        data[parameter.key] = parameter.defaultValue;
      }
    }
    return ActionBlock(type: def.type, data: data);
  }

  void _saveOnCreate(
    ProjectData project,
    int projectIndex,
    PageData page,
    int pageIndex,
    List<ActionBlock> blocks,
  ) {
    final pages = [...project.pages];
    pages[pageIndex] = page.copyWith(onCreate: blocks);
    ref
        .read(projectProvider.notifier)
        .updateProject(projectIndex, project.copyWith(pages: pages));
  }
}
