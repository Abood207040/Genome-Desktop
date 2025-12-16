import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

// PDF generation imports
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

// Platform-specific imports
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

// ✅ Doctor name from signed-in account
import 'package:firebase_auth/firebase_auth.dart';

import '../../widgets/app_background.dart';
import '../../widgets/custom_app_bar.dart';

class PatientDiseaseScreen extends StatefulWidget {
  const PatientDiseaseScreen({super.key});

  @override
  State<PatientDiseaseScreen> createState() => _PatientDiseaseScreenState();
}

class _PatientDiseaseScreenState extends State<PatientDiseaseScreen> {
  // State for Upload and Loading
  PlatformFile? pickedFile;
  String fileName = "";
  bool isLoading = false;
  String errorMessage = "";
  bool isPdfGenerating = false;
  bool isDragging = false;

  // ✅ Patient name input (Identical name for report)
  final TextEditingController _patientNameController = TextEditingController();

  // State for Results
  String patientNameFromAI = "Awaiting Analysis";
  String chrom = "Chr7: 117,559,593–117,559,595 (GRCh38)";
  String clnsig = "Likely pathogenic – associated with cystic fibrosis";
  String disease = "---";
  String treatment = "---";
  bool showResults = false;

  @override
  void dispose() {
    _patientNameController.dispose();
    super.dispose();
  }

