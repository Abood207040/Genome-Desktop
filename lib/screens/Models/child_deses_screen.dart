import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

// PDF
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

// Desktop
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

// Auth
import 'package:firebase_auth/firebase_auth.dart';

import '../../widgets/app_background.dart';
import '../../widgets/custom_app_bar.dart';

class ChildGeneticsScreen extends StatefulWidget {
  const ChildGeneticsScreen({super.key});

  @override
  State<ChildGeneticsScreen> createState() => _ChildGeneticsScreenState();
}

class _ChildGeneticsScreenState extends State<ChildGeneticsScreen> {
  PlatformFile? pickedFile;
  String fileName = "";
  bool isLoading = false;
  bool isPdfGenerating = false;
  bool isDragging = false;
  String errorMessage = "";

  final TextEditingController _childNameController =
      TextEditingController();

  String predictedDisease = "---";
  String predictedRisk = "---";
  bool showResults = false;

  @override
  void dispose() {
    _childNameController.dispose();
    super.dispose();
  }

  Future<void> pickCSV() async {
    setState(() {
      errorMessage = "";
      showResults = false;
    });

    final result = await FilePicker.platform.pickFiles(
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

  Future<void> uploadAndAnalyze() async {
    if (pickedFile == null) {
      setState(() => errorMessage = "Please select a CSV file first.");
      return;
    }

    final childName = _childNameController.text.trim();
    if (childName.isEmpty) {
      setState(() => errorMessage = "Please enter Child Name first.");
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = "";
    });

    try {
      final uri = Uri.parse(
        "https://genetic-disease-api.onrender.com/predict_csv",
      );

      final request = http.MultipartRequest("POST", uri);
      request.files.add(
        http.MultipartFile.fromBytes(
          "file",
          pickedFile!.bytes!,
          filename: fileName,
        ),
      );

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["predictions"] != null &&
            data["predictions"].isNotEmpty) {
          final prediction = data["predictions"][0];

          setState(() {
            predictedDisease =
                prediction["disease_prediction"] ??
                    "Not Identified";
            predictedRisk =
                prediction["risk_prediction"] ??
                    "No Risk Data";
            showResults = true;
          });
        } else {
          setState(() {
            errorMessage =
                "No prediction data returned from API.";
          });
        }
      } else {
        setState(() {
          errorMessage =
              "API Error (${response.statusCode})";
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Processing error: $e";
      });
    }

    setState(() => isLoading = false);
  }

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

