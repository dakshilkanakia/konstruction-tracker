import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:intl/intl.dart'; // Will be used for currency formatting
import '../models/project.dart';
import '../models/component.dart';
import '../models/material.dart' as models;
import '../models/machinery.dart';
import '../services/firestore_service.dart';
import '../widgets/budget_progress_card.dart';
import '../widgets/components_section.dart';
import '../widgets/materials_section.dart';
import '../widgets/machinery_section.dart';
import '../widgets/labor_section.dart';
import '../widgets/daily_logs_section.dart';
import 'add_component_screen.dart';
import 'add_labor_screen.dart';
import 'add_material_screen.dart';
import 'add_machinery_screen.dart';
import 'add_daily_log_screen.dart';

class ProjectDetailsScreen extends StatefulWidget {
  final Project project;

  const ProjectDetailsScreen({
    super.key,
    required this.project,
  });

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Component> _components = [];
  List<models.Material> _materials = [];
  List<Machinery> _machinery = [];
  bool _isLoading = true;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadProjectData();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) return;
    setState(() {
      _currentTabIndex = _tabController.index;
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProjectData() async {
    setState(() => _isLoading = true);

    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    
    print('ProjectDetails: Loading data for project ${widget.project.id}');
    
    final results = await Future.wait([
      firestoreService.getProjectComponents(widget.project.id),
      firestoreService.getProjectMaterials(widget.project.id),
      firestoreService.getProjectMachinery(widget.project.id),
    ]);

    print('ProjectDetails: Components loaded: ${(results[0] as List<Component>).length}');
    print('ProjectDetails: Materials loaded: ${(results[1] as List<models.Material>).length}');
    print('ProjectDetails: Machinery loaded: ${(results[2] as List<Machinery>).length}');

    setState(() {
      _components = results[0] as List<Component>;
      _materials = results[1] as List<models.Material>;
      _machinery = results[2] as List<Machinery>;
      _isLoading = false;
    });
    
    print('ProjectDetails: State updated - showing ${_components.length} components');
  }

  double get _totalUsedBudget {
    double total = 0.0;
    
    // Add component costs
    for (var component in _components) {
      total += component.totalCost;
    }
    
    // Add material costs
    for (var material in _materials) {
      total += material.totalCost;
    }
    
    // Add machinery costs
    for (var machine in _machinery) {
      total += machine.totalCost;
    }
    
    return total;
  }

  double get _overallProgress {
    if (_components.isEmpty) return 0.0;
    
    double totalProgress = 0.0;
    for (var component in _components) {
      totalProgress += component.overallProgressPercentage;
    }
    
    return totalProgress / _components.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.project.name),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.build), text: 'Components'),
            Tab(icon: Icon(Icons.inventory), text: 'Materials'),
            Tab(icon: Icon(Icons.construction), text: 'Machinery'),
            Tab(icon: Icon(Icons.work), text: 'Labor'),
            Tab(icon: Icon(Icons.assignment), text: 'Logs'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildComponentsTab(),
                _buildMaterialsTab(),
                _buildMachineryTab(),
                _buildLaborTab(),
                _buildDailyLogsTab(),
              ],
            ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: _loadProjectData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Project Info Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Project Information',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow('Location', widget.project.location),
                  _buildInfoRow('Contractor', widget.project.generalContractor),
                  _buildInfoRow('Start Date', 
                    '${widget.project.startDate.day}/${widget.project.startDate.month}/${widget.project.startDate.year}'),
                  _buildInfoRow('Days Running', '${widget.project.daysSinceStart}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Overall Progress Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Overall Progress',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: _overallProgress,
                    backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                    color: _getProgressColor(_overallProgress),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(_overallProgress * 100).toStringAsFixed(1)}% Complete',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Budget Progress Card
          BudgetProgressCard(
            totalBudget: widget.project.totalBudget,
            usedBudget: _totalUsedBudget,
          ),
          const SizedBox(height: 16),

          // Quick Stats
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Components',
                  '${_components.length}',
                  Icons.build,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Materials',
                  '${_materials.length}',
                  Icons.inventory,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Machinery',
                  '${_machinery.length}',
                  Icons.construction,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComponentsTab() {
    return ComponentsSection(
      components: _components,
      project: widget.project,
      onRefresh: _loadProjectData,
      onAddComponent: () => _navigateToAddComponent(),
    );
  }

  Widget _buildMaterialsTab() {
    return MaterialsSection(
      project: widget.project,
      onRefresh: _loadProjectData,
    );
  }

  Widget _buildMachineryTab() {
    return MachinerySection(projectId: widget.project.id);
  }

  Widget _buildLaborTab() {
    return LaborSection(
      project: widget.project,
      onRefresh: _loadProjectData,
    );
  }

  Widget _buildDailyLogsTab() {
    return DailyLogsSection(projectId: widget.project.id);
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _getProgressColor(double progress) {
    if (progress < 0.3) return Colors.red;
    if (progress < 0.7) return Colors.orange;
    return Colors.green;
  }

  Widget? _buildFAB() {
    // Use the stable _currentTabIndex instead of _tabController.index
    switch (_currentTabIndex) {
      case 1: // Components tab
        return FloatingActionButton(
          onPressed: _navigateToAddComponent,
          tooltip: 'Add Component',
          child: const Icon(Icons.add),
        );
      case 2: // Materials tab
        return FloatingActionButton(
          onPressed: _navigateToAddMaterial,
          tooltip: 'Add Material',
          child: const Icon(Icons.add),
        );
      case 3: // Machinery tab
        return FloatingActionButton(
          onPressed: _navigateToAddMachinery,
          tooltip: 'Add Machinery',
          child: const Icon(Icons.add),
        );
      case 4: // Labor tab
        return FloatingActionButton(
          onPressed: _navigateToAddLabor,
          tooltip: 'Add Labor Entry',
          child: const Icon(Icons.add),
        );
      case 5: // Daily Logs tab
        return FloatingActionButton(
          onPressed: _navigateToAddDailyLog,
          tooltip: 'Add Daily Log',
          child: const Icon(Icons.add),
        );
      default:
        return null;
    }
  }

  void _navigateToAddComponent() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddComponentScreen(project: widget.project),
      ),
    ).then((_) => _loadProjectData());
  }

  void _navigateToAddMaterial() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddMaterialScreen(projectId: widget.project.id),
      ),
    ).then((_) => _loadProjectData());
  }

  void _navigateToAddMachinery() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddMachineryScreen(projectId: widget.project.id),
      ),
    ).then((_) => _loadProjectData());
  }

  void _navigateToAddLabor() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddLaborScreen(project: widget.project),
      ),
    ).then((_) => _loadProjectData());
  }

  void _navigateToAddDailyLog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddDailyLogScreen(projectId: widget.project.id),
      ),
    ).then((_) => _loadProjectData());
  }
}
