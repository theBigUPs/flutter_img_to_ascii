import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';

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

      //useIsolate(decodedImage);
      //brightnessArray[0][0]=12;
      //print("width:${decodedImage.width} height:${decodedImage.height}");
      //print('Pixel at ($x, $y): color blue: ${pixelColor.b},');
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

      print('Result: ${brightnessArray[0][0]}');

      Isolate.spawn(constructAsciiArray,
          [receivePort2.sendPort, brightnessArray, asciiBrightnessCharacters]);
      asciiImage = await receivePort2.first;
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

    // Create a dynamic 2D list to store brightness values
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

  static void constructAsciiArray(
    List<dynamic> args,
  ) {
    //args[0] is sendport args[1] is brightnessarray args[2] is the asciistring
    int width = args[1].length;
    int height = args[1].isNotEmpty ? args[1][0].length : 0;
    SendPort resultPort = args[0];
    List<List<String>> asciiPixelArray =
        List.generate(height, (i) => List<String>.filled(width, ""));
    for (var i = 0; i < 2; i++) {
      //height
      for (var j = 0; j < 2; j++) {
        //width
        int charNum = args[1][i][j] ~/ (255 / 67); //integer division
        asciiPixelArray[i][j] = args[2][charNum];
        print(asciiPixelArray[i][j]);
      }
    }
    resultPort.send(asciiPixelArray);
  }
}
