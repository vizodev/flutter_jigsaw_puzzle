// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';

import '../image_box.dart';
import 'puzzle_piece_clipper.dart';
import 'puzzle_piece_painter.dart';

class JigsawBlockPainting extends StatefulWidget {
  const JigsawBlockPainting({
    Key? key,
    required this.imageBox,
    required this.isJigsawReveal,
  }) : super(key: key);

  final ImageBox imageBox;
  final bool isJigsawReveal;

  @override
  _JigsawBlockPaintingState createState() => _JigsawBlockPaintingState();
}

class _JigsawBlockPaintingState extends State<JigsawBlockPainting> {
  @override
  Widget build(BuildContext context) {
    return ClipPath(
      /// Will extend color painting | Note: [JointSize] automatically adjusts to piece sizes
      clipper: BoxClipExtender(extend: widget.imageBox.radiusPoint / 3),
      child: ClipPath(
        clipper: PuzzlePieceClipper(imageBox: widget.imageBox),
        child: CustomPaint(
          painter: PuzzlePiecePainter(
            isForegroundPainter: false,
            isJigsawReveal: widget.isJigsawReveal,
            imageBox: widget.imageBox,
          ),
          foregroundPainter: PuzzlePiecePainter(
            isJigsawReveal: widget.isJigsawReveal,
            imageBox: widget.imageBox,
          ),
          child: widget.imageBox.image,
        ),
      ),
    );
  }
}

class BoxClipExtender extends CustomClipper<Path> {
  BoxClipExtender({required this.extend});

  final double extend;

  @override
  Path getClip(Size size) {
    final path = Path()
      ..lineTo(-extend, size.height + extend)
      ..lineTo(size.width + extend, size.height + extend)
      ..lineTo(size.width + extend, -extend)
      ..close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
