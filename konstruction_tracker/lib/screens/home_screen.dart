import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/project.dart';
import '../widgets/project_card.dart';
import 'create_project_screen.dart';
import 'project_details_screen.dart';
import '../services/firebase_test.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Project> _projects = [];
  List<Project> _archivedProjects = [];
  bool _isLoading = true;
  bool _showArchived = false;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() => _isLoading = true);

    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    
    print('HomeScreen: Loading projects...');
    final activeProjects = await firestoreService.getProjects(includeArchived: false);
    final archivedProjects = await firestoreService.getProjects(includeArchived: true);
    
    print('HomeScreen: Active projects loaded: ${activeProjects.length}');
    print('HomeScreen: Archived projects loaded: ${archivedProjects.length}');
    
    setState(() {
      _projects = activeProjects;
      _archivedProjects = archivedProjects.where((p) => p.isArchived).toList();
      _isLoading = false;
    });
    
    print('HomeScreen: State updated - showing ${_projects.length} active projects');
  }

  void _showCreateProject() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateProjectScreen()),
    ).then((_) => _loadProjects());
  }

  void _showEditProject(Project project) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreateProjectScreen(project: project)),
    ).then((result) {
      if (result == true) {
        _loadProjects();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Konstruction Tracker'),
        actions: [
          IconButton(
            icon: Icon(_showArchived ? Icons.unarchive : Icons.archive),
            onPressed: () {
              setState(() => _showArchived = !_showArchived);
            },
            tooltip: _showArchived ? 'Show Active Projects' : 'Show Archived Projects',
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const ListTile(
                  leading: Icon(Icons.bug_report),
                  title: Text('Test Firebase'),
                ),
                onTap: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Testing Firebase connection...')),
                  );
                  
                  final success = await FirebaseTest.testFirestoreConnection();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success 
                            ? 'Firebase connection successful!' 
                            : 'Firebase connection failed - check console'),
                        backgroundColor: success ? Colors.green : Colors.red,
                      ),
                    );
                  }
                },
              ),
              PopupMenuItem(
                child: const ListTile(
                  leading: Icon(Icons.delete),
                  title: Text('Delete Seat Wall Labor'),
                ),
                onTap: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Deleting Seat Wall labor entry...')),
                  );
                  
                  final firestoreService = Provider.of<FirestoreService>(context, listen: false);
                  final success = await firestoreService.deleteSeatWallLaborEntry('4b3206d6-64f8-4d9c-a78e-f1654e452317');
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success 
                            ? 'Seat Wall labor entry deleted successfully!' 
                            : 'Failed to delete Seat Wall labor entry'),
                        backgroundColor: success ? Colors.green : Colors.red,
                      ),
                    );
                  }
                },
              ),
              PopupMenuItem(
                child: const ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Sign Out'),
                ),
                onTap: () {
                  Provider.of<AuthService>(context, listen: false).signOut();
                },
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadProjects,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildProjectsList(),
      ),
      floatingActionButton: _showArchived
          ? null
          : FloatingActionButton(
              onPressed: _showCreateProject,
              tooltip: 'Create New Project',
              child: const Icon(Icons.add),
            ),
    );
  }

  Widget _buildProjectsList() {
    final projectsToShow = _showArchived ? _archivedProjects : _projects;
    
    if (projectsToShow.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo at center when no projects
            Image.asset(
              'logo2.png',
              height: 120,
              width: 120,
            ),
            const SizedBox(height: 24),
            Text(
              'Konstruction Tracker',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _showArchived ? 'No archived projects' : 'No active projects',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            if (!_showArchived)
              Text(
                'Tap the + button to create your first project',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Projects List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: projectsToShow.length,
            itemBuilder: (context, index) {
              return ProjectCard(
                project: projectsToShow[index],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProjectDetailsScreen(
                        project: projectsToShow[index],
                      ),
                    ),
                  );
                },
                onEdit: () => _showEditProject(projectsToShow[index]),
                onArchiveToggle: () async {
                  // TODO: Implement archive toggle
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Archive functionality coming soon')),
                  );
                },
              );
            },
          ),
        ),
        
        // Logo at bottom when projects exist
        Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
            Image.asset(
              'logo2.png',
              height: 300,
              width: 300,
            ),
            ],
          ),
        ),
      ],
    );
  }
}
