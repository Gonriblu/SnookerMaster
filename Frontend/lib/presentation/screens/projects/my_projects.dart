import 'package:flutter/material.dart';
import 'package:snooker_flutter/entities/project.dart';
import 'package:snooker_flutter/presentation/widgets/shared/custom_appbar.dart';
import 'package:snooker_flutter/presentation/widgets/shared/custom_project_grid.dart';
import 'package:snooker_flutter/services/http_services/projects_datasource.dart';

class MyProjectsScreen extends StatefulWidget {
  static const name = 'my-projects-screen';
  final String to;

  const MyProjectsScreen({super.key, required this.to});

  @override
  State<MyProjectsScreen> createState() => _MyProjectsScreenState();
}

class _MyProjectsScreenState extends State<MyProjectsScreen> {
  bool _isDataLoaded = false;
  List<Project>? myProjects;

  _loadData() async {
    myProjects = await ProjectService.getInstance().getMyProjects(null);
    setState(() {
      _isDataLoaded = true;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _onProjectCreated() {
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isDataLoaded) {
      return const Scaffold(
        appBar: CustomAppBar(title: 'Proyectos'),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: const CustomAppBar(title: 'Proyectos'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: CustomProjectGrid(
                  create: true,
                  to: widget.to,
                  projectList: myProjects ?? [],
                  onProjectCreated: _onProjectCreated,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadData();
  }

  @override
  void didUpdateWidget(covariant MyProjectsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.to != oldWidget.to) {
      _loadData();
    }
  }
}
