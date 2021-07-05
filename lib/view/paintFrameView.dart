import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:paint/component/button.dart';
import 'package:paint/viewModel/paintViewModel.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gallery_saver/gallery_saver.dart';

class PaintFrameView extends StatefulWidget {
  // const PaintFrameView({Key? key}) : super(key: key);

  @override
  _PaintFrameViewState createState() => _PaintFrameViewState();
}

class _PaintFrameViewState extends State<PaintFrameView> {

  ImagePicker _picker = ImagePicker();
  static GlobalKey _boxKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    PaintViewModel _controller = Provider.of<PaintViewModel>(context);
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.grey[300],
          leadingWidth: 101,
          leading: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: PaintButton("SAVE", () async {
                  var boundary = _boxKey.currentContext!.findRenderObject();
                  ui.Image image = await (boundary as RenderRepaintBoundary).toImage();
                  final directory = (await getTemporaryDirectory()).path;
                  ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
                  if (byteData != null) {
                    Uint8List pngBytes = byteData.buffer.asUint8List();
                    File imgFile = File("$directory/screenshot_${DateTime.now().millisecondsSinceEpoch}.png");
                    imgFile.writeAsBytes(pngBytes);
                    // print("캡쳐완료 $directory/screenshot_${DateTime.now().millisecondsSinceEpoch}.png");

                    GallerySaver.saveImage(imgFile.path).then((value) {
                       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("이미지가 저장되었습니다.")));
                    });
                  }

                }, disable: false),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 5),
                child: PaintButton("LOAD", () async {
                  PickedFile? picked = await _picker.getImage(source: ImageSource.gallery);
                  if (picked != null) {
                    Uint8List _image = await picked.readAsBytes();
                    setState(() {
                      _controller.media = [_image];
                    });
                  }
                }),
              ),
            ],
          ),
          title: Container(
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                PaintButton("ADD", () async {
                  PickedFile? picked = await _picker.getImage(source: ImageSource.gallery);
                  if (picked != null) {
                    Uint8List _image = await picked.readAsBytes();
                    setState(() {
                      _controller.addImage(_image);
                    });
                  }
                }),
                Row(
                  children: [
                    PaintButton("←", () {
                      setState(() {
                        _controller.undo();
                      });
                    }, disable: _controller.isEmpty),
                    Padding(
                      padding: const EdgeInsets.only(left: 5),
                      child: PaintButton("→", () {
                        setState(() {
                          _controller.redo();
                        });
                      }, disable: !_controller.redoAble),
                    ),
                  ],
                )
              ],
            ),
          ),
          actions: [
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 5),
                  child: PaintButton("PEN", () {
                    _controller.eraseMode = false;
                  }, activate: !_controller.eraseMode),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: PaintButton("ERASE", () {
                    _controller.eraseMode = true;
                  }, activate: _controller.eraseMode),
                ),
              ],
            )
          ],
        ),
      body: Container(
        color: Colors.black,
        child: Center(
          child: AspectRatio(
            aspectRatio: 1,
            child: RepaintBoundary(
              key: _boxKey,
              child: Stack(
                children: [
                  Container(
                    color: Colors.white,
                  ),
                  Stack(
                    alignment: Alignment.center,
                    children: List.generate(_controller.media.length, (index) => Container(
                      width: double.infinity,
                      height: double.infinity,
                      child: Image.memory(_controller.media[index]),
                    )),
                  ),
                  PaintView(_controller)
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

