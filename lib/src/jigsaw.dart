// TODO remove me
// ignore_for_file: public_member_api_docs

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as ui;

import 'error.dart';
import 'jigsaw_colors.dart';

class JigsawConfigs {
  const JigsawConfigs({
    this.gridSize = 3,
    this.autoStartPuzzle = false,
    this.onAutoStarted,
    required this.onBlockFitted,
    required this.onFinished,
    this.carouselDirection = Axis.horizontal,
    this.carouselSize = 160,
    this.outlineCanvas = true,
    this.outlinesWidthFactor = 1,
    this.autoStartDelay,
    this.autoStartOnTapImage = false,
    this.snapSensitivity = .5,
  });

  /// 3 => 3 x 3 | 5 => 5 x 5
  final int gridSize;
  final Function()? onBlockFitted;
  final Function()? onFinished;

  final Axis carouselDirection;

  /// May be carousel width or height, depends on [carouselDirection]
  final double carouselSize;

  /// Show pieces outlines in canvas
  final bool outlineCanvas;

  /// To make outlines (width) thicker or thinner
  ///
  /// 1 means no change | <1 make bigger | >>1 make smaller
  final double outlinesWidthFactor;

  final Function()? onAutoStarted;

  /// Auto generate blocks
  final bool autoStartPuzzle;

  /// used when [autoStartPuzzle] is true
  final Duration? autoStartDelay;

  /// Generate blocks on tap image
  final bool autoStartOnTapImage;

  /// Between 0 and 1: how hard to fit new puzzle piece
  final double snapSensitivity;
}

void _tryAutoStartPuzzle(GlobalKey<JigsawWidgetState> puzzleKey,
    {JigsawConfigs? configs}) {
  print('_tryAutoStartPuzzle...');
  if (puzzleKey.currentState?.mounted == true) {
    puzzleKey.currentState!.generate().whenComplete(() {
      if (puzzleKey.currentState?.mounted == true) {
        return configs?.onAutoStarted?.call();
      }
    });
  }
}

///
class JigsawPuzzle extends StatefulWidget {
  const JigsawPuzzle({
    Key? key,
    required this.puzzleKey,
    required this.image,
    this.imageFit = BoxFit.cover,
    required this.configs,
  }) : super(key: key);

  final GlobalKey<JigsawWidgetState> puzzleKey;
  final ImageProvider image;
  final BoxFit imageFit;
  final JigsawConfigs configs;

  bool get isHorizontalAxis => configs.carouselDirection == Axis.horizontal;

  @override
  _JigsawPuzzleState createState() => _JigsawPuzzleState();
}

class _JigsawPuzzleState extends State<JigsawPuzzle> {
  @override
  Widget build(BuildContext context) {
    return JigsawWidget(
      puzzleKey: widget.puzzleKey,
      configs: widget.configs,
      imageChild: Image(
        fit: widget.imageFit,
        image: widget.image,
        filterQuality: FilterQuality.medium,
      ),
    );
  }
}

class JigsawWidget extends StatefulWidget {
  const JigsawWidget({
    required this.puzzleKey,
    required this.configs,
    required this.imageChild,
  }) : super(key: puzzleKey);

  final GlobalKey<JigsawWidgetState> puzzleKey;
  final Image imageChild;
  final JigsawConfigs configs;

  @override
  JigsawWidgetState createState() => JigsawWidgetState();
}

class JigsawWidgetState extends State<JigsawWidget> {
  final GlobalKey _repaintKey = GlobalKey();
  JigsawConfigs get configs => widget.configs;
  Axis get direction => widget.configs.carouselDirection;

  Size? screenSize;
  ui.Image? fullImage;
  Color? imagePredominantBgColor;
  List<List<BlockClass>> images = <List<BlockClass>>[];
  ValueNotifier<List<BlockClass>> blocksNotifier =
      ValueNotifier<List<BlockClass>>(<BlockClass>[]);

  CarouselController? _carouselController;
  Widget? get carouselBlocksWidget => _carouselBlocks;
  Widget? _carouselBlocks;

  bool get isGameFinished => _isGameFinished;
  bool _isGameFinished = false;

  Offset _pos = Offset.zero;
  int? _index;

  Timer? _autoStartTimer;

  @override
  void initState() {
    super.initState();
    print('INIT');
    _carouselController = CarouselController();

    if (widget.configs.autoStartPuzzle == true) {
      _autoStartTimer = Timer(
          widget.configs.autoStartDelay ?? const Duration(milliseconds: 100),
          () => _tryAutoStartPuzzle(widget.puzzleKey, configs: widget.configs));
    }
  }

