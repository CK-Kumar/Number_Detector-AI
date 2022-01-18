import 'package:flutter/material.dart';
import 'package:image/image.dart'as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:io';

class Classifier{
  var _file = io.File(image.path);
    img.Image imageTemp = img.decodeImage(_file.readAsBytesSync());
    img.Image resizedImg = img.copyResize(imageTemp,
        height: mnistSize, width: mnistSize);
    var imgBytes = resizedImg.getBytes();
    var imgAsList = imgBytes.buffer.asUint8List();

    // Everything "important" is done in getPred
    return getPred(imgAsList);
}