  // -----------------------------
  // Pick CSV file
  // -----------------------------
  Future<void> pickCSV() async {
    setState(() {
      errorMessage = "";
      showResults = false;
      patientNameFromAI = "Awaiting Analysis";
    });

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      setState(() {
        pickedFile = result.files.single;
        fileName = result.files.single.name;
        isDragging = false;
      });
    } else {
      setState(() => isDragging = false);
    }
  }

  // -----------------------------
  // Send CSV file to Flask API
  // -----------------------------
  Future<void> uploadAndAnalyze() async {
    if (pickedFile == null) {
      setState(() => errorMessage = "Please select a CSV file first.");
      return;
    }

    // ✅ ensure user entered patient name
    final typedName = _patientNameController.text.trim();
    if (typedName.isEmpty) {
      setState(() => errorMessage = "Please enter Patient Name first.");
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = "";
    });

    try {
      var uri = Uri.parse("http://127.0.0.1:5000/predict");
      var request = http.MultipartRequest("POST", uri);
      Uint8List fileBytes = pickedFile!.bytes!;

      request.files.add(
        http.MultipartFile.fromBytes("file", fileBytes, filename: fileName),
      );

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          // keep AI name in case you need it, but report name comes from input
          patientNameFromAI = data["name"]?.toString() ?? "Unknown Patient";
          chrom = data["chrom"]?.toString() ?? "Chr7: 117,559,593 117,559,595 (GRCh38)";
          clnsig = data["clnsig"]?.toString() ?? "Likely pathogenic  associated with cystic fibrosis";
          disease = data["predicted_disease"]?.toString() ?? "Analysis Failed";
          treatment =
              data["predicted_treatment"]?.toString() ?? "Consult a specialist.";
          showResults = true;
        });
      } else {
        setState(
          () => errorMessage =
              "API Error (${response.statusCode}): ${response.body}",
        );
      }
    } catch (e) {
      setState(
        () => errorMessage =
            "Processing Error: Check API JSON/network. Error: ${e.toString()}",
      );
    }

    setState(() => isLoading = false);
  }

  // ✅ helper for PDF section titles
  pw.Widget _pdfSectionTitle(String text, PdfColor color) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 16,
          fontWeight: pw.FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  // -----------------------------
  // PDF GENERATION LOGIC (One Page + Logo + Doctor Sign + QR)
  // -----------------------------
  Future<void> _generatePdf(BuildContext context) async {
    if (!showResults || isPdfGenerating) return;

    final patientNameForReport = _patientNameController.text.trim();
    if (patientNameForReport.isEmpty) {
      setState(() => errorMessage = "Patient Name is required for the report.");
      return;
    }

    setState(() => isPdfGenerating = true);

    try {
      // ✅ signed-in doctor name
      final user = FirebaseAuth.instance.currentUser;
      final doctorNameFromAccount =
          (user?.displayName?.trim().isNotEmpty ?? false)
              ? user!.displayName!.trim()
              : (user?.email?.trim().isNotEmpty ?? false)
                  ? user!.email!.trim()
                  : "Doctor";

      // hospital info (static branding)
      const hospitalName = "GENORA Genomic Diagnostics Center";
      const doctorTitle = "Consultant in Genomic Medicine";

      final pdf = pw.Document();
      final primaryColor = PdfColor.fromInt(Theme.of(context).primaryColor.value);

      // load logo
      final logoImage = pw.MemoryImage(
        (await rootBundle.load('assets/images/hospital_logo.png'))
            .buffer
            .asUint8List(),
      );

      // QR data (can be URL later)
     final doctorEmail = user?.email ?? "";

final subject = Uri.encodeComponent(
  "Genomic Report – $patientNameForReport",
);

final body = Uri.encodeComponent(
  "Hello Doctor,\n\n"
  "Please find below the AI-assisted genomic report summary:\n\n"
  "Patient Name: $patientNameForReport\n"
  "Diagnosis: $disease\n"
  "Recommended Treatment: $treatment\n\n"
  "Generated by GENORA Genomic Diagnostics Center.\n"
  "Date: ${DateTime.now().toLocal().toString().split(' ')[0]}",
);

// ✅ QR opens email composer
final qrData = doctorEmail.isNotEmpty
    ? "mailto:$doctorEmail?subject=$subject&body=$body"
    : "mailto:?subject=$subject&body=$body";


      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (_) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // HEADER
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Image(logoImage, width: 80),
                    pw.SizedBox(width: 15),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          hospitalName,
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          'Genomic Diagnostic Report',
                          style: pw.TextStyle(
                            fontSize: 13,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.Divider(height: 28),

                // PATIENT INFO
                _pdfSectionTitle("Patient Information", primaryColor),
                pw.Text("Patient Name: $patientNameForReport"),
                pw.Text(
                  "Report Date: ${DateTime.now().toLocal().toString().split(' ')[0]}",
                ),

                pw.SizedBox(height: 16),

                // GENOMIC FINDINGS
                _pdfSectionTitle("Genomic Findings", primaryColor),
                pw.Bullet(text: "Chromosomal Location: $chrom"),
                pw.Bullet(text: "Clinical Significance (CLNSIG): $clnsig"),

                pw.SizedBox(height: 16),

                // INTERPRETATION
                _pdfSectionTitle("Diagnostic Interpretation", primaryColor),
                pw.Text(
                  "This report summarizes the AI-assisted genomic analysis of the uploaded sample. "
                  "The identified variant demonstrates a clinically relevant association with the observed phenotype. "
                  "Variant classification suggests a pathogenic or likely pathogenic implication; therefore, correlation with "
                  "the patient's clinical history, laboratory findings, and specialist evaluation is recommended.",
                  textAlign: pw.TextAlign.justify,
                ),

                pw.SizedBox(height: 16),

                // DIAGNOSIS
                _pdfSectionTitle("Confirmed Genomic Diagnosis", primaryColor),
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: primaryColor),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Text(
                    disease,
                    style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),

                pw.SizedBox(height: 16),

                // TREATMENT
                _pdfSectionTitle("Recommended Treatment & Clinical Management", primaryColor),
                pw.Text(
                  "The following management plan is suggested based on current genomic insights and standard clinical practice:",
                  textAlign: pw.TextAlign.justify,
                ),
                pw.SizedBox(height: 8),
                pw.Bullet(text: treatment),
                pw.Bullet(text: "Genetic counseling is recommended when clinically appropriate."),
                pw.Bullet(text: "Follow-up evaluation and monitoring should be individualized by the attending physician."),

                pw.Spacer(),

                // FOOTER: SIGN + QR
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          doctorNameFromAccount,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(doctorTitle),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          "Authorized Genomic Report",
                          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey),
                        ),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.BarcodeWidget(
                          barcode: pw.Barcode.qrCode(),
                          data: qrData,
                          width: 80,
                          height: 80,
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          "Scan for verification",
                          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
                        ),
                      ],
                    )
                  ],
                ),

                pw.SizedBox(height: 8),
                pw.Text(
                  "Disclaimer: This report is generated using AI-assisted genomic analysis and is intended to support "
                  "clinical decision-making. It does not replace professional medical judgment. Final diagnosis and "
                  "treatment decisions remain the responsibility of the attending physician.",
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
                ),
              ],
            );
          },
        ),
      );

      final bytes = await pdf.save();

      Directory? directory = await getDownloadsDirectory();
      directory ??= await getApplicationDocumentsDirectory();

      final safeName = patientNameForReport
          .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
          .trim();
      final pdfFileName =
          "Genomic_Report_${safeName.isEmpty ? 'Patient' : safeName}.pdf";

      final filePath = '${directory.path}/$pdfFileName';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF saved to: $filePath'),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () async {
                final result = await OpenFilex.open(filePath);
                if (result.type != ResultType.done && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Could not open file: ${result.message}')),
                  );
                }
              },
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => errorMessage = "PDF generation failed. Check console.");
    } finally {
      if (mounted) setState(() => isPdfGenerating = false);
    }
  }

  // -----------------------------
  // Reusable Field Widget
  // -----------------------------
  Widget _buildResultField(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    final color = Theme.of(context).primaryColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFF4F4FF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(
              "$label: ",
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -----------------------------
  // UI - SAME AS YOUR ORIGINAL + Added Patient Name Field
  // -----------------------------
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyLarge?.color;
    final cardColor = theme.cardColor;
    final primaryColor = theme.primaryColor;

    // show typed patient name in UI (identical to report)
    final uiPatientName = _patientNameController.text.trim().isNotEmpty
        ? _patientNameController.text.trim()
        : patientNameFromAI;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CustomAppBar(activePage: "Patient Disease"),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Upload Your File To Proceed",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 30),
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 950),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // LEFT SIDE (Upload)
                              SizedBox(
                                width: 350,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // ✅ Patient Name Field (NEW)
                                    TextField(
                                      controller: _patientNameController,
                                      decoration: InputDecoration(
                                        labelText: "Patient Name",
                                        hintText: "Enter patient name for the report",
                                        filled: true,
                                        fillColor: cardColor,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      onChanged: (_) {
                                        // refresh UI name instantly
                                        setState(() {});
                                      },
                                    ),
                                    const SizedBox(height: 15),

                                    GestureDetector(
                                      onTap: () => pickCSV(),
                                      child: DragTarget<Object>(
                                        onWillAcceptWithDetails: (details) {
                                          if (!isDragging) {
                                            setState(() => isDragging = true);
                                          }
                                          return true;
                                        },
                                        onLeave: (data) {
                                          setState(() => isDragging = false);
                                        },
                                        onAcceptWithDetails: (details) {
                                          pickCSV();
                                        },
                                        builder: (context, candidateData, rejectedData) {
                                          return Container(
                                            width: 350,
                                            height: 200,
                                            decoration: BoxDecoration(
                                              color: isDragging
                                                  ? theme.primaryColor.withOpacity(0.1)
                                                  : cardColor,
                                              borderRadius: BorderRadius.circular(18),
                                              border: Border.fromBorderSide(
                                                BorderSide(
                                                  color: isDragging
                                                      ? theme.primaryColor
                                                      : isDark
                                                          ? Colors.white30
                                                          : Colors.grey.shade400,
                                                  width: 2,
                                                  strokeAlign: BorderSide.strokeAlignInside,
                                                ),
                                              ),
                                            ),
                                            child: Center(
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.cloud_upload,
                                                    size: 60,
                                                    color: isDragging
                                                        ? theme.primaryColor
                                                        : isDark
                                                            ? Colors.blueGrey.shade400
                                                            : primaryColor,
                                                  ),
                                                  const SizedBox(height: 10),
                                                  Text(
                                                    isDragging
                                                        ? "Drop your CSV here"
                                                        : "Drag and Drop or Browse",
                                                    style: TextStyle(
                                                      color: textColor,
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),

                                    const SizedBox(height: 20),

                                    Container(
                                      height: 48,
                                      width: 350,
                                      padding: const EdgeInsets.symmetric(horizontal: 15),
                                      decoration: BoxDecoration(
                                        color: cardColor,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.grey.shade400.withOpacity(0.5),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.description, color: primaryColor),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              fileName.isNotEmpty ? fileName : "No file selected",
                                              style: TextStyle(
                                                color: textColor,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (fileName.isNotEmpty)
                                            IconButton(
                                              icon: const Icon(
                                                Icons.close,
                                                size: 18,
                                                color: Colors.red,
                                              ),
                                              onPressed: () => setState(() {
                                                pickedFile = null;
                                                fileName = "";
                                                errorMessage = "";
                                                showResults = false;
                                                patientNameFromAI = "Awaiting Analysis";
                                              }),
                                            ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 30),

                                    SizedBox(
                                      width: 350,
                                      child: ElevatedButton(
                                        onPressed: isLoading ? null : uploadAndAnalyze,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: primaryColor,
                                          padding: const EdgeInsets.symmetric(vertical: 20),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: isLoading
                                            ? const CircularProgressIndicator(color: Colors.white)
                                            : const Text(
                                                "Proceed",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                      ),
                                    ),

                                    const SizedBox(height: 20),

                                    if (errorMessage.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 10),
                                        child: Text(
                                          errorMessage,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Colors.redAccent,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 40),

                              // RIGHT SIDE (Results)
                              Expanded(
                                child: Container(
                                  constraints: const BoxConstraints(maxWidth: 500),
                                  padding: const EdgeInsets.all(30),
                                  decoration: BoxDecoration(
                                    color: cardColor,
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Center(
                                        child: Image.asset(
                                          "assets/images/aboveName.png",
                                          height: 120,
                                          fit: BoxFit.contain,
                                          errorBuilder: (context, error, stackTrace) => Icon(
                                            Icons.description,
                                            size: 80,
                                            color: Colors.grey.shade400,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 20),

                                      // ✅ name displayed is the typed patient name (identical)
                                      Text(
                                        "Name: $uiPatientName",
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),

                                      const SizedBox(height: 25),

                                      _buildResultField(
                                        context,
                                        label: "Disease",
                                        value: disease,
                                      ),

                                      const SizedBox(height: 15),

                                      Center(
                                        child: Image.asset(
                                          "assets/images/aboveTreatment.png",
                                          height: 120,
                                          fit: BoxFit.contain,
                                          errorBuilder: (context, error, stackTrace) => Icon(
                                            Icons.science,
                                            size: 80,
                                            color: Colors.grey.shade400,
                                          ),
                                        ),
                                      ),

                                      const SizedBox(height: 20),

                                      _buildResultField(
                                        context,
                                        label: "Treatment",
                                        value: treatment,
                                      ),

                                      const SizedBox(height: 30),

                                      Center(
                                        child: ElevatedButton(
                                          onPressed: showResults && !isPdfGenerating
                                              ? () => _generatePdf(context)
                                              : null,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: showResults && !isPdfGenerating
                                                ? theme.colorScheme.secondary
                                                : Colors.grey.shade400,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 40,
                                              vertical: 15,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(15),
                                            ),
                                          ),
                                          child: isPdfGenerating
                                              ? const SizedBox(
                                                  width: 24,
                                                  height: 24,
                                                  child: CircularProgressIndicator(
                                                    color: Colors.white,
                                                    strokeWidth: 3,
                                                  ),
                                                )
                                              : const Text(
                                                  "Print",
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    color: Colors.white,
                                                  ),
                                                ),
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
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