  @override
  void dispose() {
    _autoStartTimer?.cancel();
    _autoStartTimer = null;
    // ValueNotifier<List<BlockClass>>(<BlockClass>[])
    blocksNotifier.dispose();
    super.dispose();
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

  Future<void> generate() async {
    if (!mounted) {
      return;
    }
    if (images.isNotEmpty) {
      print('Something wrong with JigsawPuzzle');
      return;
    }

    images = [[]];

    fullImage ??= await _getImageFromWidget();

    /// Cover images have no white bars, is filled
    if (widget.imageChild.fit?.name != BoxFit.cover.name) {
      imagePredominantBgColor =
          (await computePaletteColor(widget.imageChild.image, screenSize))
              .dominantColor
              ?.color;
    }

    if (!mounted) {
      return;
    }
    final int xGrid = configs.gridSize;
    final int yGrid = configs.gridSize;
    final double widthPerBlock = fullImage!.width / xGrid;
    final double heightPerBlock = fullImage!.height / yGrid;

    /// Matrix XY
    for (var y = 0; y < yGrid; y++) {
      final random = math.Random();
      final tempImages = <BlockClass>[];
      images.add(tempImages);

      for (var x = 0; x < xGrid; x++) {
        final int randomPosRow = random.nextInt(2).isEven ? 1 : -1;
        final int randomPosCol = random.nextInt(2).isEven ? 1 : -1;
        // Offset offsetCenter = Offset(widthPerBlock / 2, heightPerBlock / 2);

        final PositionedData jigsawPosSide = PositionedData(
          top: y == 0 ? 0 : -images[y - 1][x].widget.imageBox.posSide.bottom,
          bottom: y == yGrid - 1 ? 0 : randomPosCol,
          left: x == 0 ? 0 : -images[y][x - 1].widget.imageBox.posSide.right,
          right: x == xGrid - 1 ? 0 : randomPosRow,
        );

        final double minSize = math.min(widthPerBlock, heightPerBlock) / 15 * 4;
        double xAxis = widthPerBlock * x;
        double yAxis = heightPerBlock * y;

        Offset offsetCenter = Offset(
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
            Uint8List.fromList(ui.encodePng(temp, level: 1)),
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
            // isAntiAlias: true,
          ),
          imagePredominantBgColor: imagePredominantBgColor,
          configs: configs,
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
    print('GENERATE!');
    setState(() {});
    return;
  }

  void reset() {
    if (!mounted) {
      return;
    }
    images.clear();
    _isGameFinished = false;
    blocksNotifier = ValueNotifier<List<BlockClass>>(<BlockClass>[]);
    // TODO: hack!
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    blocksNotifier.notifyListeners();
    setState(() {});
  }

  void finishAndReveal() {
    if (!mounted) {
      return;
    }
    images.clear();
    _isGameFinished = true;
    setState(() {});
  }

  ///
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: blocksNotifier,
        builder: (context, List<BlockClass> blocks, child) {
          final List<BlockClass> blockNotDone =
              blocks.where((block) => !block.blockIsDone).toList();
          final List<BlockClass> blockDone =
              blocks.where((block) => block.blockIsDone).toList();

          _isGameFinished =
              blockDone.length == (configs.gridSize * configs.gridSize) &&
                  blockNotDone.isEmpty;
          print('puzzle index: $_index');

          final double carouselWidth = direction == Axis.horizontal
              ? MediaQuery.of(context).size.width // null
              : configs.carouselSize;
          final double carouselHeight = direction == Axis.horizontal
              ? configs.carouselSize * .88
              : (screenSize?.height ?? MediaQuery.of(context).size.height);
          // print(MediaQuery.of(context).size);
          // print('carousel: $carouselWidth / $carouselHeight');
          _carouselBlocks = Container(
            color: JigsawColors.blocksCarouselBg,
            constraints: BoxConstraints(
              maxWidth: direction == Axis.horizontal
                  ? double.infinity
                  : MediaQuery.of(context).size.width * 0.14,
              maxHeight: direction == Axis.horizontal
                  ? MediaQuery.of(context).size.height * 0.19
                  : double.infinity,
            ),
            width: carouselWidth,
            height: carouselHeight,
            child: CarouselSlider(
              carouselController: _carouselController,
              options: CarouselOptions(
                aspectRatio: 1,
                height: carouselHeight,
                scrollDirection: direction,
                scrollPhysics: const AlwaysScrollableScrollPhysics(),
                initialPage: _index ??
                    (blockNotDone.length >= 3
                        ? (blockNotDone.length / 2).floor()
                        : 0),
                enableInfiniteScroll: false,
                viewportFraction: 0.2,
                enlargeCenterPage: true,
                enlargeStrategy: CenterPageEnlargeStrategy.height,
                onPageChanged: (index, reason) => setState(() {
                  _index = index;
                }),
              ),
              items: blockNotDone.map((block) {
                final blockSize = block.widget.imageBox.size;
                return FittedBox(
                  child: SizedBox.fromSize(
                    size: blockSize,
                    child: GestureDetector(
                      onTap: () {
                        // print('${block.posSide.toStringShort()}');
                        final blockIndex = blockNotDone.indexOf(block);
                        if (blockIndex >= 0) {
                          setState(() => _index = blockIndex);
                        }
                      },
                      child: block.widget,
                    ),
                  ),
                );
              }).toList(),
            ),
          );

          final _puzzleCanvas = AspectRatio(
              aspectRatio: 1,
              child: Listener(
                onPointerUp: (event) =>
                    handleBlockPointerUp(event, blockNotDone, blockDone),
                onPointerMove: (event) =>
                    handleBlockPointerMove(event, blockNotDone),
                child: Stack(
                  children: [
                    /// Background faded Image
                    Positioned.fill(
                      child: Opacity(
                        opacity: (blocks.isEmpty || _isGameFinished) ? 1 : .25,
                        child: widget.imageChild,
                      ),
                    ),
                    Offstage(
                      offstage: blocks.isEmpty,
                      child: SizedBox(
                        // color: JigsawColors.white,
                        // width: screenSize?.width,
                        // height: screenSize?.height,
                        child: CustomPaint(
                          painter: JigsawPainterBackground(
                            blocks,
                            configs: configs,
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
                    ),

                    /// Background finished Image
                    if (blocks.isEmpty || _isGameFinished)
                      Positioned.fill(
                        child: RepaintBoundary(
                          key: _repaintKey,
                          child: widget.imageChild,
                        ),
                      ),
                  ],
                ),
              ));

          if (direction == Axis.horizontal) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(child: _puzzleCanvas),
                carouselBlocksWidget ?? const SizedBox.shrink(),
              ],
            );
          } else {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                carouselBlocksWidget ?? const SizedBox.shrink(),
                Expanded(child: _puzzleCanvas),
              ],
            );
          }
        });
  }

  void handleBlockPointerUp(PointerUpEvent event, List<BlockClass> blockNotDone,
      List<BlockClass> blockDone) {
    if (!mounted) {
      return;
    }
    if (blockDone.isNotEmpty && blockNotDone.isEmpty /*&& !_isGameFinished*/) {
      finishAndReveal();
      configs.onFinished?.call();
    }

    if (_index == null) {
      if (widget.configs.autoStartOnTapImage == true &&
          blockNotDone.isEmpty &&
          blockDone.isEmpty) {
        _tryAutoStartPuzzle(widget.puzzleKey, configs: widget.configs);
        _autoStartTimer?.cancel();
        _autoStartTimer = null;
      }

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

    final sensitivity = configs.snapSensitivity;
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

      configs.onBlockFitted?.call();
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

class ImageBox {
  ImageBox({
    required this.image,
    this.imagePredominantBgColor,
    required this.configs,
    required this.isDone,
    required this.offsetCenter,
    required this.posSide,
    required this.radiusPoint,
    required this.size,
  });

  Widget image;
  Color? imagePredominantBgColor;
  bool isDone;
  PositionedData posSide;
  Offset offsetCenter;
  Size size;
  double radiusPoint;

  final JigsawConfigs? configs;
}

///
class JigsawPainterBackground extends CustomPainter {
  JigsawPainterBackground(this.blocks, {required this.configs});

  List<BlockClass> blocks;
  JigsawConfigs configs;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeFactor = configs.outlinesWidthFactor;
    final Paint backgroundPaint = Paint()
      ..style =
          configs.outlineCanvas ? PaintingStyle.stroke : PaintingStyle.fill
      ..color = configs.outlineCanvas
          ? JigsawColors.canvasOutline
          : JigsawColors.canvasBg
      ..strokeWidth = (JigsawDesign.strokeCanvasWidth / strokeFactor)
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
        painter: _PuzzlePiecePainter(
          isForegroundPainter: false,
          imageBox: widget.imageBox,
        ),
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
    this.isForegroundPainter = true,
    required this.imageBox,
  });

  bool isForegroundPainter;
  ImageBox imageBox;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeFactor = imageBox.configs?.outlinesWidthFactor ?? 1;

    // NEW
    if (!isForegroundPainter && imageBox.imagePredominantBgColor != null) {
      final Paint backgroundPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = imageBox.imagePredominantBgColor!;
      canvas.drawPath(
          getPiecePath(size, imageBox.radiusPoint, imageBox.offsetCenter,
              imageBox.posSide),
          backgroundPaint);

      return;
    }

    final Paint paint = Paint()
      ..color = imageBox.isDone
          ? JigsawColors.pieceOutlineDone
          : JigsawColors.pieceOutline
      ..style = PaintingStyle.stroke
      ..strokeWidth = (JigsawDesign.strokePieceWidth / strokeFactor) * 2;

    canvas.drawPath(
      getPiecePath(
          size, imageBox.radiusPoint, imageBox.offsetCenter, imageBox.posSide),
      paint,
    );

    if (imageBox.isDone) {
      final Paint paintDone = Paint()
        ..color = JigsawColors.pieceOutlineDone
        ..style = PaintingStyle.stroke
        ..strokeWidth = (JigsawDesign.strokeCanvasWidth / strokeFactor);

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
