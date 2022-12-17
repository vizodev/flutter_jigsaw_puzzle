// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:flutter_jigsaw_puzzle/src/puzzle_piece/piece_block.dart';

import '../image_box.dart';

class PuzzlePieceClipper extends CustomClipper<Path> {
  PuzzlePieceClipper({
    required this.imageBox,
  });

  ImageBox imageBox;

  @override
  Path getClip(Size size) {
    return getPiecePath(
        size, imageBox.jointSize, imageBox.offsetCenter, imageBox.posSide);
  }

  // IMPORTANT
  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
}

Path getPiecePath(
  Size size,
  double jointSize,
  Offset offsetCenter,
  PositionedData posSide,
) {
  final Path path = Path();

  Offset topLeft = const Offset(0, 0);
  Offset topRight = Offset(size.width, 0);
  Offset bottomLeft = Offset(0, size.height);
  Offset bottomRight = Offset(size.width, size.height);

  topLeft = Offset(posSide.left > 0 ? jointSize : 0,
          (posSide.top > 0) ? jointSize : 0) +
      topLeft;
  topRight = Offset(posSide.right > 0 ? -jointSize : 0,
          (posSide.top > 0) ? jointSize : 0) +
      topRight;
  bottomRight = Offset(posSide.right > 0 ? -jointSize : 0,
          (posSide.bottom > 0) ? -jointSize : 0) +
      bottomRight;
  bottomLeft = Offset(posSide.left > 0 ? jointSize : 0,
          (posSide.bottom > 0) ? -jointSize : 0) +
      bottomLeft;

  final double topMiddle = posSide.top == 0
      ? topRight.dy
      : (posSide.top > 0
          ? topRight.dy - jointSize
          : topRight.dy + jointSize);

  final double bottomMiddle = posSide.bottom == 0
      ? bottomRight.dy
      : (posSide.bottom > 0
          ? bottomRight.dy + jointSize
          : bottomRight.dy - jointSize);

  final double leftMiddle = posSide.left == 0
      ? topLeft.dx
      : (posSide.left > 0
          ? topLeft.dx - jointSize
          : topLeft.dx + jointSize);

  final double rightMiddle = posSide.right == 0
      ? topRight.dx
      : (posSide.right > 0
          ? topRight.dx + jointSize
          : topRight.dx - jointSize);

  path.moveTo(topLeft.dx, topLeft.dy);

  if (posSide.top != 0) {
    // path.cubicTo(
    //     offsetCenter.dx - radiusPoint,
    //     topLeft.dy - radiusPoint / 5,
    //     offsetCenter.dx - radiusPoint / 3,
    //     topLeft.dy + radiusPoint / 3,
    //     offsetCenter.dx - radiusPoint / 2,
    //     topLeft.dy);
    path.extendWithPath(
      calculatePoint(
          axis: Axis.horizontal,
          fromPoint: topLeft.dy,
          point: Offset(offsetCenter.dx, topMiddle),
          jointSize: jointSize,
          isLeft: false,
          isTop: true),
      Offset.zero,
    );
  }
  path.lineTo(topRight.dx, topRight.dy);

  if (posSide.right != 0) {
    path.quadraticBezierTo(
      topRight.dx + (jointSize / 8) * (posSide.right > 0 ? -1 : 1),
      topRight.dy + jointSize / 2,
      topRight.dx,
      offsetCenter.dy - jointSize / 2,
    );

    path.extendWithPath(
        calculatePoint(
            axis: Axis.vertical,
            fromPoint: topRight.dx,
            point: Offset(rightMiddle, offsetCenter.dy),
            jointSize: jointSize,
            isLeft: false,
            isTop: false),
        Offset.zero);

    path.quadraticBezierTo(
      topRight.dx + (jointSize / 8) * (posSide.right > 0 ? 1 : -1),
      bottomRight.dy - jointSize / 2,
      topRight.dx,
      bottomRight.dy,
    );
  }
  path.lineTo(bottomRight.dx, bottomRight.dy);

  if (posSide.bottom != 0) {
    path.extendWithPath(
        calculatePoint(
            axis: Axis.horizontal,
            fromPoint: bottomRight.dy,
            point: Offset(offsetCenter.dx, bottomMiddle),
            jointSize: -jointSize,
            isLeft: false,
            isTop: false),
        Offset.zero);
  }
  path.lineTo(bottomLeft.dx, bottomLeft.dy);

  if (posSide.left != 0) {
    //  path.moveTo(fromPoint, point.dy - radiusPoint / 2);
    path.quadraticBezierTo(
        bottomLeft.dx + (jointSize / 8) * (posSide.left > 0 ? -1 : 1),
        bottomLeft.dy - jointSize / 2,
        bottomLeft.dx,
        offsetCenter.dy + jointSize / 2);

    path.extendWithPath(
        calculatePoint(
            axis: Axis.vertical,
            fromPoint: bottomLeft.dx,
            point: Offset(leftMiddle, offsetCenter.dy),
            jointSize: -jointSize,
            isLeft: true,
            isTop: false),
        Offset.zero);

    path.quadraticBezierTo(
      bottomLeft.dx + (jointSize / 8) * (posSide.left > 0 ? 1 : -1),
      topLeft.dy + jointSize / 2,
      bottomLeft.dx,
      topLeft.dy,
    );
  } else {
    path.lineTo(topLeft.dx, topLeft.dy);
  }

  path.close();

  return path;
}