  Future<void> _generatePdf(BuildContext context) async {
    if (!showResults || isPdfGenerating) return;

    final childName = _childNameController.text.trim();
    if (childName.isEmpty) return;

    setState(() => isPdfGenerating = true);

    try {
      final user = FirebaseAuth.instance.currentUser;

      final doctorName =
          (user?.displayName?.trim().isNotEmpty ?? false)
              ? user!.displayName!.trim()
              : (user?.email?.trim().isNotEmpty ?? false)
                  ? user!.email!.trim()
                  : "Doctor";

      final doctorEmail = user?.email ?? "";

      const hospitalName = "GENORA Genomic Diagnostics Center";
      const doctorTitle = "Consultant in Genomic Medicine";

      final reportDate =
          DateTime.now().toLocal().toString().split(' ')[0];

      final subject = Uri.encodeComponent(
        "Child Genomic Report – $childName",
      );

      final body = Uri.encodeComponent(
        "Child Name: $childName\n"
        "Predicted Disease: $predictedDisease\n"
        "Risk Level: $predictedRisk\n\n"
        "Generated by GENORA Genomic Diagnostics Center\n"
        "Date: $reportDate",
      );

      final qrData = doctorEmail.isNotEmpty
          ? "mailto:$doctorEmail?subject=$subject&body=$body"
          : "mailto:?subject=$subject&body=$body";

      final pdf = pw.Document();
      final primaryColor =
          PdfColor.fromInt(
            Theme.of(context).primaryColor.value,
          );

      final logoImage = pw.MemoryImage(
        (await rootBundle
                .load('assets/images/hospital_logo.png'))
            .buffer
            .asUint8List(),
      );

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (_) {
            return pw.Column(
              crossAxisAlignment:
                  pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  children: [
                    pw.Image(logoImage, width: 80),
                    pw.SizedBox(width: 15),
                    pw.Column(
                      crossAxisAlignment:
                          pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          hospitalName,
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight:
                                pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          "Genomic Diagnostic Report",
                          style: pw.TextStyle(
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.Divider(height: 28),

                _pdfSectionTitle(
                    "Child Information", primaryColor),
                pw.Text("Child Name: $childName"),
                pw.Text("Report Date: $reportDate"),

                pw.SizedBox(height: 16),

                _pdfSectionTitle(
                    "Genomic Findings", primaryColor),
                pw.Bullet(
                    text:
                        "Predicted Disease: $predictedDisease"),
                pw.Bullet(
                    text:
                        "Risk Level: $predictedRisk"),

                pw.SizedBox(height: 16),

                _pdfSectionTitle(
                    "Diagnostic Interpretation",
                    primaryColor),
                pw.Text(
                  "This report summarizes the AI-assisted genomic analysis "
                  "of the uploaded sample. The identified genetic markers "
                  "suggest a potential association with inherited conditions. "
                  "Clinical correlation and specialist evaluation are strongly recommended.",
                  textAlign: pw.TextAlign.justify,
                ),

                pw.SizedBox(height: 16),

                _pdfSectionTitle(
                    "Clinical Recommendation",
                    primaryColor),
                pw.Bullet(
                    text:
                        "Follow-up genetic counseling is advised."),
                pw.Bullet(
                    text:
                        "Further confirmatory diagnostic testing may be required."),
                pw.Bullet(
                    text:
                        "Clinical management should be individualized by the attending physician."),

                pw.Spacer(),
                pw.Divider(),

                pw.Row(
                  mainAxisAlignment:
                      pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment:
                          pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          doctorName,
                          style: pw.TextStyle(
                              fontWeight:
                                  pw.FontWeight.bold),
                        ),
                        pw.Text(doctorTitle),
                        pw.Text(
                          "Authorized Genomic Report",
                          style: const pw.TextStyle(
                            fontSize: 9,
                            color: PdfColors.grey,
                          ),
                        ),
                      ],
                    ),
                    pw.BarcodeWidget(
                      barcode: pw.Barcode.qrCode(),
                      data: qrData,
                      width: 80,
                      height: 80,
                    ),
                  ],
                ),

                pw.SizedBox(height: 8),
                pw.Text(
                  "Disclaimer: This report is generated using AI-assisted genomic analysis "
                  "and is intended to support clinical decision-making. "
                  "It does not replace professional medical judgment.",
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey,
                  ),
                ),
              ],
            );
          },
        ),
      );

      final bytes = await pdf.save();

      Directory? dir = await getDownloadsDirectory();
      dir ??= await getApplicationDocumentsDirectory();

      final safeName =
          childName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');

      final path =
          "${dir.path}/Child_Genomic_Report_$safeName.pdf";

      await File(path).writeAsBytes(bytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("PDF saved to: $path"),
            action: SnackBarAction(
              label: "Open",
              onPressed: () => OpenFilex.open(path),
            ),
          ),
        );
      }
    } catch (_) {
      setState(() =>
          errorMessage = "PDF generation failed.");
    } finally {
      if (mounted) {
        setState(() => isPdfGenerating = false);
      }
    }
  }

  Widget _buildResultField(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;
    final color = Theme.of(context).primaryColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 15, vertical: 12),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : const Color(0xFFF4F4FF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(
              "$label: ",
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark =
        theme.brightness == Brightness.dark;
    final textColor =
        theme.textTheme.bodyLarge?.color;
    final cardColor = theme.cardColor;
    final primaryColor = theme.primaryColor;

    final uiChildName =
        _childNameController.text.trim().isNotEmpty
            ? _childNameController.text.trim()
            : "Awaiting Analysis";

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: Column(
          children: [
            const CustomAppBar(
                activePage: "Child Genetics"),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Upload Your File To Proceed",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight:
                              FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 30),
                      Center(
                        child: ConstrainedBox(
                          constraints:
                              const BoxConstraints(
                                  maxWidth: 950),
                          child: Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 350,
                                child: Column(
                                  children: [
                                    TextField(
                                      controller:
                                          _childNameController,
                                      decoration:
                                          InputDecoration(
                                        labelText:
                                            "Child Name",
                                        filled: true,
                                        fillColor:
                                            cardColor,
                                        border:
                                            OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius
                                                  .circular(
                                                      10),
                                        ),
                                      ),
                                      onChanged:
                                          (_) =>
                                              setState(
                                                  () {}),
                                    ),
                                    const SizedBox(
                                        height: 15),

                                    GestureDetector(
                                      onTap: pickCSV,
                                      child:
                                          DragTarget<
                                              Object>(
                                        onWillAcceptWithDetails:
                                            (_) {
                                          setState(() =>
                                              isDragging =
                                                  true);
                                          return true;
                                        },
                                        onLeave:
                                            (_) =>
                                                setState(
                                                    () =>
                                                        isDragging =
                                                            false),
                                        onAcceptWithDetails:
                                            (_) =>
                                                pickCSV(),
                                        builder:
                                            (context,
                                                __,
                                                ___) {
                                          return Container(
                                            height:
                                                200,
                                            decoration:
                                                BoxDecoration(
                                              color: isDragging
                                                  ? primaryColor
                                                      .withOpacity(
                                                          0.1)
                                                  : cardColor,
                                              borderRadius:
                                                  BorderRadius
                                                      .circular(
                                                          18),
                                              border:
                                                  Border
                                                      .fromBorderSide(
                                                BorderSide(
                                                  color: isDragging
                                                      ? primaryColor
                                                      : isDark
                                                          ? Colors
                                                              .white30
                                                          : Colors
                                                              .grey
                                                              .shade400,
                                                  width:
                                                      2,
                                                ),
                                              ),
                                            ),
                                            child:
                                                Center(
                                              child:
                                                  Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .center,
                                                children: [
                                                  Icon(
                                                    Icons
                                                        .cloud_upload,
                                                    size:
                                                        60,
                                                    color: primaryColor,
                                                  ),
                                                  const SizedBox(
                                                      height:
                                                          10),
                                                  Text(
                                                    isDragging
                                                        ? "Drop your CSV here"
                                                        : "Drag and Drop or Browse",
                                                    style:
                                                        TextStyle(
                                                      color:
                                                          textColor,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(
                                        height: 30),
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
          }),
        ),
    ],
  ),
),
SizedBox(height: 20,),

                                    SizedBox(
                                      width:
                                          double.infinity,
                                      child:
                                          ElevatedButton(
                                        onPressed: isLoading
                                            ? null
                                            : uploadAndAnalyze,
                                        style: ElevatedButton
                                            .styleFrom(
                                          backgroundColor:
                                              primaryColor,
                                          padding:
                                              const EdgeInsets
                                                  .symmetric(
                                            vertical:
                                                20,
                                          ),
                                        ),
                                        child: isLoading
                                            ? const CircularProgressIndicator(
                                                color:
                                                    Colors.white,
                                              )
                                            : const Text(
                                                "Proceed",
                                                style:
                                                    TextStyle(
                                                  color:
                                                      Colors.white,
                                                  fontSize:
                                                      18,
                                                ),
                                              ),
                                      ),
                                    ),

                                    if (errorMessage
                                        .isNotEmpty)
                                      Padding(
                                        padding:
                                            const EdgeInsets
                                                .only(
                                                    top:
                                                        10),
                                        child: Text(
                                          errorMessage,
                                          style:
                                              const TextStyle(
                                            color: Colors
                                                .redAccent,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(
                                  width: 40),
                              Expanded(
                                child: Container(
                                  padding:
                                      const EdgeInsets
                                          .all(30),
                                  decoration:
                                      BoxDecoration(
                                    color: cardColor,
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                                18),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                    children: [
                                      Text(
                                        "Name: $uiChildName",
                                        style:
                                            TextStyle(
                                          fontSize:
                                              22,
                                          fontWeight:
                                              FontWeight
                                                  .bold,
                                          color:
                                              textColor,
                                        ),
                                      ),
                                      const SizedBox(
                                          height: 25),

                                      _buildResultField(
                                        context,
                                        label:
                                            "Disease",
                                        value:
                                            predictedDisease,
                                      ),
                                      _buildResultField(
                                        context,
                                        label:
                                            "Risk Level",
                                        value:
                                            predictedRisk,
                                      ),

                                      const SizedBox(
                                          height: 30),

                                      Center(
                                        child:
                                            ElevatedButton(
                                          onPressed: showResults &&
                                                  !isPdfGenerating
                                              ? () =>
                                                  _generatePdf(
                                                      context)
                                              : null,
                                          child: isPdfGenerating
                                              ? const CircularProgressIndicator()
                                              : const Text(
                                                  "Print",
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
