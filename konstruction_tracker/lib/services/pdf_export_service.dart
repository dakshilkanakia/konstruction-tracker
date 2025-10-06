import 'dart:typed_data';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/project.dart';
import '../models/component.dart';
import '../models/labor.dart';
import '../models/material.dart' as models;
import '../models/machinery.dart';

class PdfExportService {
  static Future<void> exportProjectReport(
    BuildContext context,
    Project project,
    List<Component> components,
    List<Labor> labor,
    List<models.Material> materials,
    List<Machinery> machinery,
  ) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Generate PDF
      final pdfBytes = await _generateProjectReport(
        project,
        components,
        labor,
        materials,
        machinery,
      );

      // Debug: Check PDF size and first few bytes
      print('PDF generated: ${pdfBytes.length} bytes');
      if (pdfBytes.isNotEmpty) {
        print('PDF starts with: ${pdfBytes.take(10).toList()}');
      }

      // Close loading dialog
      Navigator.of(context).pop();

      // Download PDF in web browser
      _downloadPdf(pdfBytes, '${project.name}_Progress_Report.pdf');
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF report generated successfully! Check your downloads.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  static Future<Uint8List> _generateProjectReport(
    Project project,
    List<Component> components,
    List<Labor> labor,
    List<models.Material> materials,
    List<Machinery> machinery,
  ) async {
    final pdf = pw.Document();

    // Calculate totals
    final totalBudget = project.totalBudget;
    final usedBudget = _calculateUsedBudget(components, materials, machinery, labor);
    final budgetProgress = totalBudget > 0 ? (usedBudget / totalBudget * 100) : 0.0;
    
    final totalArea = components.fold(0.0, (sum, c) => sum + c.totalArea);
    final completedArea = components.fold(0.0, (sum, c) => sum + c.completedArea);
    final areaProgress = totalArea > 0 ? (completedArea / totalArea * 100) : 0.0;

    // Single page with all content
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              _buildSimpleHeader(project),
              pw.SizedBox(height: 20),
              
              // Overview
              _buildSimpleOverview(project, usedBudget, budgetProgress, completedArea, areaProgress),
              pw.SizedBox(height: 20),
              
              // Components
              if (components.isNotEmpty) ...[
                _buildSimpleSectionTitle('Components (${components.length})'),
                pw.SizedBox(height: 10),
                _buildSimpleComponentsList(components),
                pw.SizedBox(height: 20),
              ],
              
              // Labor
              if (labor.isNotEmpty) ...[
                _buildSimpleSectionTitle('Labor (${labor.length})'),
                pw.SizedBox(height: 10),
                _buildSimpleLaborList(labor),
                pw.SizedBox(height: 20),
              ],
              
              // Materials
              if (materials.isNotEmpty) ...[
                _buildSimpleSectionTitle('Materials (${materials.length})'),
                pw.SizedBox(height: 10),
                _buildSimpleMaterialsList(materials),
                pw.SizedBox(height: 20),
              ],
              
              // Machinery
              if (machinery.isNotEmpty) ...[
                _buildSimpleSectionTitle('Machinery (${machinery.length})'),
                pw.SizedBox(height: 10),
                _buildSimpleMachineryList(machinery),
              ],
            ],
          );
        },
      ),
    );

    final pdfBytes = await pdf.save();
    
    // Validate PDF content
    if (pdfBytes.isEmpty) {
      throw Exception('PDF generation failed: Empty PDF content');
    }
    
    // Check if it's a valid PDF (should start with %PDF)
    final pdfHeader = String.fromCharCodes(pdfBytes.take(4));
    if (pdfHeader != '%PDF') {
      throw Exception('PDF generation failed: Invalid PDF header');
    }
    
    return pdfBytes;
  }


  static double _calculateUsedBudget(
    List<Component> components,
    List<models.Material> materials,
    List<Machinery> machinery,
    List<Labor> labor,
  ) {
    double total = 0.0;
    
    // Add component costs
    total += components.fold(0.0, (sum, c) => sum + c.amountUsed);
    
    // Add material costs
    total += materials.fold(0.0, (sum, m) => sum + m.finalTotalCost);
    
    // Add machinery costs
    total += machinery.fold(0.0, (sum, m) => sum + m.totalCost);
    
    // Add labor costs (only progress entries, not contracts)
    total += labor.where((l) => l.isProgress).fold(0.0, (sum, l) => sum + l.totalCost);
    
    return total;
  }

  static void _downloadPdf(Uint8List pdfBytes, String fileName) {
    try {
      // Create blob with explicit PDF MIME type
      final blob = html.Blob([pdfBytes], 'application/pdf');
      
      // Create download URL
      final url = html.Url.createObjectUrlFromBlob(blob);
      
      // Create anchor element for download
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..style.display = 'none';
      
      // Add to DOM, click, and remove
      html.document.body?.append(anchor);
      anchor.click();
      anchor.remove();
      
      // Clean up URL after a short delay
      Future.delayed(const Duration(milliseconds: 100), () {
        html.Url.revokeObjectUrl(url);
      });
    } catch (e) {
      print('Error downloading PDF: $e');
      // Fallback: try direct download
      _downloadPdfFallback(pdfBytes, fileName);
    }
  }

  static void _downloadPdfFallback(Uint8List pdfBytes, String fileName) {
    try {
      // Alternative approach using data URL
      final base64 = html.window.btoa(String.fromCharCodes(pdfBytes));
      final dataUrl = 'data:application/pdf;base64,$base64';
      
      final anchor = html.AnchorElement(href: dataUrl)
        ..setAttribute('download', fileName)
        ..style.display = 'none';
      
      html.document.body?.append(anchor);
      anchor.click();
      anchor.remove();
    } catch (e) {
      print('Fallback download failed: $e');
    }
  }

  // Simple helper methods for web-compatible PDF generation
  static pw.Widget _buildSimpleHeader(Project project) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Construction Progress Report',
          style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Text('Project: ${project.name}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.Text('Location: ${project.location}'),
        pw.Text('Contractor: ${project.generalContractor}'),
        pw.Text('Start Date: ${DateFormat('MMM dd, yyyy').format(project.startDate)}'),
        pw.Text('Generated: ${DateFormat('MMM dd, yyyy').format(DateTime.now())}'),
      ],
    );
  }

  static pw.Widget _buildSimpleOverview(
    Project project,
    double usedBudget,
    double budgetProgress,
    double completedArea,
    double areaProgress,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Project Overview', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        pw.Text('Budget Progress: ${budgetProgress.toStringAsFixed(1)}% (\$${usedBudget.toStringAsFixed(2)} of \$${project.totalBudget.toStringAsFixed(2)})'),
        pw.Text('Area Progress: ${areaProgress.toStringAsFixed(1)}% (${completedArea.toStringAsFixed(1)} sq ft completed)'),
      ],
    );
  }

  static pw.Widget _buildSimpleSectionTitle(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
    );
  }

  static pw.Widget _buildSimpleComponentsList(List<Component> components) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: components.take(10).map((component) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 8),
        child: pw.Text(
          '• ${component.name}: ${component.totalArea.toStringAsFixed(1)} sq ft, \$${component.amountUsed.toStringAsFixed(2)} used, ${(component.overallProgressPercentage * 100).toStringAsFixed(1)}% complete',
          style: pw.TextStyle(fontSize: 10),
        ),
      )).toList()
        ..addAll(components.length > 10 ? [
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 4),
            child: pw.Text(
              '... and ${components.length - 10} more components',
              style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic),
            ),
          ),
        ] : []),
    );
  }

  static pw.Widget _buildSimpleLaborList(List<Labor> labor) {
    final contracts = labor.where((l) => l.isContract).toList();
    final progressEntries = labor.where((l) => l.isProgress).toList();
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (contracts.isNotEmpty) ...[
          pw.Text('Contracts:', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 5),
          ...contracts.take(5).map((contract) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Text(
              '• ${contract.workCategory}: ${contract.totalSqFt?.toStringAsFixed(1) ?? '0.0'} sq ft, \$${contract.totalValue.toStringAsFixed(2)}',
              style: pw.TextStyle(fontSize: 10),
            ),
          )),
          if (contracts.length > 5) pw.Text('... and ${contracts.length - 5} more contracts', style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic)),
          pw.SizedBox(height: 10),
        ],
        if (progressEntries.isNotEmpty) ...[
          pw.Text('Progress Entries:', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 5),
          ...progressEntries.take(8).map((progress) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Text(
              '• ${progress.workCategory}: ${progress.completedSqFt?.toStringAsFixed(1) ?? '0.0'} sq ft, \$${progress.totalCost.toStringAsFixed(2)}${progress.location != null ? ', ${progress.location}' : ''}',
              style: pw.TextStyle(fontSize: 10),
            ),
          )),
          if (progressEntries.length > 8) pw.Text('... and ${progressEntries.length - 8} more progress entries', style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic)),
        ],
      ],
    );
  }

  static pw.Widget _buildSimpleMaterialsList(List<models.Material> materials) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: materials.take(10).map((material) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.Text(
          '• ${material.name ?? 'Unnamed'}: ${material.quantityOrdered?.toStringAsFixed(1) ?? '0.0'} ${material.unit ?? 'units'}, \$${material.finalTotalCost.toStringAsFixed(2)}',
          style: pw.TextStyle(fontSize: 10),
        ),
      )).toList()
        ..addAll(materials.length > 10 ? [
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 4),
            child: pw.Text(
              '... and ${materials.length - 10} more materials',
              style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic),
            ),
          ),
        ] : []),
    );
  }

  static pw.Widget _buildSimpleMachineryList(List<Machinery> machinery) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: machinery.take(10).map((machine) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.Text(
          '• ${machine.name ?? 'Unnamed'}: ${machine.hoursUsed?.toStringAsFixed(1) ?? '0.0'} hrs, \$${machine.totalCost.toStringAsFixed(2)}',
          style: pw.TextStyle(fontSize: 10),
        ),
      )).toList()
        ..addAll(machinery.length > 10 ? [
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 4),
            child: pw.Text(
              '... and ${machinery.length - 10} more machinery',
              style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic),
            ),
          ),
        ] : []),
    );
  }
}
