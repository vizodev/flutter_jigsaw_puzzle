// TODO remove me
// ignore_for_file: public_member_api_docs

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as ui;

import 'package:flutter_jigsaw_puzzle/src/error.dart';

import 'jigsaw_colors.dart';

class JigsawPuzzle extends StatefulWidget {
  const JigsawPuzzle({
    Key? key,
    required this.puzzleKey,
    required this.gridSize,
    required this.image,
    this.onFinished,
    this.onBlockSuccess,
    this.carouselBlocksDirection = Axis.horizontal,
    this.outlineCanvas = true,
    this.autoStart = false,
    this.snapSensitivity = .5,
  }) : super(key: key);

  final GlobalKey<JigsawWidgetState> puzzleKey;
  final int gridSize;
  final AssetImage image;
  final Function()? onFinished;
  final Function()? onBlockSuccess;
  final Axis carouselBlocksDirection;
  final bool outlineCanvas;
  final bool autoStart;
  final double snapSensitivity;

  @override
  _JigsawPuzzleState createState() => _JigsawPuzzleState();
}

class _JigsawPuzzleState extends State<JigsawPuzzle> {
  @override
  Widget build(BuildContext context) {
    return JigsawWidget(
      key: widget.puzzleKey,
      gridSize: widget.gridSize,
      callbackFinish: widget.onFinished,
      callbackSuccess: widget.onBlockSuccess,
      carouselDirection: widget.carouselBlocksDirection,
      outlineCanvas: widget.outlineCanvas,
      snapSensitivity: widget.snapSensitivity,
      child: Image(
        fit: BoxFit.contain,
        image: widget.image,
      ),
    );
  }
}

class JigsawWidget extends StatefulWidget {
  const JigsawWidget({
    Key? key,
    required this.gridSize,
    this.callbackFinish,
    this.callbackSuccess,
    required this.carouselDirection,
    required this.outlineCanvas,
    required this.snapSensitivity,
    required this.child,
  }) : super(key: key);

  final Widget child;
  final int gridSize;
  final Function()? callbackFinish;
  final Function()? callbackSuccess;
  final Axis carouselDirection;
  final bool outlineCanvas;
  final double snapSensitivity;

  @override
  JigsawWidgetState createState() => JigsawWidgetState();
}

class JigsawWidgetState extends State<JigsawWidget> {
  final GlobalKey _repaintKey = GlobalKey();
  Size? screenSize;

  ui.Image? fullImage;
  List<List<BlockClass>> images = <List<BlockClass>>[];
  ValueNotifier<List<BlockClass>> blocksNotifier =
      ValueNotifier<List<BlockClass>>(<BlockClass>[]);
  CarouselController? _carouselController;
  Widget? get carouselBlocksWidget => _carouselBlocks;
  Widget? _carouselBlocks;

  Offset _pos = Offset.zero;
  int? _index;

  @override
  void initState() {
    _carouselController = CarouselController();
    super.initState();
  }

  Future<ui.Image?> _getImageFromWidget() async {
    final RenderRepaintBoundary boundary = _repaintKey.currentContext!
        .findRenderObject()! as RenderRepaintBoundary;

    screenSize = boundary.size;
    final img = await boundary.toImage();
    final byteData = await img.toByteData(format: ImageByteFormat.png);
    final pngBytes = byteData?.buffer.asUint8List();

    if (pngBytes == null) {
      throw InvalidImageException();
    }
    return ui.decodeImage(List<int>.from(pngBytes));
  }

  void reset() {
    images.clear();
    blocksNotifier = ValueNotifier<List<BlockClass>>(<BlockClass>[]);
    // TODO: hack!
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    blocksNotifier.notifyListeners();
    setState(() {});
  }

