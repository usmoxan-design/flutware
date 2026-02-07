import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import '../models/app_models.dart';

class ApkBuilder {
  static const String _templatePath = 'assets/template.apk';
  static const String _projectJsonPath =
      'assets/flutter_assets/assets/project.json';

  static final List<String> logs = [];

  static void _log(String message) {
    logs.add(
      '[${DateTime.now().toString().split(' ').last.split('.').first}] $message',
    );
    debugPrint(message);
  }

  static Future<String?> buildApk(
    ProjectData project, {
    Function(String)? onProgress,
  }) async {
    logs.clear();
    _log('Build jarayoni boshlandi: ${project.appName}');
    try {
      if (onProgress != null) onProgress('Tayyorlanmoqda...');

      _log('Assetlardan template yuklanmoqda...');
      final ByteData data = await rootBundle.load(_templatePath);
      final List<int> bytes = data.buffer.asUint8List();
      _log('APK fayli dekodlanmoqda...');
      final Archive archive = ZipDecoder().decodeBytes(bytes);

      if (onProgress != null) onProgress('Build qilinmoqda...');
      _log('Project JSON generatsiya qilinmoqda...');
      final String jsonContent = jsonEncode(project.toJson());
      final List<int> jsonBytes = utf8.encode(jsonContent);
      final ArchiveFile projectFile = ArchiveFile(
        _projectJsonPath,
        jsonBytes.length,
        jsonBytes,
      );

      _log('Arxiv yangilanmoqda...');
      final newArchive = Archive();
      for (var file in archive.files) {
        if (file.name != _projectJsonPath &&
            !file.name.startsWith('META-INF/')) {
          newArchive.addFile(file);
        }
      }
      newArchive.addFile(projectFile);

      _log('Yangi APK arxivlanmoqda...');
      final List<int>? buildBytes = ZipEncoder().encode(newArchive, level: 0);
      if (buildBytes == null) throw Exception('ZIP enkoding xatosi');

      // Saqlash joyini aniqlash (Download papkasi)
      Directory targetDir;
      try {
        targetDir = Directory('/storage/emulated/0/Download');
        if (!targetDir.existsSync()) {
          final ext = await getExternalStorageDirectory();
          targetDir = ext ?? (await getTemporaryDirectory());
        }
        // Yozish huquqini tekshirish
        final testFile = File('${targetDir.path}/.permission_test');
        await testFile.writeAsString('test');
        await testFile.delete();
        _log('Saqlash manzili: ${targetDir.path}');
      } catch (e) {
        _log('Download papkasiga yozib bo\'lmadi, muqobil joy qidirilmoqda...');
        final ext = await getExternalStorageDirectory();
        targetDir = ext ?? (await getTemporaryDirectory());
        _log('Muqobil manzil: ${targetDir.path}');
      }

      // Vaqtinchalik unsigned fayl (cache'da qoladi)
      final tempDir = await getTemporaryDirectory();
      final String outPathUnsigned =
          '${tempDir.path}/${project.appName}_unsigned.apk';

      // Final signed fayl (Download papkasida)
      final String outPathSigned = '${targetDir.path}/${project.appName}.apk';

      _log('Vaqtinchalik fayl yozilmoqda: $outPathUnsigned');
      final File outFile = File(outPathUnsigned);
      await outFile.writeAsBytes(buildBytes);

      if (onProgress != null) onProgress('Imzolanmoqda...');
      _log('Native Signer ishga tushirildi...');

      // Agar avvalgi fayl bo'lsa o'chirish
      final signedFile = File(outPathSigned);
      if (await signedFile.exists()) {
        try {
          await signedFile.delete();
        } catch (e) {
          _log('Eski faylni o\'chirishda xatolik: $e');
        }
      }

      final String? signedPath = await signApk(outPathUnsigned, outPathSigned);

      if (signedPath != null) {
        if (onProgress != null) onProgress('Imzolandi tayyor!');
        _log('Build muvaffaqiyatli yakunlandi: $signedPath');

        // Unsigned faylni tozalash
        try {
          if (await outFile.exists()) await outFile.delete();
        } catch (_) {}
      } else {
        _log('Imzolashda xatolik, unsigned APK ishlatiladi.');
        // Agar imzolash o'xshamasa, unsignedni targetga ko'chirish
        try {
          await outFile.copy(outPathSigned);
          return outPathSigned;
        } catch (e) {
          return outPathUnsigned;
        }
      }

      return signedPath ?? outPathUnsigned;
    } catch (e) {
      _log('XATOLIK: $e');
      return null;
    }
  }

  static Future<String?> signApk(String inputPath, String outputPath) async {
    const platform = MethodChannel('com.flutware.builder/installer');
    try {
      final String? result = await platform.invokeMethod('signApk', {
        'inputPath': inputPath,
        'outputPath': outputPath,
      });
      return result;
    } on PlatformException catch (e) {
      _log('Sign Bridge Error: ${e.message}');
      return null;
    }
  }

  static Future<void> installApk(String path) async {
    const platform = MethodChannel('com.flutware.builder/installer');
    try {
      await platform.invokeMethod('installApk', {'path': path});
    } on PlatformException catch (e) {
      debugPrint('Install Error: ${e.message}');
    }
  }
}
