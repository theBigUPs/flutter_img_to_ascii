import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class HomeViewModel with ChangeNotifier {
  Uint8List? displayedImage;
  List<List<int>> brightnessArray = [];
  List<List<String>> asciiImage = [];
  String asciiBrightnessCharacters =
      r'`^\",:;Il!i~+_-?][}{1)(|\\/tfjrxnuvczXYUJCLQ0OZmwqpdbkhao*#MW&8%B@$'; //67
  bool _showProgressIndicator = false;

  set showProgressIndicator(bool value) {
    _showProgressIndicator = value;
    notifyListeners();
  }

  String _status = "";
  String get status => _status;
  set status(String val) {
    _status = val;
    notifyListeners();
  }

  bool get showProgressIndicator => _showProgressIndicator;

  void getImage() async {
    final ImagePicker picker = ImagePicker();
    // Pick an image.
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      img.Image decodedImage = img.decodeImage(await image.readAsBytes())!;
      img.Image resizedImage = img.copyResize(decodedImage, height: 200);
      displayedImage = Uint8List.fromList(img.encodePng(resizedImage));
      //_showProgressIndicator = false;
      notifyListeners();
      useIsolate(resizedImage);
    } else {
      print('No image picked.');
    }
  }

  void useIsolate(img.Image val) async {
    final ReceivePort receivePort1 = ReceivePort();
    final ReceivePort receivePort2 = ReceivePort();
    try {
      Isolate.spawn(constructBrightnessArray,
          [receivePort1.sendPort, val, brightnessArray]);
      brightnessArray = await receivePort1.first;
      status = "constructing brightness array";
      //print('Result: ${brightnessArray[0][0]}');

      Isolate.spawn(constructAsciiArray,
          [receivePort2.sendPort, brightnessArray, asciiBrightnessCharacters]);
      asciiImage = await receivePort2.first;
      status = "constructing ascii array";

      writeToDownloads("text.txt", asciiImage);
      status = "ascii array written to download/text.txt file";
    } on IsolateSpawnException catch (e) {
      debugPrint('Isolate Failed: $e');
      receivePort1.close();
      receivePort2.close();
    }
  }

  static void constructBrightnessArray(List<dynamic> args) {
    SendPort resultPort = args[0];
    int width = args[1].width;
    int height = args[1].height;
    print("width :$width height :$height");
    args[2] = List.generate(height, (i) => List<int>.filled(width, 0));
    for (var i = 0; i < height; i++) {
      //height
      for (var j = 0; j < width; j++) {
        //width
        img.Pixel pixelColor = args[1].getPixel(j, i);
        double brightness = (pixelColor.b + pixelColor.g + pixelColor.r) / 3;
        args[2][i][j] = brightness.toInt();
        //print(args[2][i][j]);
      }
    }
    resultPort.send(args[2]);
  }

  static void constructAsciiArray(
    List<dynamic> args,
  ) {
    //args[0] is sendport args[1] is brightnessarray args[2] is the asciistring
    int width = args[1].isNotEmpty ? args[1][0].length : 0;
    int height = args[1].length;
    print("width :$width height :$height");
    SendPort resultPort = args[0];
    List<List<String>> asciiPixelArray =
        List.generate(height, (i) => List<String>.filled(width, ""));
    for (var i = 0; i < height; i++) {
      //height
      for (var j = 0; j < width; j++) {
        //width
        int charNum = args[1][i][j] ~/ (255 / 67); //integer division
        asciiPixelArray[i][j] = args[2][charNum];
        //print(asciiPixelArray[i][j]);
      }
    }
    resultPort.send(asciiPixelArray);
  }

  Future<String?> getDownloadPath() async {
    Directory? directory;
    try {
      if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else {
        directory = Directory('/storage/emulated/0/Download');
        // Put file in global download folder, if for an unknown reason it didn't exist, we fallback
        // ignore: avoid_slow_async_io
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      }
    } catch (err) {
      print("Cannot get download folder path");
    }
    return directory?.path;
  }

  Future<void> writeToDownloads(
      String fileName, List<List<String>> matrix) async {
    String? downloadsPath = await getDownloadPath();

    String filePath = '$downloadsPath/$fileName';

    try {
      // Write to the file
      File file = File(filePath);
      for (List<String> row in matrix) {
        await file.writeAsString('${row.join(' ')}\n', mode: FileMode.append);
      }

      print('File written to: $filePath');
    } catch (e) {
      print('Error writing to file: $e');
    }
  }

  Future<void> requestStoragePermission() async {
    while (true) {
      var status = await Permission.storage.status;

      if (status.isGranted) {
        // Permission is already granted
        return;
      } else if (status.isDenied || status.isPermanentlyDenied) {
        var result = await Permission.storage.request();

        if (result.isGranted) {
          // Permission granted
          print('Storage permission granted');
          return;
        } else {
          // Permission denied
          print('Storage permission denied');
          // You can provide some feedback to the user here if needed
        }
      }
    }
  }
}
