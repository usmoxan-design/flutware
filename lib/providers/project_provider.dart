import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/app_models.dart';

final projectProvider =
    StateNotifierProvider<ProjectNotifier, List<ProjectData>>((ref) {
      return ProjectNotifier();
    });

class ProjectNotifier extends StateNotifier<List<ProjectData>> {
  ProjectNotifier() : super([]) {
    _loadProjects();
  }

  late Box _box;

  Future<void> _loadProjects() async {
    _box = await Hive.openBox('projects_box');
    final List<dynamic> rawProjects = _box.get('projects', defaultValue: []);
    state = rawProjects.map((e) => ProjectData.decode(e as String)).toList();
  }

  Future<void> addProject(String name) async {
    final newProject = ProjectData(
      appName: name,
      pages: [
        PageData(
          id: 'page_1',
          name: 'Home',
          type: 'StatelessWidget',
          widgets: [],
          logic: {},
        ),
      ],
    );
    state = [...state, newProject];
    _save();
  }

  Future<void> updateProject(int index, ProjectData project) async {
    final newState = [...state];
    newState[index] = project;
    state = newState;
    _save();
  }

  Future<void> deleteProject(int index) async {
    final newState = [...state];
    newState.removeAt(index);
    state = newState;
    _save();
  }

  void _save() {
    final rawList = state.map((p) => p.encode()).toList();
    _box.put('projects', rawList);
  }
}

final currentProjectIndexProvider = StateProvider<int?>((ref) => null);
final currentPageIndexProvider = StateProvider<int?>((ref) => null);

final currentProjectProvider = Provider<ProjectData?>((ref) {
  final index = ref.watch(currentProjectIndexProvider);
  final projects = ref.watch(projectProvider);
  if (index == null || index >= projects.length) return null;
  return projects[index];
});

final currentPageProvider = Provider<PageData?>((ref) {
  final project = ref.watch(currentProjectProvider);
  final pageIndex = ref.watch(currentPageIndexProvider);
  if (project == null || pageIndex == null || pageIndex >= project.pages.length)
    return null;
  return project.pages[pageIndex];
});
