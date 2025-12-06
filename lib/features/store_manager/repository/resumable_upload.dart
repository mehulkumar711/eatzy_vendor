import 'dart:io';
import 'package:tus_client/tus_client.dart';
import 'package:cross_file/cross_file.dart';

class ResumableUploader {
  final String endpoint; // e.g., "http://yourserver:1080/files/"
  ResumableUploader(this.endpoint);

  /// Upload a file with resumable protocol, returns final file URL or metadata.
  Future<String> uploadFile(File file, {Function(double)? onProgress}) async {
    // Create a client
    final client = TusClient(
      Uri.parse(endpoint),
      XFile(file.path),
    );

    // Start upload
    await client.upload(
      onProgress: (progress) {
        if (onProgress != null) {
          onProgress(progress);
        }
      },
    );

    // Return URL (usually endpoint + file fingerprint or handled by server)
    // tus_client's `uploadUrl` getter might give the location
    return client.uploadUrl.toString();
  }
}
