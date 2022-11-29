// TODO remove me
// ignore_for_file: public_member_api_docs, always_put_control_body_on_new_line

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_jigsaw_puzzle/src/puzzle_piece/jigsaw_block_painting.dart';
import 'package:flutter_jigsaw_puzzle/src/puzzle_piece/piece_block.dart';
import 'package:image/image.dart' as ui;

import 'error.dart';
import 'image_box.dart';
import 'jigsaw_colors.dart';
import 'jigsaw_configs.dart';
import 'puzzle_piece/puzzle_piece_clipper.dart';

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
          () => tryAutoStartPuzzle(widget.puzzleKey, configs: widget.configs));
    }
  }

  @override
  void dispose() {
    _autoStartTimer?.cancel();
    _autoStartTimer = null;
    // blocksNotifier.dispose();
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
    // final int xGrid = configs.gridSize;
    // final int yGrid = configs.gridSize;
    final int xGrid = configs.xPieces;
    final int yGrid = configs.yPieces;
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

        final Offset offsetCenter = Offset(
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
              isJigsawReveal: false,
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
    if (mounted) setState(() {});
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
    if (mounted) setState(() {});
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

          // _isGameFinished =
          //     blockDone.length == (configs.gridSize * configs.gridSize) &&
          //         blockNotDone.isEmpty;
          _isGameFinished =
              blockDone.length == (configs.xPieces * configs.yPieces) &&
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
                onPageChanged: (index, reason) => mounted
                    ? setState(() {
                        _index = index;
                      })
                    : null,
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
                          if (!mounted) return;
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
                    // Background faded Image
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
                                            if (!mounted) return;
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
        tryAutoStartPuzzle(widget.puzzleKey, configs: widget.configs);
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
          if (!mounted) return;
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

    if (mounted) setState(() {});
  }
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