Path calculatePoint({
  required Axis axis,
  required double fromPoint,
  required Offset point,
  required double jointSize,
  required bool isLeft,
  required bool isTop,
}) {
  final Path path = Path();
  const extremeEdgeFactor = 20.5; // 3.5;
  // radiusPoint *= 1.1;
  // point = Offset(point.dx, point.dy * 0.8);

  if (axis == Axis.horizontal) {
    path.moveTo(point.dx - jointSize / 2, fromPoint);
    path.quadraticBezierTo(
      point.dx - jointSize,
      (fromPoint + (3 * point.dy)) / 4,
      point.dx - jointSize / 2,
      point.dy,
    );
    // path.lineTo(point.dx - radiusPoint / 2, point.dy);
    path.quadraticBezierTo(
      point.dx,
      point.dy < fromPoint
          ? (!isTop
              ? point.dy + jointSize / extremeEdgeFactor
              : point.dy - jointSize / extremeEdgeFactor)
          : (isTop
              ? point.dy + jointSize / extremeEdgeFactor
              : point.dy - jointSize / extremeEdgeFactor),
      point.dx + jointSize / 2,
      point.dy,
    );
    path.lineTo(point.dx + jointSize / 2, point.dy);

    path.quadraticBezierTo(
      point.dx + jointSize,
      (fromPoint + (3 * point.dy)) / 4,
      point.dx + jointSize / 2,
      fromPoint,
    );
    //path.lineTo(point.dx + radiusPoint / 2, fromPoint);
  } else if (axis == Axis.vertical) {
    path.moveTo(fromPoint, point.dy - jointSize / 2);

    ///Previous original
    // path.lineTo(point.dx, point.dy - radiusPoint / 2);
    // path.lineTo(point.dx, point.dy + radiusPoint / 2);
    // path.lineTo(fromPoint, point.dy + radiusPoint / 2);
    path.quadraticBezierTo(
      (fromPoint + (3 * point.dx)) / 4,
      point.dy - jointSize,
      point.dx,
      point.dy - jointSize / 2,
    );

    path.quadraticBezierTo(
      point.dx < fromPoint
          ? (isLeft
              ? point.dx + jointSize / extremeEdgeFactor
              : point.dx - jointSize / extremeEdgeFactor)
          : (!isLeft
              ? point.dx + jointSize / extremeEdgeFactor
              : point.dx - jointSize / extremeEdgeFactor),
      point.dy,
      point.dx,
      point.dy + jointSize / 2,
    );

    path.quadraticBezierTo(
      (fromPoint + (3 * point.dx)) / 4,
      point.dy + jointSize,
      fromPoint,
      point.dy + jointSize / 2,
    );
  }

  return path;
}
