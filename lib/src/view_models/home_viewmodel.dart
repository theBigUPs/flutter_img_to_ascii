import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

class HomeViewModel with ChangeNotifier {
  Uint8List? displayedImage;
  List<List<int>> brightnessArray = [];
  String asciiBrightnessCharacters =
      r'`^\",:;Il!i~+_-?][}{1)(|\\/tfjrxnuvczXYUJCLQ0OZmwqpdbkhao*#MW&8%B@$';
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
      //int x = 10;
      //int y = 20;
      useIsolate(decodedImage);
      //brightnessArray[0][0]=12;
      //print("width:${decodedImage.width} height:${decodedImage.height}");
      //print('Pixel at ($x, $y): color blue: ${pixelColor.b},');
    } else {
      print('No image picked.');
    }
  }

  useIsolate(img.Image val) async {
    final ReceivePort receivePort = ReceivePort();
    try {
      await Isolate.spawn(constructBrightnessArray,
          [receivePort.sendPort, val, brightnessArray]);
      brightnessArray = await receivePort.first;

      print('Result: ${brightnessArray[0][0]}');
      receivePort.close();
    } on IsolateSpawnException catch (e) {
      debugPrint('Isolate Failed: $e');
      receivePort.close();
    }
  }

  static void constructBrightnessArray(List<dynamic> args) {
    SendPort resultPort = args[0];
    int width = args[1].width;
    int height = args[1].height;

    // Create a dynamic 2D list to store brightness values
    args[2] = List.generate(height, (i) => List<int>.filled(width, 0));
    for (var i = 0; i < 2; i++) {
      for (var j = 0; j < 2; j++) {
        img.Pixel pixelColor = args[1].getPixel(j, i);
        double brightness = (pixelColor.b + pixelColor.g + pixelColor.r) / 3;
        args[2][i][j] = brightness.toInt();
        print(args[2][i][j]);
      }
    }
    resultPort.send(args[2]);
  }
}