  Future<void> generate() async {
    images = [[]];

    fullImage ??= await _getImageFromWidget();

    final int xSplitCount = widget.gridSize;
    final int ySplitCount = widget.gridSize;

    final double widthPerBlock = fullImage!.width / xSplitCount;
    final double heightPerBlock = fullImage!.height / ySplitCount;

    for (var y = 0; y < ySplitCount; y++) {
      final tempImages = <BlockClass>[];

      images.add(tempImages);
      for (var x = 0; x < xSplitCount; x++) {
        final int randomPosRow = math.Random().nextInt(2).isEven ? 1 : -1;
        final int randomPosCol = math.Random().nextInt(2).isEven ? 1 : -1;

        Offset offsetCenter = Offset(widthPerBlock / 2, heightPerBlock / 2);

        final ClassJigsawPos jigsawPosSide = ClassJigsawPos(
          bottom: y == ySplitCount - 1 ? 0 : randomPosCol,
          left: x == 0 ? 0 : -images[y][x - 1].widget.imageBox.posSide.right,
          right: x == xSplitCount - 1 ? 0 : randomPosRow,
          top: y == 0 ? 0 : -images[y - 1][x].widget.imageBox.posSide.bottom,
        );

        double xAxis = widthPerBlock * x;
        double yAxis = heightPerBlock * y;

        final double minSize = math.min(widthPerBlock, heightPerBlock) / 15 * 4;

        offsetCenter = Offset(
          (widthPerBlock / 2) + (jigsawPosSide.left == 1 ? minSize : 0),
          (heightPerBlock / 2) + (jigsawPosSide.top == 1 ? minSize : 0),
        );

        xAxis -= jigsawPosSide.left == 1 ? minSize : 0;
        yAxis -= jigsawPosSide.top == 1 ? minSize : 0;

        final double widthPerBlockTemp = widthPerBlock +
            (jigsawPosSide.left == 1 ? minSize : 0) +
            (jigsawPosSide.right == 1 ? minSize : 0);
        final double heightPerBlockTemp = heightPerBlock +
            (jigsawPosSide.top == 1 ? minSize : 0) +
            (jigsawPosSide.bottom == 1 ? minSize : 0);

        final ui.Image temp = ui.copyCrop(
          fullImage!,
          xAxis.round(),
          yAxis.round(),
          widthPerBlockTemp.round(),
          heightPerBlockTemp.round(),
        );

        final Offset offset = Offset(
            screenSize!.width / 2 - widthPerBlockTemp / 2,
            screenSize!.height / 2 - heightPerBlockTemp / 2);

        final ImageBox imageBox = ImageBox(
          image: Image.memory(
            Uint8List.fromList(ui.encodePng(temp)),
            fit: BoxFit.contain,
          ),
          isDone: false,
          offsetCenter: offsetCenter,
          posSide: jigsawPosSide,
          radiusPoint: minSize,
          size: Size(widthPerBlockTemp, heightPerBlockTemp),
        );

        images[y].add(
          BlockClass(
            widget: JigsawBlockPainting(
              imageBox: imageBox,
            ),
            offset: offset,
            offsetDefault: Offset(xAxis, yAxis),
          ),
        );
      }
    }

    blocksNotifier.value = images.expand((image) => image).toList();
    blocksNotifier.value.shuffle();
    // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
    blocksNotifier.notifyListeners();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: blocksNotifier,
        builder: (context, List<BlockClass> blocks, child) {
          final List<BlockClass> blockNotDone =
              blocks.where((block) => !block.blockIsDone).toList();
          final List<BlockClass> blockDone =
              blocks.where((block) => block.blockIsDone).toList();

          _carouselBlocks = Container(
            color: JigsawColors.blocksCarouselBg,
            height: widget.carouselDirection == Axis.horizontal
                ? 110
                : screenSize?.height,
            width: widget.carouselDirection == Axis.vertical ? 130 : null,
            child: CarouselSlider(
              carouselController: _carouselController,
              options: CarouselOptions(
                scrollDirection: widget.carouselDirection,
                scrollPhysics: const AlwaysScrollableScrollPhysics(),
                initialPage: _index ??
                    (blockNotDone.length >= 3
                        ? (blockNotDone.length / 2).floor()
                        : 0),
                height: widget.carouselDirection == Axis.horizontal
                    ? 110
                    : screenSize?.height ?? 600,
                aspectRatio: 1,
                enableInfiniteScroll: false,
                viewportFraction: 0.2,
                enlargeCenterPage: true,
                enlargeStrategy: CenterPageEnlargeStrategy.height,
                onPageChanged: (index, reason) => setState(() {
                  _index = index;
                }),
              ),
              items: blockNotDone.map((block) {
                final sizeBlock = block.widget.imageBox.size;
                return FittedBox(
                  child: SizedBox.fromSize(
                    size: sizeBlock,
                    child: block.widget,
                  ),
                );
              }).toList(),
            ),
          );

          final _puzzleCanvas = AspectRatio(
            aspectRatio: 1,
            child: LayoutBuilder(builder: (context, constraints) {
              return SizedBox.fromSize(
                size: constraints.biggest,
                child: Listener(
                  onPointerUp: (event) =>
                      handleBlockPointerUp(event, blockNotDone),
                  onPointerMove: (event) =>
                      handleBlockPointerMove(event, blockNotDone),
                  child: Stack(
                    children: [
                      if (blocks.isEmpty) ...[
                        RepaintBoundary(
                          key: _repaintKey,
                          child: SizedBox.fromSize(
                            size: constraints.biggest,
                            child: widget.child,
                          ),
                        ),
                      ],
                      Offstage(
                        offstage: blocks.isEmpty,
                        child: Container(
                          color: JigsawColors.white,
                          constraints: BoxConstraints(
                            minWidth:
                                screenSize?.width ?? constraints.biggest.width,
                            minHeight: screenSize?.height ??
                                constraints.biggest.height,
                            maxWidth: constraints.biggest.width,
                            maxHeight: constraints.biggest.height,
                          ),
                          child: CustomPaint(
                            painter: JigsawPainterBackground(
                              blocks,
                              outlineCanvas: widget.outlineCanvas,
                            ),
                            child: Stack(
                              children: [
                                if (blockDone.isNotEmpty)
                                  ...blockDone.map(
                                    (map) {
                                      return Positioned(
                                        left: map.offset.dx,
                                        top: map.offset.dy,
                                        child: Container(
                                          child: map.widget,
                                        ),
                                      );
                                    },
                                  ),
                                if (blockNotDone.isNotEmpty)
                                  ...blockNotDone.asMap().entries.map(
                                    (map) {
                                      return Positioned(
                                        left: map.value.offset.dx,
                                        top: map.value.offset.dy,
                                        child: Offstage(
                                          offstage: _index != map.key,
                                          child: GestureDetector(
                                            onTapDown: (details) {
                                              if (map.value.blockIsDone) {
                                                return;
                                              }

                                              setState(() {
                                                _pos = details.localPosition;
                                                _index = map.key;
                                              });
                                            },
                                            child: Container(
                                              child: map.value.widget,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              );
            }),
          );

          // return ListView(
          //   physics: const NeverScrollableScrollPhysics(),
          //   padding: EdgeInsets.zero,
          //   shrinkWrap: true,
          //   scrollDirection: widget.carouselDirection,
          //   children: [
          //     _puzzleCanvas,
          //     carouselBlocksWidget ?? const SizedBox.shrink(),
          //   ],
          // );

          if (widget.carouselDirection == Axis.horizontal) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _puzzleCanvas,
                carouselBlocksWidget ?? const SizedBox.shrink(),
              ],
            );
          } else {
            // return _puzzleCanvas;

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                carouselBlocksWidget ?? const SizedBox.shrink(),
                _puzzleCanvas,
              ],
            );
          }
        });
  }

  void handleBlockPointerUp(
      PointerUpEvent event, List<BlockClass> blockNotDone) {
    if (blockNotDone.isEmpty) {
      reset();
      widget.callbackFinish?.call();
    }

    if (_index == null) {
      /// When no widget owns this controller
      if (_carouselController?.ready == false) {
        return;
      }

      _carouselController
          ?.nextPage(duration: const Duration(milliseconds: 1))
          .whenComplete(
        () {
          setState(() {});
          // NEW
          if (_index == null && blockNotDone.isNotEmpty) {
            _index = blockNotDone.indexOf(blockNotDone.first);
          }
        },
      );
    }
  }

  void handleBlockPointerMove(
      PointerMoveEvent event, List<BlockClass> blockNotDone) {
    if (_index == null) {
      return;
    }
    if (blockNotDone.isEmpty) {
      return;
    }

    final Offset offset = event.localPosition - _pos;

    blockNotDone[_index!].offset = offset;

    const minSensitivity = 0;
    const maxSensitivity = 1;
    const maxDistanceThreshold = 20;
    const minDistanceThreshold = 1;

    final sensitivity = widget.snapSensitivity;
    final distanceThreshold = sensitivity *
            (maxSensitivity - minSensitivity) *
            (maxDistanceThreshold - minDistanceThreshold) +
        minDistanceThreshold;

    if ((blockNotDone[_index!].offset - blockNotDone[_index!].offsetDefault)
            .distance <
        distanceThreshold) {
      blockNotDone[_index!].blockIsDone = true;

      blockNotDone[_index!].offset = blockNotDone[_index!].offsetDefault;

      _index = null;

      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      blocksNotifier.notifyListeners();

      widget.callbackSuccess?.call();
    }

    setState(() {});
  }
}

///
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

  set blockIsDone(bool value) => widget.imageBox.isDone = value;
}

class ImageBox {
  ImageBox({
    required this.image,
    required this.posSide,
    required this.isDone,
    required this.offsetCenter,
    required this.radiusPoint,
    required this.size,
  });

  Widget image;
  ClassJigsawPos posSide;
  Offset offsetCenter;
  Size size;
  double radiusPoint;
  bool isDone;
}

class ClassJigsawPos {
  ClassJigsawPos({
    required this.top,
    required this.bottom,
    required this.left,
    required this.right,
  });

  int top, bottom, left, right;
}

///
class JigsawPainterBackground extends CustomPainter {
  JigsawPainterBackground(this.blocks, {required this.outlineCanvas});

  List<BlockClass> blocks;
  bool outlineCanvas;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint backgroundPaint = Paint()
      ..style = outlineCanvas ? PaintingStyle.stroke : PaintingStyle.fill
      ..color =
          outlineCanvas ? JigsawColors.canvasOutline : JigsawColors.canvasBg
      ..strokeWidth = JigsawDesign.strokeCanvasWidth
      ..strokeCap = StrokeCap.round;

    final Path path = Path();
    blocks.forEach((element) {
      final Path pathTemp = getPiecePath(
        element.widget.imageBox.size,
        element.widget.imageBox.radiusPoint,
        element.widget.imageBox.offsetCenter,
        element.widget.imageBox.posSide,
      );

      path.addPath(pathTemp, element.offsetDefault);
    });

    canvas.drawPath(path, backgroundPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class JigsawBlockPainting extends StatefulWidget {
  const JigsawBlockPainting({Key? key, required this.imageBox})
      : super(key: key);

  final ImageBox imageBox;

  @override
  _JigsawBlockPaintingState createState() => _JigsawBlockPaintingState();
}

class _JigsawBlockPaintingState extends State<JigsawBlockPainting> {
  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _PuzzlePieceClipper(imageBox: widget.imageBox),
      child: CustomPaint(
        foregroundPainter: _PuzzlePiecePainter(
          imageBox: widget.imageBox,
        ),
        child: widget.imageBox.image,
      ),
    );
  }
}

class _PuzzlePiecePainter extends CustomPainter {
  _PuzzlePiecePainter({
    required this.imageBox,
  });

  ImageBox imageBox;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = imageBox.isDone
          ? JigsawColors.pieceOutlineDone
          : JigsawColors.pieceOutline
      ..style = PaintingStyle.stroke
      ..strokeWidth = JigsawDesign.strokePieceWidth * 2;

    canvas.drawPath(
      getPiecePath(
          size, imageBox.radiusPoint, imageBox.offsetCenter, imageBox.posSide),
      paint,
    );

    if (imageBox.isDone) {
      final Paint paintDone = Paint()
        ..color = JigsawColors.pieceOutlineDone
        ..style = PaintingStyle.fill
        ..strokeWidth = JigsawDesign.strokeCanvasWidth;

      canvas.drawPath(
        getPiecePath(size, imageBox.radiusPoint, imageBox.offsetCenter,
            imageBox.posSide),
        paintDone,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PuzzlePieceClipper extends CustomClipper<Path> {
  _PuzzlePieceClipper({
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
  ClassJigsawPos posSide,
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
      _calculatePoint(Axis.horizontal, topLeft.dy,
          Offset(offsetCenter.dx, topMiddle), radiusPoint),
      Offset.zero,
    );
  }
  path.lineTo(topRight.dx, topRight.dy);

  if (posSide.right != 0) {
    path.extendWithPath(
        _calculatePoint(Axis.vertical, topRight.dx,
            Offset(rightMiddle, offsetCenter.dy), radiusPoint),
        Offset.zero);
  }
  path.lineTo(bottomRight.dx, bottomRight.dy);

  if (posSide.bottom != 0) {
    path.extendWithPath(
        _calculatePoint(Axis.horizontal, bottomRight.dy,
            Offset(offsetCenter.dx, bottomMiddle), -radiusPoint),
        Offset.zero);
  }
  path.lineTo(bottomLeft.dx, bottomLeft.dy);

  if (posSide.left != 0) {
    path.extendWithPath(
        _calculatePoint(Axis.vertical, bottomLeft.dx,
            Offset(leftMiddle, offsetCenter.dy), -radiusPoint),
        Offset.zero);
  }
  path.lineTo(topLeft.dx, topLeft.dy);

  path.close();

  return path;
}

Path _calculatePoint(
  Axis axis,
  double fromPoint,
  Offset point,
  double radiusPoint,
) {
  final Path path = Path();

  if (axis == Axis.horizontal) {
    path.moveTo(point.dx - radiusPoint / 2, fromPoint);
    path.lineTo(point.dx - radiusPoint / 2, point.dy);
    path.lineTo(point.dx + radiusPoint / 2, point.dy);
    path.lineTo(point.dx + radiusPoint / 2, fromPoint);
  } else if (axis == Axis.vertical) {
    path.moveTo(fromPoint, point.dy - radiusPoint / 2);
    path.lineTo(point.dx, point.dy - radiusPoint / 2);
    path.lineTo(point.dx, point.dy + radiusPoint / 2);
    path.lineTo(fromPoint, point.dy + radiusPoint / 2);
  }

  return path;
}
