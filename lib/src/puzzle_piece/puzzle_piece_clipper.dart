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
        size, imageBox.radiusPoint, imageBox.offsetCenter, imageBox.posSide);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
}

Path getPiecePath(
  Size size,
  double radiusPoint,
  Offset offsetCenter,
  PositionedData posSide,
) {
  final Path path = Path();

  Offset topLeft = const Offset(0, 0);
  Offset topRight = Offset(size.width, 0);
  Offset bottomLeft = Offset(0, size.height);
  Offset bottomRight = Offset(size.width, size.height);

  topLeft = Offset(posSide.left > 0 ? radiusPoint : 0,
          (posSide.top > 0) ? radiusPoint : 0) +
      topLeft;
  topRight = Offset(posSide.right > 0 ? -radiusPoint : 0,
          (posSide.top > 0) ? radiusPoint : 0) +
      topRight;
  bottomRight = Offset(posSide.right > 0 ? -radiusPoint : 0,
          (posSide.bottom > 0) ? -radiusPoint : 0) +
      bottomRight;
  bottomLeft = Offset(posSide.left > 0 ? radiusPoint : 0,
          (posSide.bottom > 0) ? -radiusPoint : 0) +
      bottomLeft;

  final double topMiddle = posSide.top == 0
      ? topRight.dy
      : (posSide.top > 0
          ? topRight.dy - radiusPoint
          : topRight.dy + radiusPoint);

  final double bottomMiddle = posSide.bottom == 0
      ? bottomRight.dy
      : (posSide.bottom > 0
          ? bottomRight.dy + radiusPoint
          : bottomRight.dy - radiusPoint);

  final double leftMiddle = posSide.left == 0
      ? topLeft.dx
      : (posSide.left > 0
          ? topLeft.dx - radiusPoint
          : topLeft.dx + radiusPoint);

  final double rightMiddle = posSide.right == 0
      ? topRight.dx
      : (posSide.right > 0
          ? topRight.dx + radiusPoint
          : topRight.dx - radiusPoint);

  path.moveTo(topLeft.dx, topLeft.dy);

  if (posSide.top != 0) {
    path.extendWithPath(
      calculatePoint(
          axis: Axis.horizontal,
          fromPoint: topLeft.dy,
          point: Offset(offsetCenter.dx, topMiddle),
          radiusPoint: radiusPoint,
          isLeft: false,
          isTop: true),
      Offset.zero,
    );
  }
  path.lineTo(topRight.dx, topRight.dy);

  if (posSide.right != 0) {
    path.extendWithPath(
        calculatePoint(
            axis: Axis.vertical,
            fromPoint: topRight.dx,
            point: Offset(rightMiddle, offsetCenter.dy),
            radiusPoint: radiusPoint,
            isLeft: false,
            isTop: false),
        Offset.zero);
  }
  path.lineTo(bottomRight.dx, bottomRight.dy);

  if (posSide.bottom != 0) {
    path.extendWithPath(
        calculatePoint(
            axis: Axis.horizontal,
            fromPoint: bottomRight.dy,
            point: Offset(offsetCenter.dx, bottomMiddle),
            radiusPoint: -radiusPoint,
            isLeft: false,
            isTop: false),
        Offset.zero);
  }
  path.lineTo(bottomLeft.dx, bottomLeft.dy);

  if (posSide.left != 0) {
    path.extendWithPath(
        calculatePoint(
            axis: Axis.vertical,
            fromPoint: bottomLeft.dx,
            point: Offset(leftMiddle, offsetCenter.dy),
            radiusPoint: -radiusPoint,
            isLeft: true,
            isTop: false),
        Offset.zero);
  }
  path.lineTo(topLeft.dx, topLeft.dy);

  path.close();

  return path;
}

Path calculatePoint({
  required Axis axis,
  required double fromPoint,
  required Offset point,
  required double radiusPoint,
  required bool isLeft,
  required bool isTop,
}) {
  final Path path = Path();

  const extremeEdgeFactor = 3.5;

  if (axis == Axis.horizontal) {
    path.moveTo(point.dx - radiusPoint / 2, fromPoint);
    path.quadraticBezierTo(
      point.dx - radiusPoint,
      (fromPoint + (3 * point.dy)) / 4,
      point.dx - radiusPoint / 2,
      point.dy,
    );
    // path.lineTo(point.dx - radiusPoint / 2, point.dy);
    path.quadraticBezierTo(
      point.dx,
      point.dy < fromPoint
          ? (!isTop
              ? point.dy + radiusPoint / extremeEdgeFactor
              : point.dy - radiusPoint / extremeEdgeFactor)
          : (isTop
              ? point.dy + radiusPoint / extremeEdgeFactor
              : point.dy - radiusPoint / extremeEdgeFactor),
      point.dx + radiusPoint / 2,
      point.dy,
    );
    path.lineTo(point.dx + radiusPoint / 2, point.dy);

    path.quadraticBezierTo(
      point.dx + radiusPoint,
      (fromPoint + (3 * point.dy)) / 4,
      point.dx + radiusPoint / 2,
      fromPoint,
    );
    //path.lineTo(point.dx + radiusPoint / 2, fromPoint);
  } else if (axis == Axis.vertical) {
    path.moveTo(fromPoint, point.dy - radiusPoint / 2);

    ///Previous original
    // path.lineTo(point.dx, point.dy - radiusPoint / 2);
// path.lineTo(point.dx, point.dy + radiusPoint / 2);
    // path.lineTo(fromPoint, point.dy + radiusPoint / 2);
    path.quadraticBezierTo(
      (fromPoint + (3 * point.dx)) / 4,
      point.dy - radiusPoint,
      point.dx,
      point.dy - radiusPoint / 2,
    );

    path.quadraticBezierTo(
      point.dx < fromPoint
          ? (isLeft
              ? point.dx + radiusPoint / extremeEdgeFactor
              : point.dx - radiusPoint / extremeEdgeFactor)
          : (!isLeft
              ? point.dx + radiusPoint / extremeEdgeFactor
              : point.dx - radiusPoint / extremeEdgeFactor),
      point.dy,
      point.dx,
      point.dy + radiusPoint / 2,
    );

    path.quadraticBezierTo(
      (fromPoint + (3 * point.dx)) / 4,
      point.dy + radiusPoint,
      fromPoint,
      point.dy + radiusPoint / 2,
    );
  }

  return path;
}
