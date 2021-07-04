import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:paint/component/button.dart';
import 'package:paint/viewModel/paintViewModel.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

class PaintFrameView extends StatefulWidget {
  // const PaintFrameView({Key? key}) : super(key: key);

  @override
  _PaintFrameViewState createState() => _PaintFrameViewState();
}

class _PaintFrameViewState extends State<PaintFrameView> {

  ImagePicker _picker = ImagePicker();
  // PaintViewModel? _controller;
  // PaintViewModel _controller = _newController();

  // static PaintViewModel _newController() {
  //   PaintViewModel controller = PaintViewModel();
  //   controller.thickness = 5.0;
  //   controller.backgroundColor = Colors.green;
  //   return controller;
  // }

  @override
  void initState() {
    super.initState();
    // _controller = Provider.of<PaintViewModel>(context)
    //   ..thickness = 5
    //   ..backgroundColor = Colors.white;
  }

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
                child: PaintButton("SAVE", () {
                  print("save");
                }, disable: true,),
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
      body: Stack(
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
    );
  }
}

