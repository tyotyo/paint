import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PaintButton extends StatefulWidget {

  final String title;
  final VoidCallback action;
  final bool activate;
  final bool disable;

  PaintButton(this.title, this.action, {
    this.activate = false,
    this.disable = false
  });

  @override
  _PaintButtonState createState() => _PaintButtonState();
}

class _PaintButtonState extends State<PaintButton> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.disable? null :  widget.action,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(5)),
          color: widget.disable? Colors.grey[400]
              : widget.activate ? Colors.blueAccent : Colors.grey
        ),
        child: Center(
          child: Text(widget.title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.bold
              )),
        ),
      ),
    );
  }
}
