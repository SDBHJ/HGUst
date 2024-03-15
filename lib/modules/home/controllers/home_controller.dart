import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:logger/logger.dart';

class HomeController extends GetxController {
  RxBool isInitializedCamera = false.obs;
  FaceDetector? _faceDetector;
  late CameraController cameraController;
  List<Face>? facess; // 얼굴 감지 정보를 저장할 변수
  ui.Image? iimage; // 이미지를 저장할 변수
  RxBool isLoading = false.obs; // 로딩 상태를 나타낼 변수

  //TODO: Implement HomeController
  var logger = Logger(
    printer: PrettyPrinter(
        methodCount: 2, // number of method calls to be displayed
        errorMethodCount: 8, // number of method calls if stacktrace is provided
        lineLength: 120, // width of the output
        colors: true, // Colorful log messages
        printEmojis: true, // Print an emoji for each log message
        printTime: false // Should each log print contain a timestamp
        ),
  );
  final count = 0.obs;
  @override
  Future<void> onInit() async {
    super.onInit();
    var cameras = await availableCameras();
    cameraController = CameraController(cameras[0], ResolutionPreset.high);
    await cameraController.initialize();
    isInitializedCamera.value = true;
    _faceDetector = GoogleMlKit.vision.faceDetector(
        FaceDetectorOptions(performanceMode: FaceDetectorMode.accurate));
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    super.onClose();
  }

  Future getAvailableCamera() async {
    final cameras = await availableCameras();
    return cameras;
  }

  Future<void> initializeCamera() async {
    await cameraController.initialize();
    isInitializedCamera.value = true;
    cameraController.setFlashMode(FlashMode.always);

    // 사진 찍기
    XFile? imageFile = await this.cameraController.takePicture();

    // 사진에서 얼굴 감지
    final image = InputImage.fromFilePath(imageFile!.path);
    final faceDetector = GoogleMlKit.vision.faceDetector(FaceDetectorOptions(
        performanceMode: FaceDetectorMode.fast, enableLandmarks: true));
    List<Face> faces = await faceDetector.processImage(image);

    // 감지된 얼굴 리스트와 이미지를 상태로 저장
    this.facess = faces;
    await _loadImage(imageFile);

    // 얼굴이 감지되었는지 확인
    if (faces.isNotEmpty) {
      // 얼굴이 감지되었다는 메시지를 표시
      Get.showSnackbar(
        GetBar(
          message: "얼굴이 감지되었습니다.",
          duration: Duration(seconds: 2),
        ),
      );
    }

    // 상태 업데이트
    update();
  }

  Future<void> _loadImage(XFile file) async {
    final data = await file.readAsBytes();
    await decodeImageFromList(data).then((value) => this.iimage = value);
    isLoading.value = false;
  }
}
