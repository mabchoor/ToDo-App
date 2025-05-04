import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'add_task_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  List<Map<String, dynamic>> tasks = [];
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? tasksString = prefs.getString('tasks');
    if (tasksString != null) {
      setState(() {
        tasks = List<Map<String, dynamic>>.from(json.decode(tasksString));
      });
    }
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tasks', json.encode(tasks));
  }

  void _addTask(String newTitle) {
    setState(() {
      tasks.add({'title': newTitle, 'done': false});
    });
    _saveTasks();
    _controller.forward(from: 0);
  }

  void _toggleTask(int index, bool? value) {
    setState(() {
      tasks[index]['done'] = value!;
    });
    _saveTasks();
  }

  void _deleteTask(int index) {
    final deletedTask = tasks[index];
    setState(() {
      tasks.removeAt(index);
    });
    _saveTasks();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("🗑️ Tâche supprimée"),
        action: SnackBarAction(
          label: "Annuler",
          onPressed: () {
            setState(() {
              tasks.insert(index, deletedTask);
            });
            _saveTasks();
          },
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("📋 Mes Tâches"),
        centerTitle: true,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body:
          tasks.isEmpty
              ? const Center(child: Text("Aucune tâche ajoutée."))
              : ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  return Dismissible(
                    key: Key(tasks[index]['title'] + index.toString()),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) => _deleteTask(index),
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      color: Colors.redAccent,
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    child: Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      child: CheckboxListTile(
                        title: Text(
                          tasks[index]['title'],
                          style: TextStyle(
                            decoration:
                                tasks[index]['done']
                                    ? TextDecoration.lineThrough
                                    : null,
                          ),
                        ),
                        value: tasks[index]['done'],
                        onChanged: (val) => _toggleTask(index, val),
                        secondary: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _deleteTask(index),
                        ),
                      ),
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => AddTaskPage(onTaskAdded: _addTask),
              transitionsBuilder:
                  (_, anim, __, child) => SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 1),
                      end: Offset.zero,
                    ).animate(anim),
                    child: FadeTransition(opacity: anim, child: child),
                  ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
