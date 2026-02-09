import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/app_models.dart';
import '../../providers/project_provider.dart';
import '../logic_editor_screen.dart';

class UiTab extends ConsumerStatefulWidget {
  const UiTab({super.key});

  @override
  ConsumerState<UiTab> createState() => _UiTabState();
}

class _UiTabState extends ConsumerState<UiTab> {
  static const _templates = <_WidgetTemplate>[
    _WidgetTemplate(type: 'row', title: 'Row', icon: Icons.view_column),
    _WidgetTemplate(type: 'column', title: 'Column', icon: Icons.view_stream),
    _WidgetTemplate(type: 'text', title: 'Text', icon: Icons.text_fields),
    _WidgetTemplate(type: 'button', title: 'Button', icon: Icons.smart_button),
  ];

  String? _selectedWidgetId;
  _PropertySheetTab _sheetTab = _PropertySheetTab.basic;

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

    final selected = _findWidgetById(page.widgets, _selectedWidgetId);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 900;
        final paletteWidth = isCompact ? 150.0 : 210.0;

        return Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(width: paletteWidth, child: _buildPalette(page)),
                VerticalDivider(width: 1, color: Colors.grey.shade300),
                Expanded(
                  child: _buildCanvas(
                    project,
                    projectIndex,
                    pageIndex,
                    page,
                    selected,
                  ),
                ),
              ],
            ),
            _buildPropertySheet(
              project,
              projectIndex,
              pageIndex,
              page,
              selected,
            ),
          ],
        );
      },
    );
  }

  Widget _buildPalette(PageData page) {
    return Container(
      color: Colors.grey.shade100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Text(
              'Widgets',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade800,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 190),
              itemCount: _templates.length,
              itemBuilder: (context, index) {
                final template = _templates[index];
                final tile = _buildTemplateTile(template, page);
                return LongPressDraggable<_WidgetTemplate>(
                  data: template,
                  feedback: Material(
                    color: Colors.transparent,
                    child: SizedBox(width: 160, child: tile),
                  ),
                  childWhenDragging: Opacity(opacity: 0.35, child: tile),
                  child: tile,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateTile(_WidgetTemplate template, PageData page) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => _addWidgetFromTemplate(template, page),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(template.icon, size: 17, color: Colors.blueGrey.shade700),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                template.title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCanvas(
    ProjectData project,
    int projectIndex,
    int pageIndex,
    PageData page,
    WidgetData? selected,
  ) {
    return DragTarget<_WidgetTemplate>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (details) =>
          _addWidgetFromTemplate(details.data, page),
      builder: (context, candidateData, rejectedData) {
        final isActive = candidateData.isNotEmpty;

        return Container(
          color: isActive ? Colors.blue.withValues(alpha: 0.03) : Colors.white,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 170),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text(
                      'main.xml',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const Spacer(),
                    if (selected != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.lightBlue.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.lightBlue.shade100),
                        ),
                        child: Text(
                          'Selected: ${selected.id}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 9 / 16,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade400),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Column(
                            children: [
                              Container(
                                height: 42,
                                width: double.infinity,
                                color: Colors.green.shade700,
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: const Text(
                                  'Toolbar',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.all(12),
                                  child: page.widgets.isEmpty
                                      ? _buildDefaultPreview()
                                      : Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            for (final widget in page.widgets)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  bottom: 8,
                                                ),
                                                child: _buildCanvasNode(
                                                  widget,
                                                  page,
                                                ),
                                              ),
                                          ],
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap widget to edit properties. Select Row/Column then add to nest.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDefaultPreview() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('TextView', style: TextStyle(fontSize: 13)),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: () {}, child: const Text('Button')),
        ],
      ),
    );
  }

  Widget _buildCanvasNode(WidgetData widget, PageData page) {
    final isSelected = widget.id == _selectedWidgetId;
    final children = _childrenOf(widget);
    final isContainer = widget.type == 'row' || widget.type == 'column';

    Widget body;
    switch (widget.type) {
      case 'text':
        body = Text(
          widget.text.isEmpty ? 'TextView' : widget.text,
          style: TextStyle(fontSize: widget.fontSize),
        );
        break;
      case 'button':
        final enabled = widget.properties['enabled'] != false;
        body = ElevatedButton(
          onPressed: enabled ? () {} : null,
          child: Text(widget.text.isEmpty ? 'Button' : widget.text),
        );
        break;
      case 'row':
        body = DragTarget<_WidgetTemplate>(
          onWillAcceptWithDetails: (_) => true,
          onAcceptWithDetails: (details) =>
              _addWidgetFromTemplate(details.data, page, parentId: widget.id),
          builder: (context, candidateData, rejectedData) {
            return Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade50,
                border: Border.all(
                  color: candidateData.isNotEmpty
                      ? Colors.indigo
                      : Colors.grey.shade300,
                ),
              ),
              child: children.isEmpty
                  ? const Text(
                      'Row (empty)',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final child in children)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: _buildCanvasNode(child, page),
                            ),
                          ),
                      ],
                    ),
            );
          },
        );
        break;
      case 'column':
        body = DragTarget<_WidgetTemplate>(
          onWillAcceptWithDetails: (_) => true,
          onAcceptWithDetails: (details) =>
              _addWidgetFromTemplate(details.data, page, parentId: widget.id),
          builder: (context, candidateData, rejectedData) {
            return Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade50,
                border: Border.all(
                  color: candidateData.isNotEmpty
                      ? Colors.indigo
                      : Colors.grey.shade300,
                ),
              ),
              child: children.isEmpty
                  ? const Text(
                      'Column (empty)',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final child in children)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: _buildCanvasNode(child, page),
                          ),
                      ],
                    ),
            );
          },
        );
        break;
      default:
        body = Text('Unknown: ${widget.type}');
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedWidgetId = widget.id;
          _sheetTab = _PropertySheetTab.basic;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.lightBlue : Colors.transparent,
            width: 2,
          ),
          color: isSelected
              ? Colors.lightBlue.withValues(alpha: 0.08)
              : Colors.transparent,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: body),
            if (isContainer)
              Padding(
                padding: const EdgeInsets.only(left: 6, top: 4),
                child: Icon(
                  Icons.account_tree_outlined,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertySheet(
    ProjectData project,
    int projectIndex,
    int pageIndex,
    PageData page,
    WidgetData? selected,
  ) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: DraggableScrollableSheet(
        initialChildSize: 0.25,
        minChildSize: 0.16,
        maxChildSize: 0.58,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFFE8EFF7),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade500,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.widgets,
                      color: Colors.blueGrey.shade700,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        selected?.id ?? 'No widget selected',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (selected != null)
                      IconButton(
                        tooltip: 'Delete',
                        onPressed: () {
                          _removeWidgetById(
                            project,
                            projectIndex,
                            pageIndex,
                            page,
                            selected.id,
                          );
                          setState(() => _selectedWidgetId = null);
                        },
                        icon: const Icon(Icons.delete_outline),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Basic'),
                      selected: _sheetTab == _PropertySheetTab.basic,
                      onSelected: (_) {
                        setState(() => _sheetTab = _PropertySheetTab.basic);
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Event'),
                      selected: _sheetTab == _PropertySheetTab.event,
                      onSelected: (_) {
                        setState(() => _sheetTab = _PropertySheetTab.event);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (selected == null)
                  Text(
                    'Canvasdagi widgetni tanlang.',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                  )
                else if (_sheetTab == _PropertySheetTab.basic)
                  _buildBasicProperties(
                    project,
                    projectIndex,
                    pageIndex,
                    page,
                    selected,
                  )
                else
                  _buildEventProperties(
                    project,
                    projectIndex,
                    pageIndex,
                    page,
                    selected,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBasicProperties(
    ProjectData project,
    int projectIndex,
    int pageIndex,
    PageData page,
    WidgetData selected,
  ) {
    final children = _childrenOf(selected);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (selected.type == 'text' || selected.type == 'button') ...[
          TextFormField(
            initialValue: selected.text,
            decoration: const InputDecoration(
              labelText: 'text',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onFieldSubmitted: (value) {
              final key = selected.type == 'text' ? 'text' : 'label';
              _updateWidgetProperty(
                project,
                projectIndex,
                pageIndex,
                page,
                selected.id,
                key,
                value,
              );
            },
          ),
          const SizedBox(height: 10),
        ],
        if (selected.type == 'button')
          SwitchListTile(
            value: selected.properties['enabled'] != false,
            title: const Text('enabled'),
            contentPadding: EdgeInsets.zero,
            onChanged: (value) {
              _updateWidgetProperty(
                project,
                projectIndex,
                pageIndex,
                page,
                selected.id,
                'enabled',
                value,
              );
            },
          ),
        if (selected.type == 'row' || selected.type == 'column')
          Text(
            'children: ${children.length}',
            style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
          ),
      ],
    );
  }

  Widget _buildEventProperties(
    ProjectData project,
    int projectIndex,
    int pageIndex,
    PageData page,
    WidgetData selected,
  ) {
    if (selected.type != 'button') {
      return Text(
        'Bu widget uchun Event mavjud emas.',
        style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
      );
    }

    final logic = page.logic[selected.id] ?? WidgetLogic();
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        title: const Text('onPressed'),
        subtitle: Text('${logic.onClicked.length} ta blok'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _openWidgetLogicEditor(
          project,
          projectIndex,
          pageIndex,
          page,
          selected.id,
        ),
      ),
    );
  }

  Future<void> _addWidgetFromTemplate(
    _WidgetTemplate template,
    PageData page, {
    String? parentId,
  }) async {
    final project = ref.read(currentProjectProvider);
    final projectIndex = ref.read(currentProjectIndexProvider);
    final pageIndex = ref.read(currentPageIndexProvider);
    if (project == null || projectIndex == null || pageIndex == null) return;

    final newWidget = _createWidgetFromTemplate(template, page);
    final targetParentId = parentId ?? _selectedContainerId(page.widgets);

    final widgets = targetParentId == null
        ? [...page.widgets, newWidget]
        : _insertChild(page.widgets, targetParentId, newWidget);

    _updatePage(
      ref,
      project,
      projectIndex,
      pageIndex,
      page.copyWith(widgets: widgets),
    );

    setState(() {
      _selectedWidgetId = newWidget.id;
      _sheetTab = _PropertySheetTab.basic;
    });
    HapticFeedback.selectionClick();
  }

  WidgetData _createWidgetFromTemplate(
    _WidgetTemplate template,
    PageData page,
  ) {
    final id = _nextId(page, template.type);
    switch (template.type) {
      case 'text':
        return WidgetData(
          id: id,
          type: 'text',
          properties: {'text': 'TextView', 'fontSize': 14.0},
        );
      case 'button':
        return WidgetData(
          id: id,
          type: 'button',
          properties: {'label': 'Button', 'enabled': true},
        );
      case 'row':
        return WidgetData(
          id: id,
          type: 'row',
          properties: {'label': 'Row', 'children': <Map<String, dynamic>>[]},
        );
      case 'column':
      default:
        return WidgetData(
          id: id,
          type: 'column',
          properties: {'label': 'Column', 'children': <Map<String, dynamic>>[]},
        );
    }
  }

  void _openWidgetLogicEditor(
    ProjectData project,
    int pIdx,
    int pgIdx,
    PageData page,
    String widgetId,
  ) {
    final logic = page.logic[widgetId] ?? WidgetLogic();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LogicEditorScreen(
          title: '$widgetId - onPressed',
          project: project,
          initialActions: logic.onClicked,
          onSave: (newActions) {
            _updateWidgetLogic(
              project,
              pIdx,
              pgIdx,
              page,
              widgetId,
              onClicked: newActions,
            );
          },
        ),
      ),
    );
  }

  void _updateWidgetLogic(
    ProjectData project,
    int pIdx,
    int pgIdx,
    PageData page,
    String widgetId, {
    List<ActionBlock>? onClicked,
  }) {
    final currentLogic = page.logic[widgetId] ?? WidgetLogic();
    final newLogic = WidgetLogic(
      onClicked: onClicked ?? currentLogic.onClicked,
      onLongPressed: currentLogic.onLongPressed,
    );
    final newLogicMap = {...page.logic, widgetId: newLogic};
    _updatePage(ref, project, pIdx, pgIdx, page.copyWith(logic: newLogicMap));
  }

  void _updateWidgetProperty(
    ProjectData project,
    int pIdx,
    int pgIdx,
    PageData page,
    String widgetId,
    String key,
    dynamic value,
  ) {
    final widgets = _updateWidgetById(page.widgets, widgetId, (old) {
      return WidgetData(
        id: old.id,
        type: old.type,
        properties: {...old.properties, key: value},
      );
    });
    _updatePage(ref, project, pIdx, pgIdx, page.copyWith(widgets: widgets));
  }

  void _removeWidgetById(
    ProjectData project,
    int pIdx,
    int pgIdx,
    PageData page,
    String widgetId,
  ) {
    final widgets = _removeById(page.widgets, widgetId);
    final logic = {...page.logic}..remove(widgetId);
    _updatePage(
      ref,
      project,
      pIdx,
      pgIdx,
      page.copyWith(widgets: widgets, logic: logic),
    );
    HapticFeedback.vibrate();
  }

  String? _selectedContainerId(List<WidgetData> widgets) {
    final selected = _findWidgetById(widgets, _selectedWidgetId);
    if (selected == null) return null;
    if (selected.type == 'row' || selected.type == 'column') return selected.id;
    return null;
  }

  WidgetData? _findWidgetById(List<WidgetData> widgets, String? id) {
    if (id == null) return null;
    for (final widget in widgets) {
      if (widget.id == id) return widget;
      final nested = _findWidgetById(_childrenOf(widget), id);
      if (nested != null) return nested;
    }
    return null;
  }

  List<WidgetData> _insertChild(
    List<WidgetData> widgets,
    String parentId,
    WidgetData child,
  ) {
    return widgets.map((item) {
      if (item.id == parentId) {
        final children = _childrenOf(item);
        return _withChildren(item, [...children, child]);
      }
      final children = _childrenOf(item);
      if (children.isEmpty) return item;
      return _withChildren(item, _insertChild(children, parentId, child));
    }).toList();
  }

  List<WidgetData> _removeById(List<WidgetData> widgets, String id) {
    return widgets.where((item) => item.id != id).map((item) {
      final children = _childrenOf(item);
      if (children.isEmpty) return item;
      return _withChildren(item, _removeById(children, id));
    }).toList();
  }

  List<WidgetData> _updateWidgetById(
    List<WidgetData> widgets,
    String id,
    WidgetData Function(WidgetData) mapper,
  ) {
    return widgets.map((item) {
      if (item.id == id) return mapper(item);
      final children = _childrenOf(item);
      if (children.isEmpty) return item;
      return _withChildren(item, _updateWidgetById(children, id, mapper));
    }).toList();
  }

  List<WidgetData> _childrenOf(WidgetData widget) {
    final raw = widget.properties['children'];
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((json) {
      return WidgetData.fromJson(Map<String, dynamic>.from(json));
    }).toList();
  }

  WidgetData _withChildren(WidgetData widget, List<WidgetData> children) {
    return WidgetData(
      id: widget.id,
      type: widget.type,
      properties: {
        ...widget.properties,
        'children': children.map((child) => child.toJson()).toList(),
      },
    );
  }

  String _nextId(PageData page, String type) {
    final prefix = switch (type) {
      'text' => 'text',
      'button' => 'button',
      'row' => 'row',
      'column' => 'column',
      _ => 'widget',
    };
    final all = _flattenWidgets(page.widgets).map((item) => item.id).toSet();
    var i = 1;
    while (all.contains('${prefix}_$i')) {
      i++;
    }
    return '${prefix}_$i';
  }

  List<WidgetData> _flattenWidgets(List<WidgetData> widgets) {
    final result = <WidgetData>[];
    for (final widget in widgets) {
      result.add(widget);
      final children = _childrenOf(widget);
      if (children.isNotEmpty) {
        result.addAll(_flattenWidgets(children));
      }
    }
    return result;
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

enum _PropertySheetTab { basic, event }

class _WidgetTemplate {
  final String type;
  final String title;
  final IconData icon;

  const _WidgetTemplate({
    required this.type,
    required this.title,
    required this.icon,
  });
}
