import 'dart:convert';

class ActionBlock {
  final String type;
  final Map<String, dynamic> data;
  ActionBlock({required this.type, required this.data});
  Map<String, dynamic> toJson() => {'type': type, ...data};
  factory ActionBlock.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    final data = Map<String, dynamic>.from(json)..remove('type');
    return ActionBlock(type: type, data: data);
  }
}

class WidgetLogic {
  final List<ActionBlock> onClicked;
  final List<ActionBlock> onLongPressed;
  WidgetLogic({this.onClicked = const [], this.onLongPressed = const []});
  Map<String, dynamic> toJson() => {
    'onClicked': onClicked.map((e) => e.toJson()).toList(),
    'onLongPressed': onLongPressed.map((e) => e.toJson()).toList(),
  };
  factory WidgetLogic.fromJson(Map<String, dynamic>? json) {
    if (json == null) return WidgetLogic();
    return WidgetLogic(
      onClicked: (json['onClicked'] as List? ?? [])
          .map((e) => ActionBlock.fromJson(e as Map<String, dynamic>))
          .toList(),
      onLongPressed: (json['onLongPressed'] as List? ?? [])
          .map((e) => ActionBlock.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class WidgetData {
  final String id;
  final String type;
  final Map<String, dynamic> properties;
  WidgetData({required this.id, required this.type, required this.properties});
  Map<String, dynamic> toJson() => {'id': id, 'type': type, ...properties};
  factory WidgetData.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    final type = json['type'] as String;
    final properties = Map<String, dynamic>.from(json)
      ..remove('id')
      ..remove('type');
    return WidgetData(id: id, type: type, properties: properties);
  }
  String get text => properties['text'] ?? properties['label'] ?? '';
  double get fontSize => (properties['fontSize'] as num?)?.toDouble() ?? 16.0;
}

class PageData {
  final String id;
  final String name;
  final List<WidgetData> widgets;
  final Map<String, WidgetLogic> logic;
  final List<ActionBlock> onCreate;
  PageData({
    required this.id,
    required this.name,
    this.widgets = const [],
    this.logic = const {},
    this.onCreate = const [],
  });
  factory PageData.fromJson(Map<String, dynamic> json) {
    final logicJson = json['logic'] as Map<String, dynamic>? ?? {};
    final onCreateJson = logicJson['onCreate'] as List? ?? [];
    final logicMap = <String, WidgetLogic>{};
    logicJson.forEach((key, value) {
      if (key != 'onCreate' && value is Map<String, dynamic>) {
        logicMap[key] = WidgetLogic.fromJson(value);
      }
    });
    return PageData(
      id: json['id'] as String,
      name: json['name'] as String,
      widgets: (json['widgets'] as List? ?? [])
          .map((e) => WidgetData.fromJson(e as Map<String, dynamic>))
          .toList(),
      logic: logicMap,
      onCreate: onCreateJson
          .map((e) => ActionBlock.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ProjectData {
  final String appName;
  final List<PageData> pages;
  ProjectData({required this.appName, this.pages = const []});
  factory ProjectData.fromJson(Map<String, dynamic> json) {
    return ProjectData(
      appName: json['appName'] as String,
      pages: (json['pages'] as List? ?? [])
          .map((e) => PageData.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
  static ProjectData decode(String source) =>
      ProjectData.fromJson(jsonDecode(source) as Map<String, dynamic>);
}
