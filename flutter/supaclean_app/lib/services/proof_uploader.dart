import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'api_client.dart';

/// Stores a proof-of-payment image and returns the reference ASP.NET keeps
/// on the payment (the admin looks the file up from it).
abstract class ProofUploader {
  Future<String> upload(XFile file);
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
  Future<String> upload(XFile file) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const ApiException('Please sign in again.');
    }

    final name = file.name.toLowerCase();
    final extension = name.contains('.') ? name.split('.').last : 'jpg';
    final contentType = extension == 'png' ? 'image/png' : 'image/jpeg';
    final path = '$userId/${DateTime.now().millisecondsSinceEpoch}.$extension';

    try {
      await _client.storage.from(bucket).uploadBinary(
            path,
            await file.readAsBytes(),
            fileOptions: FileOptions(contentType: contentType),
          );
    } on StorageException catch (error) {
      throw ApiException(
        'Could not upload your proof of payment (${error.message}). '
        'Please try again.',
      );
    }

    return '$bucket/$path';
  }
}
