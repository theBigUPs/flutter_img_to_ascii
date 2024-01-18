import 'package:flutter/material.dart';
import 'package:flutter_img_to_ascii/src/view_models/home_viewmodel.dart';
import 'package:provider/provider.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey,
      body: SafeArea(
          child: Column(children: [
        ElevatedButton(
            onPressed: () async {
              HomeViewModel viewModel = Provider.of(
                context,
                listen: false,
              );
              viewModel.getPixelInfo();
            },
            child: const Icon(Icons.add)),
        const SizedBox(
          width: 100,
          height: 100,
          //child: Image(image: imageInfo),
        )
      ])),
    );
  }
}
