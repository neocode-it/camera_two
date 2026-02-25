import 'package:outtake/classes/gallery_image_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';

class FileRepository {
  Future<Directory?> _getNewMediaDirectory() async {
    final directory = await getExternalStorageDirectory();
    if (directory == null) return null;

    String path = directory.path;
    // Replace Android/data with Android/media
    if (path.contains("Android/data")) {
      path = path.replaceFirst("Android/data", "Android/media");
    }
    // Remove /files suffix if present
    if (path.endsWith("/files")) {
      path = path.substring(0, path.length - 6);
    }

    final dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<Directory?> _getOldMediaDirectory() async {
    final directory = await getExternalStorageDirectory();
    if (directory == null) return null;
    return Directory('${directory.path}/media');
  }

  Future<String> copyImage(filepath) async {
    final mediaDir = await _getNewMediaDirectory();
    if (mediaDir == null) {
      throw const FileSystemException("Storage location not found");
    }

    String filename = _generateFilename();
    File newFile = File('${mediaDir.path}/$filename.jpg');

    // Ensure unique filename
    while (await newFile.exists()) {
      filename = _generateFilename();
      newFile = File('${mediaDir.path}/$filename.jpg');
    }

    await File(filepath).copy(newFile.path);
    return newFile.path;
  }

  String _generateFilename() {
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyyMMdd_HHmmssSSS').format(now);
    return formattedDate;
  }

  String formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final inputDate = DateTime(date.year, date.month, date.day);
    final difference = today.difference(inputDate).inDays;

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

  DateTime _getDateFromFile(FileSystemEntity file) {
    if (file is! File) return DateTime.now();
    String filename = file.uri.pathSegments.last;
    // Assuming format yyyyMMdd_HHmmss... or yyyyMMdd_HHmmss.jpg
    try {
      if (filename.length >= 15) {
        String datePart = filename.substring(0, 15);
        return DateFormat('yyyyMMdd_HHmmss').parse(datePart);
      }
    } catch (e) {
      // Fallback to modification time if parsing fails
    }
    return file.lastModifiedSync();
  }

  Future<Map<String, List<GalleryImageFile>>> getGallery() async {
    Map<String, List<GalleryImageFile>> imagesGroupedByDate = {};
    List<FileSystemEntity> files = [];

    final oldDir = await _getOldMediaDirectory();
    if (oldDir != null && await oldDir.exists()) {
      try {
        files.addAll(oldDir.listSync(recursive: true));
      } catch (e) {
        // Ignore errors reading old dir
      }
    }

    final newDir = await _getNewMediaDirectory();
    if (newDir != null && await newDir.exists()) {
      try {
        files.addAll(newDir.listSync(recursive: true));
      } catch (e) {
        // Ignore errors reading new dir
      }
    }

    // Sort by date from filename, newest first
    files.sort((a, b) {
      return _getDateFromFile(b).compareTo(_getDateFromFile(a));
    });

    int index = 0;
    for (var file in files) {
      if (file is File) {
        try {
          DateTime dateFromFile = _getDateFromFile(file);
          // Normalize to date (strip time)
          DateTime dateOnly = DateTime(dateFromFile.year, dateFromFile.month, dateFromFile.day);
          String date = formatDate(dateOnly);

          if (imagesGroupedByDate.containsKey(date)) {
            imagesGroupedByDate[date]!.add(GalleryImageFile(index, file));
            index++;
          } else {
            imagesGroupedByDate[date] = [GalleryImageFile(index, file)];
            index++;
          }
        } catch (e) {
          // Skip problematic files
          continue;
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
    List<FileSystemEntity> files = [];

    final oldDir = await _getOldMediaDirectory();
    if (oldDir != null && await oldDir.exists()) {
       try { files.addAll(oldDir.listSync(recursive: true)); } catch (_) {}
    }

    final newDir = await _getNewMediaDirectory();
    if (newDir != null && await newDir.exists()) {
       try { files.addAll(newDir.listSync(recursive: true)); } catch (_) {}
    }

    if (files.isEmpty) return null;

    // Sort by modification time/date, newest first
    files.sort((a, b) => _getDateFromFile(b).compareTo(_getDateFromFile(a)));

    for (var file in files) {
      if (file is File) {
        return file;
      }
    }
    return null;
  }

  Future<int> deleteImagesOlderThan(Duration duration) async {
    int count = 0;
    List<FileSystemEntity> files = [];
    
    final oldDir = await _getOldMediaDirectory();
    if (oldDir != null && await oldDir.exists()) {
       try { files.addAll(oldDir.listSync(recursive: true)); } catch (_) {}
    }

    final newDir = await _getNewMediaDirectory();
    if (newDir != null && await newDir.exists()) {
       try { files.addAll(newDir.listSync(recursive: true)); } catch (_) {}
    }

    final cutoff = DateTime.now().subtract(duration);

    for (var file in files) {
      if (file is File) {
        // Use lastModifiedSync for deletion check, as that's the actual file property
        // But maybe we should use the parsed date? 
        // Typically "older than" refers to capture time.
        // Let's use _getDateFromFile to be consistent.
        if (_getDateFromFile(file).isBefore(cutoff)) {
          await file.delete();
          count++;
        }
      }
    }
    return count;
  }
}
