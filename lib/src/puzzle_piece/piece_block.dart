import 'package:flutter/material.dart';

import 'jigsaw_block_painting.dart';

///
// ignore_for_file: public_member_api_docs

class BlockClass {
  BlockClass({
    required this.offset,
    required this.offsetDefault,
    required this.widget,
  });

  Offset offset;
  Offset offsetDefault;

  /// [JigsawBlockPainting]
  JigsawBlockPainting widget;

  bool get blockIsDone => widget.imageBox.isDone;
  PositionedData get posSide => widget.imageBox.posSide;

  set blockIsDone(bool value) => widget.imageBox.isDone = value;
}

@immutable
class PositionedData {
  const PositionedData({
    required this.top,
    required this.bottom,
    required this.left,
    required this.right,
  });

  final int top, bottom, left, right;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PositionedData &&
          runtimeType == other.runtimeType &&
          top == other.top &&
          bottom == other.bottom &&
          left == other.left &&
          right == other.right;

  @override
  int get hashCode =>
      top.hashCode ^ bottom.hashCode ^ left.hashCode ^ right.hashCode;

  String toStringShort() {
    return 'top-bottom: $top/$bottom, left-right: $left/$right';
  }
}
