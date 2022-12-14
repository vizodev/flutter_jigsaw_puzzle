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
      clipper: PuzzlePieceClipper(imageBox: widget.imageBox),
      child: CustomPaint(
        painter: PuzzlePiecePainter(
          isJigsawReveal: widget.isJigsawReveal,
          isForegroundPainter: false,
          imageBox: widget.imageBox,
        ),
        foregroundPainter: PuzzlePiecePainter(
          isJigsawReveal: widget.isJigsawReveal,
          imageBox: widget.imageBox,
        ),
        child: widget.imageBox.image,
      ),
    );
  }
}
