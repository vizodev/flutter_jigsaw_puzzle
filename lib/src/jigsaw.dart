// TODO remove me
// ignore_for_file: public_member_api_docs, always_put_control_body_on_new_line

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:bitmap/bitmap.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_jigsaw_puzzle/src/extensions.dart';
import 'package:flutter_jigsaw_puzzle/src/puzzle_piece/jigsaw_block_painting.dart';
import 'package:flutter_jigsaw_puzzle/src/puzzle_piece/piece_block.dart';
import 'package:image/image.dart' as ui;

import 'error.dart';
import 'image_box.dart';
import 'jigsaw_colors.dart';
import 'jigsaw_configs.dart';
import 'puzzle_piece/puzzle_piece_clipper.dart';

final _random = math.Random().toSuperRandom();

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
  final GlobalKey _puzzleAreaKey = GlobalKey();
  final GlobalKey _repaintKey = GlobalKey();
  JigsawConfigs get configs => widget.configs;
  Axis get direction => widget.configs.carouselDirection;

  Size? screenSize;
  ui.Image? fullImage; // Bitmap? fullImage;
  Color? imagePredominantBgColor;
  List<List<BlockClass>> images = <List<BlockClass>>[];
  ValueNotifier<List<BlockClass>> blocksNotifier =
      ValueNotifier<List<BlockClass>>(<BlockClass>[]);

  CarouselController? _carouselController;
  late GlobalKey _carouselKey;
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
    _carouselController = CarouselController();
    _carouselKey = GlobalKey();

    if (widget.configs.autoStartPuzzle == true) {
      SchedulerBinding.instance.addPostFrameCallback((_) async {
        await SchedulerBinding.instance.endOfFrame;
        await SchedulerBinding.instance.endOfFrame;
        await SchedulerBinding.instance.endOfFrame;
        _autoStartTimer = Timer(
            widget.configs.autoStartDelay ?? const Duration(),
            () =>
                tryAutoStartPuzzle(widget.puzzleKey, configs: widget.configs));
      });
    }
  }

  @override
  void dispose() {
    _autoStartTimer?.cancel();
    _autoStartTimer = null;
    // blocksNotifier.dispose();
    super.dispose();
  }

  // Future<ui.Image?>
  Future<ui.Image?> _getImageFromWidget() async {
    final RenderRepaintBoundary boundary = _repaintKey.currentContext!
        .findRenderObject()! as RenderRepaintBoundary;

    screenSize = boundary.size;
    // final imgBytes = await (await boundary.toImage()).toByteData();
    // final Bitmap bitmap = Bitmap.fromHeadless(screenSize!.width.round(),
    //     screenSize!.height.round(), imgBytes!.buffer.asUint8List());
    // return bitmap;
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
    final double widthPerBlock = screenSize!.width / xGrid;
    final double heightPerBlock = screenSize!.height / yGrid;

    /// Matrix XY
    for (var y = 0; y < yGrid; y++) {
      final tempImages = <BlockClass>[];
      images.add(tempImages);

      for (var x = 0; x < xGrid; x++) {
        final int randomPosRow = _random.nextInt(2).isEven ? 1 : -1;
        final int randomPosCol = _random.nextInt(2).isEven ? 1 : -1;
        // Offset offsetCenter = Offset(widthPerBlock / 2, heightPerBlock / 2);

        final PositionedData jigsawPosSide = PositionedData(
          top: y == 0 ? 0 : -images[y - 1][x].widget.imageBox.posSide.bottom,
          bottom: y == yGrid - 1 ? 0 : randomPosCol,
          left: x == 0 ? 0 : -images[y][x - 1].widget.imageBox.posSide.right,
          right: x == xGrid - 1 ? 0 : randomPosRow,
        );

        final double jointSize =
            JigsawDesign.jointSize(widthPerBlock, heightPerBlock);
        double xAxis = widthPerBlock * x;
        double yAxis = heightPerBlock * y;

        final Offset offsetCenter = Offset(
          (widthPerBlock / 2) + (jigsawPosSide.left == 1 ? jointSize : 0),
          (heightPerBlock / 2) + (jigsawPosSide.top == 1 ? jointSize : 0),
        );

        xAxis -= jigsawPosSide.left == 1 ? jointSize : 0;
        yAxis -= jigsawPosSide.top == 1 ? jointSize : 0;

        final double widthPerBlockTemp = widthPerBlock +
            (jigsawPosSide.left == 1 ? jointSize : 0) +
            (jigsawPosSide.right == 1 ? jointSize : 0);
        final double heightPerBlockTemp = heightPerBlock +
            (jigsawPosSide.top == 1 ? jointSize : 0) +
            (jigsawPosSide.bottom == 1 ? jointSize : 0);

        final ui.Image cropped = ui.copyCrop(
          fullImage!,
          xAxis.round(),
          yAxis.round(),
          widthPerBlockTemp.round(),
          heightPerBlockTemp.round(),
        );
        // final Uint8List cropped = fullImage!
        //     .apply(
        //       BitmapCrop.fromLTWH(
        //           left: xAxis.truncate(),
        //           top: yAxis.truncate(),
        //           width: widthPerBlockTemp.truncate(),
        //           height: heightPerBlockTemp.truncate()),
        //     )
        //     .buildHeaded();

        final Offset offset = Offset(
            screenSize!.width / 2 - widthPerBlockTemp / 2,
            screenSize!.height / 2 - heightPerBlockTemp / 2);

        final ImageBox imageBox = ImageBox(
          image: Image.memory(
            Uint8List.fromList(ui.encodePng(cropped, level: 4)),
            fit: BoxFit.contain, // BoxFit.contain
            filterQuality: FilterQuality.medium,
            excludeFromSemantics: true,
          ),
          imagePredominantBgColor: imagePredominantBgColor,
          configs: configs,
          isDone: false,
          size: Size(widthPerBlockTemp, heightPerBlockTemp),
          offsetCenter: offsetCenter,
          posSide: jigsawPosSide,
          jointSize: jointSize,
        );
        print(Offset(xAxis, yAxis).toString());
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

    final allNotifiers = images.expand((image) => image).toList()
      ..shuffle(_random);
    blocksNotifier.value = allNotifiers;
    // TODO: hack!
    // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
    // blocksNotifier.notifyListeners();
    print('GENERATE!');
    if (allNotifiers.length >= 3) {
      SchedulerBinding.instance.addPostFrameCallback((_) async {
        await SchedulerBinding.instance.endOfFrame;
        await SchedulerBinding.instance.endOfFrame;
        await SchedulerBinding.instance.endOfFrame;
        // print('SCROLL!');
        _carouselController?.jumpToPage(3);
      });
    }
    // if (mounted) setState(() {});
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
    // blocksNotifier.notifyListeners();
    print('RESET!');
    if (mounted) setState(() {});
  }

  void finishAndReveal() {
    if (!mounted) {
      return;
    }
    images.clear();
    _isGameFinished = true;
  }

  bool animatePieceScale = false;

  ///
  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: ValueListenableBuilder(
          valueListenable: blocksNotifier,
          builder: (context, List<BlockClass> blocks, child) {
            final List<BlockClass> blockNotDone =
                blocks.where((block) => !block.blockIsDone).toList();
            final List<BlockClass> blockDone =
                blocks.where((block) => block.blockIsDone).toList();

            _isGameFinished =
                blockDone.length == (configs.xPieces * configs.yPieces) &&
                    blockNotDone.isEmpty;

            if (_isGameFinished) {
              finishAndReveal();
              configs.onFinished?.call();
            }

            final double carouselWidth = direction == Axis.horizontal
                ? MediaQuery.of(context).size.width // null
                : configs.carouselSize;
            final double carouselHeight = direction == Axis.horizontal
                ? configs.carouselSize * .88
                : (screenSize?.height ?? MediaQuery.of(context).size.height);

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
                key: _carouselKey,
                carouselController: _carouselController,
                options: CarouselOptions(
                  aspectRatio: 1,
                  height: carouselHeight,
                  scrollDirection: direction,
                  scrollPhysics: const NeverScrollableScrollPhysics(),
                  // initialPage: (blockNotDone.length - 1).clamp(0, 999),
                  initialPage: _index ??
                      (blockNotDone.length >= 3
                          ? (blockNotDone.length / 2).floor()
                          : 0),
                  pageSnapping: false,
                  viewportFraction: 0.2,
                  enlargeCenterPage: true,
                  enableInfiniteScroll: false,
                  enlargeStrategy: CenterPageEnlargeStrategy.height,
                ),
                items: blockNotDone.map((block) {
                  final blockSize = block.widget.imageBox.size;
                  return LayoutBuilder(builder: (context, constraints) {
                    return GestureDetector(
                      onVerticalDragStart: (details) {
                        if (configs.carouselDirection == Axis.vertical) {
                          return;
                        }
                        setState(() => _index = blockNotDone.indexOf(block));
                      },
                      onVerticalDragUpdate: (e) {
                        if (configs.carouselDirection == Axis.vertical) {
                          return;
                        }
                        _pos = block.widget.imageBox.offsetCenter;
                        if (block.blockIsDone) return;
                        final blockIndex = blockNotDone.indexOf(block);
                        if (blockIndex >= 0) {
                          if (!mounted) return;
                          handleBlockPointerMove(
                              e.globalPosition, blockNotDone);
                        }
                      },
                      onHorizontalDragStart: (details) {
                        if (configs.carouselDirection == Axis.horizontal) {
                          return;
                        }
                        setState(() {
                          _index = blockNotDone.indexOf(block);
                        });
                      },
                      onHorizontalDragUpdate: (e) {
                        if (configs.carouselDirection == Axis.horizontal) {
                          return;
                        }
                        _pos = block.widget.imageBox.offsetCenter;
                        if (block.blockIsDone) return;
                        final blockIndex = blockNotDone.indexOf(block);
                        if (blockIndex >= 0) {
                          if (!mounted) return;
                          handleBlockPointerMove(
                              e.globalPosition, blockNotDone);
                        }
                      },
                      child: Container(
                        width: constraints.maxWidth,
                        color: Colors.white.withOpacity(.001),
                        child: FittedBox(
                          child: SizedBox.fromSize(
                            size: blockSize,
                            child: block.widget,
                          ),
                        ),
                      ),
                    );
                  });
                }).toList(),
              ),
            );

            final _pieceDragger = [
              if (blockNotDone.isNotEmpty)
                ...blockNotDone.asMap().entries.map(
                  (map) {
                    return Positioned(
                      left: map.value.offset.dx,
                      top: map.value.offset.dy,
                      child: Offstage(
                        offstage: _index != map.key,
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 80),
                          scale: animatePieceScale ? 1.1 : 1,
                          child: Listener(
                            onPointerUp: (event) {},
                            onPointerDown: (details) {
                              if (map.value.blockIsDone) {
                                return;
                              }
                              if (!mounted) return;

                              setState(() {
                                _pos = details.localPosition;
                                _index = map.key;
                              });
                            },
                            onPointerMove: (event) async {
                              if (_index == null) return;

                              await handleBlockPointerMove(
                                  event.position, blockNotDone);
                            },
                            child: Container(
                              child: map.value.widget,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                )
            ];

            final _puzzleCanvas = AspectRatio(
                key: _puzzleAreaKey,
                aspectRatio: 1,
                child: Stack(
                  children: [
                    // Background faded Image
                    Positioned.fill(
                      child: Container(
                        color: Colors.white, // because image has opacity
                        child: Opacity(
                          opacity:
                              (blocks.isEmpty || _isGameFinished) ? 1 : .25,
                          child: widget.imageChild,
                        ),
                      ),
                    ),
                    Offstage(
                      offstage: blocks.isEmpty,
                      child: SizedBox(
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
                ));

            if (direction == Axis.horizontal) {
              return Container(
                color: JigsawColors.blocksCarouselBg,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _puzzleCanvas),
                          carouselBlocksWidget ?? const SizedBox.shrink(),
                        ],
                      ),
                    ),
                    ..._pieceDragger,
                  ],
                ),
              );
            } else {
              return Container(
                color: JigsawColors.blocksCarouselBg,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          carouselBlocksWidget ?? const SizedBox.shrink(),
                          Expanded(child: _puzzleCanvas),
                        ],
                      ),
                    ),
                    ..._pieceDragger,
                  ],
                ),
              );
            }
          }),
    );
  }

  Future<void> handleBlockPointerMove(
      Offset position, List<BlockClass> blockNotDone) async {
    if (_index == null || !mounted) {
      return;
    }

    if (blockNotDone.isEmpty) {
      return;
    }

    final Offset offset = position - _pos;
    blockNotDone[_index!].offset = offset;

    const minSensitivity = 0;
    const maxSensitivity = 1.5;
    const maxDistanceThreshold = 20;
    const minDistanceThreshold = 1;

    final sensitivity = configs.snapSensitivity;
    final distanceThreshold = sensitivity *
            (maxSensitivity - minSensitivity) *
            (maxDistanceThreshold - minDistanceThreshold) +
        minDistanceThreshold;

    Offset? defaultOffsetAdjusted;

    final RenderBox? renderBox =
        _puzzleAreaKey.currentContext!.findRenderObject() as RenderBox?;

    if (renderBox != null) {
      print("render is null");
      defaultOffsetAdjusted =
          renderBox.localToGlobal(blockNotDone[_index!].offsetDefault);
    }
    print("$distanceThreshold/ajusted: $defaultOffsetAdjusted");

    final matchDistanceOffset = (blockNotDone[_index!].offset -
        (defaultOffsetAdjusted ?? blockNotDone[_index!].offsetDefault));
    print(
        "distance offset: $matchDistanceOffset/distance ${matchDistanceOffset.distance}");
    if (matchDistanceOffset.distance < distanceThreshold) {
      setState(() {
        animatePieceScale = true;
      });

      await Future<void>.delayed(const Duration(milliseconds: 100));
      if (_index == null || !mounted) return;
      blockNotDone[_index!].blockIsDone = true;

      blockNotDone[_index!].offset = blockNotDone[_index!].offsetDefault;
      _index = null;

      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      blocksNotifier.notifyListeners();

      configs.onBlockFitted?.call();
      await Future<void>.delayed(const Duration(milliseconds: 80));
      if (!mounted) return;
      if (animatePieceScale == true) {
        setState(() {
          animatePieceScale = false;
        });
      }
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
        element.widget.imageBox.jointSize,
        element.widget.imageBox.offsetCenter,
        element.widget.imageBox.posSide,
      );

      path.addPath(pathTemp, element.offsetDefault);
    });

    canvas.drawPath(path, backgroundPaint);
  }

  // IMPORTANT
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
