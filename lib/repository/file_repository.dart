import 'package:outtake/classes/gallery_image_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';

class FileRepository {
  static int _counter = 0;

  Future<String> copyImage(filepath) async {
    final path = await _getExternalPath();
    String filename = _generateFilename();
    File newFile = File('$path/$filename');
    
    // Ensure unique filename
    while (await newFile.exists()) {
      filename = _generateFilename();
      newFile = File('$path/$filename');
    }
    
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
    String formattedDate = DateFormat('yyyyMMdd_HHmmssSSS').format(now);
    _counter = (_counter + 1) % 1000;
    return '${formattedDate}_$_counter';
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
    if (directory == null) {
      return imagesGroupedByDate;
    }
    final mediaDir = Directory('${directory.path}/media');
    if (!mediaDir.existsSync()) {
      return imagesGroupedByDate;
    }
    final List<FileSystemEntity> files = mediaDir.listSync(recursive: true);

    // Sort by modification time, newest first
    files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));

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

  Future<File?> getLastImage() async {
    final directory = await getExternalStorageDirectory();
    if (directory == null) {
      return null;
    }
    final mediaDir = Directory('${directory.path}/media');
    if (!mediaDir.existsSync()) {
      return null;
    }
    final List<FileSystemEntity> files = mediaDir.listSync(recursive: true);
    if (files.isEmpty) return null;

    // Sort by modification time, newest first
    files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));

    for (var file in files) {
      if (file is File) {
        return file;
      }
    }
    return null;
  }

  Future<int> deleteImagesOlderThan(Duration duration) async {
    int count = 0;
    final directory = await getExternalStorageDirectory();
    if (directory == null) return 0;

    final mediaDir = Directory('${directory.path}/media');
    if (!mediaDir.existsSync()) return 0;

    final cutoff = DateTime.now().subtract(duration);
    final List<FileSystemEntity> files = mediaDir.listSync(recursive: true);

    for (var file in files) {
      if (file is File) {
        if (file.lastModifiedSync().isBefore(cutoff)) {
          await file.delete();
          count++;
        }
      }
    }
    return count;
  }
}
