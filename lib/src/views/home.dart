import 'package:flutter/material.dart';
import 'package:flutter_img_to_ascii/src/view_models/home_viewmodel.dart';
import 'package:provider/provider.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  HomeState createState() => HomeState();
}

class HomeState extends State<Home> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Initialize your view model in the initState method
      HomeViewModel viewModel =
          Provider.of<HomeViewModel>(context, listen: false);
      viewModel.requestStoragePermission();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Column(
            children: [
              const SizedBox(
                height: 24,
              ),
              ElevatedButton(
                onPressed: () async {
                  //viewModel.showProgressIndicator = true;
                  HomeViewModel viewModel =
                      Provider.of<HomeViewModel>(context, listen: false);
                  viewModel.getImage();
                },
                style: ButtonStyle(
                  minimumSize: MaterialStateProperty.all(
                    const Size(80, 80),
                  ),
                ),
                child: const Icon(Icons.add),
              ),
              const SizedBox(
                height: 12,
              ),
              Consumer<HomeViewModel>(
                builder: (context, viewmodel, child) {
                  return SizedBox(
                    width: 200,
                    height: 200,
                    child: viewmodel.showProgressIndicator
                        ? const CircularProgressIndicator()
                        : viewmodel.displayedImage != null
                            ? Image.memory(viewmodel.displayedImage!)
                            : Container(),
                  );
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
