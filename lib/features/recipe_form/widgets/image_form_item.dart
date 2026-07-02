import 'package:image_picker/image_picker.dart';

/// Local editing state for one image in the form: either an existing,
/// already-persisted image (identified by its DB-relative `file_path`), or
/// a freshly picked file that only gets copied into app storage on save.
class ImageFormItem {
  const ImageFormItem.existing({required this.id, required String relativePath})
      : existingRelativePath = relativePath,
        pickedFile = null;

  const ImageFormItem.picked({required this.id, required XFile file})
      : existingRelativePath = null,
        pickedFile = file;

  final String id;
  final String? existingRelativePath;
  final XFile? pickedFile;
}
