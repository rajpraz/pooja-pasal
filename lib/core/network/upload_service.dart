import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pooja_pasal/core/network/api_client.dart';

/// Upload folders the API accepts (`POST /uploads`). Product images are for
/// sellers/admins, category and banner images for admins, the rest for
/// any signed-in user.
abstract final class UploadFolders {
  static const String productImages = 'product_images';
  static const String categoryImages = 'category_images';
  static const String profileImages = 'profile_images';
  static const String reviewImages = 'review_images';
}

/// Image uploads to the Laravel API's storage — used by the seller product
/// form, category editor, profile photo and review photos.
class UploadService {
  UploadService(this._api);

  final ApiClient _api;

  /// Uploads [file] into [folder] and returns its public URL.
  Future<String> uploadImage(File file, {required String folder}) async {
    final payload =
        await _api.upload('/uploads', file: file, fields: {'folder': folder});
    return (payload as Map<String, dynamic>)['url'] as String;
  }

  Future<List<String>> uploadImages(List<File> files,
      {required String folder}) async {
    final urls = <String>[];
    for (final file in files) {
      urls.add(await uploadImage(file, folder: folder));
    }
    return urls;
  }
}

final uploadServiceProvider = Provider<UploadService>(
    (ref) => UploadService(ref.watch(apiClientProvider)));
