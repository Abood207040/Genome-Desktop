import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
// Note: Assuming AppBackground is accessible via this path
import '../../widgets/app_background.dart';

class ResultScreen extends StatelessWidget {
  // Data passed from the previous screen
  final String predictedDisease;
  final String predictedRisk;

  const ResultScreen({
    super.key,
    required this.predictedDisease,
    required this.predictedRisk,
  });

  Future<void> _generateAndSavePDF(BuildContext context) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'GENETIC ANALYSIS REPORT',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue,
                    ),
                  ),
                  pw.SizedBox(height: 30),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(20),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey),
                      borderRadius: pw.BorderRadius.circular(10),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Predicted Disease:',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.red,
                          ),
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text(predictedDisease, style: const pw.TextStyle(fontSize: 14)),
                        pw.SizedBox(height: 20),
                        pw.Text(
                          'Predicted Risk:',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.red,
                          ),
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text(predictedRisk, style: const pw.TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 30),
                  pw.Text(
                    'Generated on ${DateTime.now().toString().split('.')[0]}',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                  ),
                ],
              ),
            );
          },
        ),
      );

      final output = await getApplicationDocumentsDirectory();
      final fileName = 'genetic_analysis_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${output.path}/$fileName');

      await file.writeAsBytes(await pdf.save());

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report saved as $fileName'),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () async {
                final result = await OpenFile.open(file.path);
                if (result.type != ResultType.done) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Could not open file: ${result.message}')),
                    );
                  }
                }
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate PDF: $e')),
        );
      }
    }
  }

  // Reusable widget to display a result field with the requested styling
  Widget _buildResultField(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    // Styling attempt to match the soft inner shadow/gradient effect in the image
    final fieldColor = Theme.of(context).cardColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
          child: Text(
            "$label:",
            style: TextStyle(
              color: Colors.red.shade700, // Matches the red font color
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
        Container(
          width: 350,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          decoration: BoxDecoration(
            color: fieldColor,
            borderRadius: BorderRadius.circular(10),
            // Mocking the subtle inner shadow/gradient seen in the photo
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.grey.shade200,
                      offset: const Offset(0, 2),
                      blurRadius: 5,
                      spreadRadius: 1,
                    ),
                  ],
            // Gradient/Color to mimic the light fill
            gradient: LinearGradient(
              colors: [fieldColor.withOpacity(0.9), fieldColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Genetic Analysis Results'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      // AppBackground is assumed to provide the DNA helix pattern as seen in the photo's background
      body: AppBackground(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 450),
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: theme.cardColor, // Main card background
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Image at the top (aboveName.png or a fallback Icon)
                Image.asset(
                  "assets/images/aboveName.png",
                  height: 100,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.assignment,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                ),
                const SizedBox(height: 40),

                // Predicted Disease Field
                _buildResultField(
                  context,
                  label: "Predicted Disease",
                  value: predictedDisease,
                ),

                // Predicted Risk Field
                _buildResultField(
                  context,
                  label: "Predicted Risk",
                  value: predictedRisk,
                ),

                const SizedBox(height: 30),

                // Action Buttons Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Open PDF Button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          // Generate and open PDF
                          try {
                            final pdf = pw.Document();

                            pdf.addPage(
                              pw.Page(
                                pageFormat: PdfPageFormat.a4,
                                build: (pw.Context context) {
                                  return pw.Center(
                                    child: pw.Column(
                                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                                      children: [
                                        pw.Text(
                                          'GENETIC ANALYSIS REPORT',
                                          style: pw.TextStyle(
                                            fontSize: 24,
                                            fontWeight: pw.FontWeight.bold,
                                            color: PdfColors.blue,
                                          ),
                                        ),
                                        pw.SizedBox(height: 30),
                                        pw.Container(
                                          padding: const pw.EdgeInsets.all(20),
                                          decoration: pw.BoxDecoration(
                                            border: pw.Border.all(color: PdfColors.grey),
                                            borderRadius: pw.BorderRadius.circular(10),
                                          ),
                                          child: pw.Column(
                                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                                            children: [
                                              pw.Text(
                                                'Predicted Disease:',
                                                style: pw.TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: pw.FontWeight.bold,
                                                  color: PdfColors.red,
                                                ),
                                              ),
                                              pw.SizedBox(height: 5),
                                              pw.Text(predictedDisease, style: const pw.TextStyle(fontSize: 14)),
                                              pw.SizedBox(height: 20),
                                              pw.Text(
                                                'Predicted Risk:',
                                                style: pw.TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: pw.FontWeight.bold,
                                                  color: PdfColors.red,
                                                ),
                                              ),
                                              pw.SizedBox(height: 5),
                                              pw.Text(predictedRisk, style: const pw.TextStyle(fontSize: 14)),
                                            ],
                                          ),
                                        ),
                                        pw.SizedBox(height: 30),
                                        pw.Text(
                                          'Generated on ${DateTime.now().toString().split('.')[0]}',
                                          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            );

                            final output = await getTemporaryDirectory();
                            final fileName = 'genetic_analysis_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
                            final file = File('${output.path}/$fileName');

                            await file.writeAsBytes(await pdf.save());

                            final result = await OpenFile.open(file.path);
                            if (result.type != ResultType.done) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Could not open file: ${result.message}')),
                                );
                              }
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to open PDF: $e')),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.open_in_new, color: Colors.white),
                        label: const Text(
                          "Open",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 20),

                    // Save PDF Button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _generateAndSavePDF(context),
                        icon: const Icon(Icons.save, color: Colors.white),
                        label: const Text(
                          "Save",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E2A85),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}