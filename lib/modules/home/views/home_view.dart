import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;

import 'package:get/get.dart';
import 'package:moapp_project/modules/face_detector_gallery/views/face_detector_gallery_view.dart';

import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({Key? key}) : super(key: key);

  Future<Uint8List?> _getImageData(ui.Image? image) async {
    if (image != null) {
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HomeView'),
        centerTitle: true,
      ),
      body: GetBuilder<HomeController>(builder: (context) {
        return Stack(
          children: [
            SizedBox(
              width: Get.width,
              height: Get.height,
              child: controller.isInitializedCamera.value &&
                      controller.cameraController != null
                  ? CameraPreview(controller.cameraController!)
                  : Container(),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      await controller.initializeCamera();
                    },
                    child: const Text("Capture Face"),
                  ),
                  Obx(() {
                    if (controller.isLoading.value) {
                      return CircularProgressIndicator();
                    } else if (controller.iimage != null) {
                      return FutureBuilder<Uint8List?>(
                        future: _getImageData(controller.iimage),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.done) {
                            if (snapshot.hasData) {
                              return Image.memory(snapshot.data!);
                            } else {
                              return Text('No image selected.');
                            }
                          } else {
                            return CircularProgressIndicator();
                          }
                        },
                      );
                    } else {
                      return Text('No image selected.');
                    }
                  }),
                  ElevatedButton(
                    onPressed: () {
                      Get.to(() => FaceDetectorGalleryView());
                    },
                    child: const Text("Detect with Gallery"),
                  ),
                ],
              ),
            )
          ],
        );
      }),
    );
  }
}
