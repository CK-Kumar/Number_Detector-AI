import 'package:flutter/widgets.dart';

import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:ui' as ui;
import 'dart:io' as io;
import 'package:image/image.dart' as img;

class Classifier {
  Classifier(); // Empty init/constructor

  classifyImage(PickedFile image) async {
    // Takes PickedFile image as input and returns an integer
    // of which integer it was (hopefully)!

    // Ugly boilerplate to get it to Uint8List
    var _file = io.File(image.path);
    img.Image? imageTemp = img.decodeImage(_file.readAsBytesSync());
    img.Image resizedImg = img.copyResize(imageTemp!, height: 28, width: 28);
    var imgBytes = resizedImg.getBytes();
    var imgAsList = imgBytes.buffer.asUint8List();

    // Everything "important" is done in getPred
    return getPred(imgAsList);
  }

  Future<int> getPred(Uint8List imgAsList) async {
    // Takes img as a List as input and returns an Integer of which digit
    // the model predicts.

    // We need to convert Image which is in RGBA to Grayscale, first we can ignore
    // the alpha (opacity) and we can take the mean of R,G,B into a single channel
    final resultBytes = List.filled(28 * 28, null, growable: false);

    int index = 0;
    for (int i = 0; i < imgAsList.lengthInBytes; i += 4) {
      final r = imgAsList[i];
      final g = imgAsList[i + 1];
      final b = imgAsList[i + 2];

      // Take the mean of R,G,B channel into single GrayScale
      resultBytes[index] = ((r + g + b) / 3.0) / 255.0;
      index++;
    }

    // Thanks for having inbuilt reshape in tflite flutter, this would much more
    // annoying otherwise :)
    var input = resultBytes.reshape([1, 28, 28, 1]);
    var output = List.filled(1 * 10, null, growable: false).reshape([1, 10]);

    // Can be used to set GPUDelegate, NNAPI, parallel cores etc. We won't use
    // this, but can be good to know it exists.
    InterpreterOptions interpreterOptions = InterpreterOptions();

    // Track how long it took to do inference
    int startTime = new DateTime.now().millisecondsSinceEpoch;

    try {
      Interpreter interpreter = await Interpreter.fromAsset("model.tflite",
          options: interpreterOptions);
      interpreter.run(input, output);
    } catch (e) {
      print('Error loading or running model: ' + e.toString());
    }

    int endTime = new DateTime.now().millisecondsSinceEpoch;

    // Obtain the highest score from the output of the model
    double highestProb = 0;
    int digitPred;

    for (int i = 0; i < output[0].length; i++) {
      if (output[0][i] > highestProb) {
        highestProb = output[0][i];
        digitPred = i;
      }
    }
    return digitPred;
  }
}
