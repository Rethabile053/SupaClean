import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'api_client.dart';

/// A proof-of-payment file (photo, screenshot or PDF) chosen by the customer.
class ProofFile {
  const ProofFile({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
}

/// Stores a proof-of-payment file and returns the reference ASP.NET keeps
/// on the payment (the admin looks the file up from it).
abstract class ProofUploader {
  Future<String> upload(ProofFile file);
}

/// Uploads to the private Supabase Storage bucket [bucket], inside a folder
/// named after the signed-in user.
///
/// One-off setup in the Supabase dashboard: create a PRIVATE bucket called
/// `payment-proofs` and add a policy that lets signed-in users upload.
class SupabaseProofUploader implements ProofUploader {
  SupabaseProofUploader({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  static const String bucket = 'payment-proofs';

  final SupabaseClient _client;

  @override
  Future<String> upload(ProofFile file) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const ApiException('Please sign in again.');
    }

    final name = file.name.toLowerCase();
    final extension = name.contains('.') ? name.split('.').last : 'jpg';
    final contentType = switch (extension) {
      'pdf' => 'application/pdf',
      'png' => 'image/png',
      _ => 'image/jpeg',
    };
    final path = '$userId/${DateTime.now().millisecondsSinceEpoch}.$extension';

    try {
      await _client.storage.from(bucket).uploadBinary(
            path,
            file.bytes,
            fileOptions: FileOptions(contentType: contentType),
          );
    } on StorageException catch (error) {
      throw ApiException(
        'Could not upload your proof of payment (${error.message}). '
        'Please try again.',
      );
    }

    // The path inside the bucket. The admin side adds the bucket name when it
    // makes the link to view the file, so it must not be included here.
    return path;
  }
}
