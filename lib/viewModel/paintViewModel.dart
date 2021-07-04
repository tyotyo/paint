import 'dart:ui';
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart' hide Image;
import 'package:flutter/widgets.dart' hide Image;

class PaintViewModel extends ChangeNotifier {

  Color _drawColor = Color.fromARGB(255, 0, 0, 0);
  Color _backgroundColor = Colors.white;
  List<Uint8List> _media = [];

  bool _eraseMode = false;

  double _thickness = 5;

  PictureDetails? _cached;
  _PathHistory _pathHistory;
  ValueGetter<Size>? _widgetFinish;

  PaintViewModel() : _pathHistory = _PathHistory();

  bool get isEmpty => _pathHistory.isEmpty;
  bool get redoAble => _pathHistory.redoAble;

  List<Uint8List> get media => _media;
  set media(List<Uint8List> media) {
    _media = media;
    notifyListeners();
  }

  void addImage(Uint8List image) {
    _media.add(image);
    notifyListeners();
  }

  bool get eraseMode => _eraseMode;
  set eraseMode(bool activate) {
    _eraseMode = activate;
    _update();
  }

  Color get drawColor => _drawColor;
  set drawColor(Color color) {
    _drawColor = color;
    _update();
  }

  Color get backgroundColor => _backgroundColor;
  set backgroundColor(Color color) {
    _backgroundColor = color;
    _update();
  }

  double get thickness => _thickness;
  set thickness(double t) {
    _thickness = t;
    _update();
  }

  bool isFinished() {
    return _cached != null;
  }

  void _update() {
    Paint paint = Paint();
    if (_eraseMode) {
      paint.blendMode = BlendMode.clear;
      paint.color = Color.fromARGB(0, 255, 0, 0);
    } else {
      paint.color = _drawColor;
      paint.blendMode = BlendMode.srcOver;
    }

    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = _thickness;
    _pathHistory.currentPaint = paint;
    _pathHistory.setBackgroundColor(_backgroundColor);
    notifyListeners();
  }

  void undo() {
    if (!isFinished()) {
      _pathHistory.undo();
      notifyListeners();
    }
  }

  void redo() {
    if (!isFinished()) {
      _pathHistory.redo();
      notifyListeners();
    }
  }

  void _notifyListeners() {
    notifyListeners();
  }

  void clear() {
    if (!isFinished()) {
      _pathHistory.clear();
      notifyListeners();
    }
  }

  PictureDetails finish() {
    if (!isFinished()) {
      if (_widgetFinish != null) {
        _cached = _render(_widgetFinish!());
      } else {
        throw StateError("에러");
      }
    }
    return _cached!;
  }

  PictureDetails _render(Size size) {
    if (size.isEmpty) {
      throw StateError("잘못된 사이즈로 인해 렌더링이 불가능합니다.");
    } else {
      PictureRecorder recorder = PictureRecorder();
      Canvas canvas = Canvas(recorder);
      _pathHistory.draw(canvas, size);
      return PictureDetails(recorder.endRecording(), size.width.floor(), size.height.floor());
    }
  }
}


class _PathHistory {
  List<MapEntry<Path, Paint>> _paths;
  List<MapEntry<Path, Paint>> _pathsForRedo;
  Paint currentPaint;
  Paint _backgroundPaint;
  bool _inDrag;

  bool get isEmpty => _paths.isEmpty || (_paths.length == 1 && _inDrag);
  bool get redoAble => _pathsForRedo.isNotEmpty;

  _PathHistory()
    : _paths = <MapEntry<Path, Paint>>[],
        _pathsForRedo = <MapEntry<Path, Paint>>[],
      _inDrag = false,
      _backgroundPaint = Paint()..blendMode = BlendMode.dstOver,
      currentPaint = Paint()
        ..color = Colors.black
        ..strokeWidth = 1
        ..style = PaintingStyle.fill;

  void setBackgroundColor(Color backgroundColor) {
    _backgroundPaint.color = backgroundColor;
  }

  void undo() {
    if (!_inDrag) {
      _pathsForRedo.add(_paths.removeLast());
    }
  }

  void redo() {
    if (!_inDrag) {
      _paths.add(_pathsForRedo.removeLast());
    }
  }

  void clear() {
    if (!_inDrag) {
      _paths.clear();
    }
  }

  void add(Offset startPoint) {
    if (!_inDrag) {
      _inDrag = true;
      Path path = Path();
      path.moveTo(startPoint.dx, startPoint.dy);
      _paths.add(MapEntry(path, currentPaint));
      _pathsForRedo.clear();
    }
  }

  void update(Offset nextPoint) {
    if (_inDrag) {
      Path path = _paths.last.key;
      path.lineTo(nextPoint.dx, nextPoint.dy);
    }
  }

  void finish() {
    _inDrag = false;
  }

  void draw(Canvas canvas, Size size) {
    canvas.saveLayer(Offset.zero & size, Paint());
    for (MapEntry<Path, Paint> path in _paths) {
      Paint p = path.value;
      canvas.drawPath(path.key, p);
    }
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), _backgroundPaint);
    canvas.restore();
  }
}

class PictureDetails {
  final Picture picture;
  final int width;
  final int height;

  const PictureDetails(this.picture, this.width, this.height);

  Future<Image> toImage() => picture.toImage(width, height);

  Future<Uint8List> toPNG() async {
    Image image = await toImage();
    ByteData? data = await image.toByteData(format: ImageByteFormat.png);
    if (data != null) {
      return data.buffer.asUint8List();
    } else {
      throw FlutterError("이미지 변환 실패");
    }
  }
}


class Painter extends CustomPainter {

  final _PathHistory _path;

  Painter(this._path, {Listenable? repaint}) : super(repaint: repaint);
  @override
  void paint(Canvas canvas, Size size) {
    _path.draw(canvas, size);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}


class PaintView extends StatefulWidget {
  final PaintViewModel paintViewModel;

  PaintView(PaintViewModel paintViewModel)
    : this.paintViewModel = paintViewModel,
      super(key: ValueKey<PaintViewModel>(paintViewModel));
  @override
  _PaintViewState createState() => _PaintViewState();
}

class _PaintViewState extends State<PaintView> {

  bool _finished = false;
  PaintViewModel get controller => widget.paintViewModel;

  @override
  void initState() {
    super.initState();
    controller._widgetFinish = _finish;
  }

  Size _finish() {
    setState(() {
      _finished = true;
    });
    return context.size ?? const Size(0,0);
  }

  @override
  Widget build(BuildContext context) {
    Widget child = CustomPaint(
      willChange: true,
      painter: Painter(controller._pathHistory, repaint: controller),
    );
    child = ClipRect(child: child);

    if (!_finished) {
      child = GestureDetector(
        child: child,
        onPanStart: (start) {
          Offset pos = (context.findRenderObject() as RenderBox).globalToLocal(start.globalPosition);
          controller._pathHistory.add(pos);
          controller._notifyListeners();
        },
        onPanUpdate: (update) {
          Offset pos = (context.findRenderObject() as RenderBox).globalToLocal(update.globalPosition);
          controller._pathHistory.update(pos);
          controller._notifyListeners();
        },
        onPanEnd: (end) {
          controller._pathHistory.finish();
          controller._notifyListeners();
        },
      );
    }

    return Container(
      child: child,
      width: double.infinity,
      height: double.infinity,
    );
  }
}