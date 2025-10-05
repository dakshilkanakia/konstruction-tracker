import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
// import 'package:intl/intl.dart'; // Will be used for currency formatting
import '../models/project.dart';
import '../models/component.dart';
import '../models/labor.dart';
import '../models/material.dart' as models;
import '../models/machinery.dart';
import '../services/firestore_service.dart';
import '../widgets/budget_progress_card.dart';
import '../widgets/components_section.dart';
import '../widgets/materials_section.dart';
import '../widgets/machinery_section.dart';
import '../widgets/labor_section.dart';
import '../widgets/daily_logs_section.dart';
import '../widgets/quick_notes_section.dart';
import 'add_component_screen.dart';
import 'add_contract_screen.dart';
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
  List<Labor> _labor = [];
  bool _isLoading = true;
  int _currentTabIndex = 0;
  int _laborRefreshKey = 0; // For forcing labor section refresh

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

  Project? _currentProject;

  Future<void> _loadProjectData() async {
    setState(() => _isLoading = true);

    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    
    print('ProjectDetails: Loading data for project ${widget.project.id}');
    
    final results = await Future.wait([
      firestoreService.getProject(widget.project.id), // Reload project data
      firestoreService.getProjectComponents(widget.project.id),
      firestoreService.getProjectMaterials(widget.project.id),
      firestoreService.getProjectMachinery(widget.project.id),
      firestoreService.getProjectLabor(widget.project.id),
    ]);

    print('ProjectDetails: Project loaded: ${results[0] != null}');
    print('ProjectDetails: Components loaded: ${(results[1] as List<Component>).length}');
    print('ProjectDetails: Materials loaded: ${(results[2] as List<models.Material>).length}');
    print('ProjectDetails: Machinery loaded: ${(results[3] as List<Machinery>).length}');
    print('ProjectDetails: Labor loaded: ${(results[4] as List<Labor>).length}');

    setState(() {
      _currentProject = results[0] as Project?;
      _components = results[1] as List<Component>;
      _materials = results[2] as List<models.Material>;
      _machinery = results[3] as List<Machinery>;
      _labor = results[4] as List<Labor>;
      _isLoading = false;
    });
    
    print('ProjectDetails: State updated - showing ${_components.length} components');
  }

  double get _totalUsedBudget {
    double total = 0.0;
    double componentTotal = 0.0;
    double materialTotal = 0.0;
    double machineryTotal = 0.0;
    double laborTotal = 0.0;
    
    // Add component costs
    for (var component in _components) {
      componentTotal += component.totalCost;
      if (kDebugMode) print('  Component: ${component.name} - Cost: \$${component.totalCost.toStringAsFixed(2)}');
    }
    
    // Add material costs
    for (var material in _materials) {
      materialTotal += material.totalCost;
      if (kDebugMode) print('  Material: ${material.name} - Cost: \$${material.totalCost.toStringAsFixed(2)}');
    }
    
    // Add machinery costs
    for (var machine in _machinery) {
      machineryTotal += machine.totalCost;
      if (kDebugMode) print('  Machine: ${machine.name} - Cost: \$${machine.totalCost.toStringAsFixed(2)}');
    }
    
    // Add labor costs (only for custom components, not existing ones)
    // Note: Labor costs for existing components are already included in component.amountUsed
    // through the sync process, so we only count custom labor to avoid double counting
    for (var labor in _labor) {
      // Check if this labor workCategory matches any existing component (case-insensitive, partial matching)
      final hasMatchingComponent = _components.any((component) {
        final componentName = component.name.toLowerCase().trim();
        final laborCategory = labor.workCategory.toLowerCase().trim();
        
        // Exact match
        if (componentName == laborCategory) return true;
        
        // Partial match - check if labor category is contained in component name or vice versa
        if (componentName.contains(laborCategory) || laborCategory.contains(componentName)) return true;
        
        // Handle common variations
        if (componentName.replaceAll(' ', '').contains(laborCategory.replaceAll(' ', '')) ||
            laborCategory.replaceAll(' ', '').contains(componentName.replaceAll(' ', ''))) return true;
            
        return false;
      });
      
      // Only include labor cost if it's a custom component (no matching component exists)
      // AND it's not a work setup (work setups are budget allocations, not actual costs)
      if (!hasMatchingComponent && !labor.isWorkSetup) {
        laborTotal += labor.totalCost; // Use totalCost to show actual work done
        if (kDebugMode) print('  Custom Labor: ${labor.workCategory} - Cost: \$${labor.totalCost.toStringAsFixed(2)}');
      } else {
        if (kDebugMode) {
          if (hasMatchingComponent) {
            print('  Labor (existing component): ${labor.workCategory} - Cost: \$${labor.totalCost.toStringAsFixed(2)} (excluded from total)');
          } else if (labor.isWorkSetup) {
            print('  Labor (work setup): ${labor.workCategory} - Cost: \$${labor.totalCost.toStringAsFixed(2)} (excluded from total)');
          }
        }
      }
    }
    
    total = componentTotal + materialTotal + machineryTotal + laborTotal;
    
    // Debug logging
    print('💰 BUDGET CALCULATION:');
    print('  Components: \$${componentTotal.toStringAsFixed(2)}');
    print('  Materials: \$${materialTotal.toStringAsFixed(2)}');
    print('  Machinery: \$${machineryTotal.toStringAsFixed(2)}');
    print('  Labor (custom): \$${laborTotal.toStringAsFixed(2)}');
    print('  Total Used: \$${total.toStringAsFixed(2)}');
    print('  Project Budget: \$${widget.project.totalBudget.toStringAsFixed(2)}');
    print('  Remaining: \$${(widget.project.totalBudget - total).toStringAsFixed(2)}');
    
    // Debug individual components
    print('🔍 COMPONENT BREAKDOWN:');
    for (var component in _components) {
      print('  ${component.name}: amountUsed=\$${component.amountUsed.toStringAsFixed(2)}, totalCost=\$${component.totalCost.toStringAsFixed(2)}');
    }
    
    // Debug individual labor entries
    print('🔍 LABOR ENTRIES:');
    for (var labor in _labor) {
      final hasMatchingComponent = _components.any((component) {
        final componentName = component.name.toLowerCase().trim();
        final laborCategory = labor.workCategory.toLowerCase().trim();
        
        // Exact match
        if (componentName == laborCategory) return true;
        
        // Partial match - check if labor category is contained in component name or vice versa
        if (componentName.contains(laborCategory) || laborCategory.contains(componentName)) return true;
        
        // Handle common variations
        if (componentName.replaceAll(' ', '').contains(laborCategory.replaceAll(' ', '')) ||
            laborCategory.replaceAll(' ', '').contains(componentName.replaceAll(' ', ''))) return true;
            
        return false;
      });
      print('  ${labor.workCategory}: totalCost=\$${labor.totalCost.toStringAsFixed(2)}, totalValue=\$${labor.totalValue.toStringAsFixed(2)}, hasComponent=$hasMatchingComponent, isWorkSetup=${labor.isWorkSetup}');
    }
    
    return total;
  }

  // Calculate total area progress across all components
  double get _totalAreaProgress {
    if (_components.isEmpty) return 0.0;
    
    double totalArea = 0.0;
    double completedArea = 0.0;
    
    for (var component in _components) {
      totalArea += component.totalArea;
      completedArea += component.completedArea;
    }
    
    if (totalArea == 0) return 0.0;
    return completedArea / totalArea;
  }
  
  // Calculate budget progress (existing logic)
  double get _budgetProgress {
    if (widget.project.totalBudget <= 0) return 0.0;
    return _totalUsedBudget / widget.project.totalBudget;
  }
  
  // Combined overall progress (average of budget and area)
  double get _overallProgress {
    return (_budgetProgress + _totalAreaProgress) / 2;
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
            Tab(icon: Icon(Icons.business), text: 'Components'),
            Tab(icon: Icon(Icons.work), text: 'Labor'),
            Tab(icon: Icon(Icons.inventory), text: 'Materials'),
            Tab(icon: Icon(Icons.local_shipping), text: 'Machinery'),
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
                _buildLaborTab(),
                _buildMaterialsTab(),
                _buildMachineryTab(),
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

          // Quick Notes Section
          QuickNotesSection(
            project: _currentProject ?? widget.project,
            onRefresh: _loadProjectData,
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
                  
                  // Combined Progress Bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Combined Progress',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: _overallProgress,
                        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                        color: _getProgressColor(_overallProgress),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(_overallProgress * 100).toStringAsFixed(1)}% Complete',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Area Progress Bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Area Progress',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: _totalAreaProgress,
                        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                        color: _getProgressColor(_totalAreaProgress),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(_totalAreaProgress * 100).toStringAsFixed(1)}% Area Complete',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
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
                  Icons.business,
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
                  Icons.local_shipping,
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
      key: ValueKey('materials_${_materials.length}'), // Force rebuild when materials count changes
      project: _currentProject ?? widget.project,
      onRefresh: _loadProjectData,
    );
  }

  Widget _buildMachineryTab() {
    return MachinerySection(
      project: _currentProject ?? widget.project,
      onRefresh: _loadProjectData,
    );
  }

  Widget _buildLaborTab() {
    return LaborSection(
      key: ValueKey('labor_$_laborRefreshKey'), // Force rebuild when refresh key changes
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
      case 2: // Labor tab
        return FloatingActionButton(
          onPressed: _navigateToAddLabor,
          tooltip: 'Add Labor Entry',
          child: const Icon(Icons.add),
        );
      case 3: // Materials tab
        return FloatingActionButton(
          onPressed: _navigateToAddMaterial,
          tooltip: 'Add Material',
          child: const Icon(Icons.add),
        );
      case 4: // Machinery tab
        return FloatingActionButton(
          onPressed: _navigateToAddMachinery,
          tooltip: 'Add Machinery',
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
        builder: (context) => AddContractScreen(project: widget.project),
      ),
    ).then((_) {
      setState(() {
        _laborRefreshKey++; // Increment to force labor section rebuild
      });
      _loadProjectData();
    });
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
