import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
//import 'dart:ui' as ui;
import 'package:image/image.dart' as img;

class HomeViewModel with ChangeNotifier {
  img.Image? pickedImage;
  void getPixelInfo() async {
    final ImagePicker picker = ImagePicker();
    // Pick an image.
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      img.Image decodedImage = img.decodeImage(await image.readAsBytes())!;
      pickedImage = decodedImage;

      int x = 10;
      int y = 20;

      img.Pixel pixelColor = decodedImage.getPixel(x, y);

      print("width:${decodedImage.width} height:${decodedImage.height}");
      print('Pixel at ($x, $y): color blue: ${pixelColor.b},');
    } else {
      print('No image picked.');
    }
  }
}
