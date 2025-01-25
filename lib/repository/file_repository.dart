import 'package:gallery_two/classes/gallery_image_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';

class FileRepository {
  Future<String> copyImage(filepath) async {
    final path = await _getExternalPath();
    final newFile = File('$path/${_generateFilename()}');
    await File(filepath).copy(newFile.path);
    return newFile.path;
  }

  Future<String> _getExternalPath() async {
    final directory = await getExternalStorageDirectory();

    if (directory == null) {
      throw const FileSystemException("Storage location not found");
    }
    final path = "${directory.path}/media";
    final customDir = Directory(path);
    if (!(await customDir.exists())) {
      await customDir.create(recursive: true);
    }
    return customDir.path;
  }

  String _generateFilename() {
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyyMMdd_HHmmss').format(now);
    return formattedDate;
  }

  String formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return "Heute";
    } else if (difference == 1) {
      return "Gestern";
    } else if (difference < 7) {
      return DateFormat('EEEE', 'de_DE').format(date);
    } else {
      return DateFormat('yyyy-MM-dd').format(date);
    }
  }

  Future<Map<String, List<GalleryImageFile>>> getGallery() async {
    Map<String, List<GalleryImageFile>> imagesGroupedByDate = {};

    final directory = await getExternalStorageDirectory();
    final mediaDir = Directory('${directory!.path}/media');
    final List<FileSystemEntity> files = mediaDir.listSync(recursive: true);

    int index = 0;
    for (var file in files) {
      if (file is File) {
        String date = file.lastModifiedSync().toString().split(" ")[0];
        date = formatDate(DateTime.parse(date));
        if (imagesGroupedByDate.containsKey(date)) {
          imagesGroupedByDate[date]!.add(GalleryImageFile(index, file));
          index++;
        } else {
          imagesGroupedByDate[date] = [GalleryImageFile(index, file)];
          index++;
        }
      }
    }
    return imagesGroupedByDate;
  }

  Future<void> deleteImage(String path) async {
    File file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
