import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import '../../widgets/app_background.dart';
import '../../widgets/custom_app_bar.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  File? selectedFile;
  bool isUploading = false;
  String? resultPath;
  String errorMessage = '';

  // ---------------------------
  // Pick file from desktop
  // ---------------------------
  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['vcf', 'vcf.gz', 'csv', 'txt'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        selectedFile = File(result.files.single.path!);
      });
    }
  }

  // ---------------------------
  // Upload file to backend & receive CSV
  // ---------------------------
  Future<void> uploadFile() async {
    if (selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a file first.")),
      );
      return;
    }

    setState(() {
      isUploading = true;
      errorMessage = ''; // Clear previous error messages
    });

    try {
      final uri = Uri.parse(
        'https://updatedmodel1.onrender.com/convert-vcf', // Your API URL
      );

      final request = http.MultipartRequest('POST', uri)
        ..files.add(
          await http.MultipartFile.fromPath('file', selectedFile!.path),
        );

      final streamedResponse = await request.send();
      final res = await http.Response.fromStream(streamedResponse);

      // Log the server response for debugging
      print("Response status: ${res.statusCode}");
      print("Response body: ${res.body}");

      if (res.statusCode == 200) {
        final bytes = res.bodyBytes;

        final dir = await getApplicationDocumentsDirectory();
        final filePath = '${dir.path}/result.csv';

        final file = File(filePath);
        await file.writeAsBytes(bytes);

        setState(() => resultPath = filePath);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ File processed successfully! CSV saved locally.'),
          ),
        );
      } else {
        // Handle API error
        setState(() {
          errorMessage = res.body.isNotEmpty ? res.body : 'Unknown error occurred';
        });
      }
    } catch (e) {
      print("Error during file upload: $e");

      setState(() {
        errorMessage = '⚠️ Error: $e';
      });
    } finally {
      setState(() => isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: Column(
          children: [
            const SizedBox(height: 10),
            const CustomAppBar(activePage: "Upload File"),
            IconButton(
              icon: Icon(Icons.arrow_back,
                  size: 28, color: isDark ? Colors.white : Colors.black87),
              onPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 🔹 Title
                    Text(
                      "Upload your files",
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1E2046),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // 🔹 Description
                    Text(
                      "Accepted formats: .VCF or .VCF.GZ",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // 🔹 Upload box
                    GestureDetector(
                      onTap: pickFile,
                      child: Container(
                        width: double.infinity,
                        height: 140,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? Colors.white30 : Colors.black26,
                          ),
                          color: isDark
                              ? Colors.white10
                              : Colors.white.withOpacity(0.7),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.upload_rounded,
                                size: 60,
                                color: isDark
                                    ? Colors.purpleAccent[200]
                                    : const Color(0xFF1E2046),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                "Tap to select your file",
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),

                    // 🔹 Selected file name
                    if (selectedFile != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            if (!isDark)
                              const BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                selectedFile!.path.split(Platform.pathSeparator).last,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              onPressed: () =>
                                  setState(() => selectedFile = null),
                              icon: const Icon(
                                Icons.close,
                                color: Colors.redAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 30),

                    // 🔹 Upload button
                    ElevatedButton.icon(
                      onPressed: isUploading ? null : uploadFile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark
                            ? Colors.purpleAccent[200]
                            : const Color(0xFF1E2046),
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 14,
                        ),
                        shadowColor:
                            isDark ? Colors.purpleAccent[100] : Colors.black26,
                        elevation: 5,
                      ),
                      icon: isUploading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.cloud_upload_outlined),
                      label: Text(
                        isUploading ? "Uploading..." : "Upload & Process",
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 🔹 Result view
                    if (resultPath != null)
                      Column(
                        children: [
                          Text(
                            "✅ File processed successfully!",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.greenAccent
                                  : Colors.green,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Saved at:\n$resultPath",
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? Colors.white70
                                  : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () async =>
                                    await OpenFilex.open(resultPath!),
                                icon: const Icon(Icons.open_in_new_rounded),
                                label: const Text("Open"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                  foregroundColor: Colors.white,
                                  shape: const StadiumBorder(),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  await Share.shareXFiles(
                                    [XFile(resultPath!)],
                                    text:
                                        'Here is my processed CSV file 📄',
                                  );
                                },
                                icon:
                                    const Icon(Icons.download_rounded),
                                label:
                                    const Text("Share / Download"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDark
                                      ? Colors.deepPurple[300]
                                      : Colors.deepPurple,
                                  foregroundColor: Colors.white,
                                  shape: const StadiumBorder(),
                                  padding:
                                      const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    // Error message for file validation
                    if (errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Text(
                          errorMessage,
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
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
    );
  }
}
