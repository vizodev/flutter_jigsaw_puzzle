// ignore_for_file:  sort_constructors_first
// TODO remove me
// ignore_for_file: public_member_api_docs

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_jigsaw_puzzle/src/jigsaw.dart';
import 'package:image/image.dart' as ui;

import '../flutter_jigsaw_puzzle.dart';
import 'image_box.dart';
import 'puzzle_piece/jigsaw_block_painting.dart';
import 'puzzle_piece/piece_block.dart';

///
class JigsawReveal extends StatefulWidget {
  const JigsawReveal({
    Key? key,
    required this.revealPuzzleKey,
    required this.image,
    this.imageFit = BoxFit.cover,
    required this.configs,
  }) : super(key: key);

  final GlobalKey<JigsawRevealWidgetState> revealPuzzleKey;
  final ImageProvider image;
  final BoxFit imageFit;
  final JigsawConfigs configs;

  bool get isHorizontalAxis => configs.carouselDirection == Axis.horizontal;

  @override
  _JigsawRevealState createState() => _JigsawRevealState();
}

class _JigsawRevealState extends State<JigsawReveal> {
  @override
  Widget build(BuildContext context) {
    return JigsawRevealWidget(
      puzzleKey: widget.revealPuzzleKey,
      configs: widget.configs,
      imageChild: Image(
        fit: widget.imageFit,
        image: widget.image,
        filterQuality: FilterQuality.medium,
      ),
    );
  }
}

class JigsawRevealWidget extends StatefulWidget {
  const JigsawRevealWidget({
    required this.puzzleKey,
    required this.configs,
    required this.imageChild,
  }) : super(key: puzzleKey);

  final GlobalKey<JigsawRevealWidgetState> puzzleKey;
  final Image imageChild;
  final JigsawConfigs configs;

  @override
  JigsawRevealWidgetState createState() => JigsawRevealWidgetState();
}

class JigsawRevealWidgetState extends State<JigsawRevealWidget> {
  final GlobalKey _repaintKey = GlobalKey();
  JigsawConfigs get configs => widget.configs;
  Axis get direction => widget.configs.carouselDirection;

  Size? screenSize;
  ui.Image? fullImage;
  Color? imagePredominantBgColor;
  List<List<BlockClass>> images = <List<BlockClass>>[];
  ValueNotifier<List<BlockClass>> blocksNotifier =
      ValueNotifier<List<BlockClass>>(<BlockClass>[]);

  bool get isGameFinished => _isGameFinished;
  bool _isGameFinished = false;

  int? _index;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      while (!mounted) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
      generate();
    });
  }

  @override
  void dispose() {
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
      //InvalidImageException();
      return null;
    }
    return ui.decodeImage(List<int>.from(pngBytes));
  }

  Future<void> generate() async {
    if (!mounted) {
      return;
    }
    if (images.isNotEmpty) {
      print('Something wrong with JigsawReveal');
      return;
    }

    final _pieceColors =
        List<Color>.from(configs.revealColorsPieces ?? <Color>[]);

    images = [[]];

    fullImage ??= await _getImageFromWidget();
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

        Color? pieceColor;

        if (configs.revealColorsPieces != null &&
            configs.revealColorsPieces!.isNotEmpty) {
          pieceColor =
              _pieceColors[(math.Random().nextInt(_pieceColors.length))];

          if (configs.revealColorsPieces!.length >= (xGrid * yGrid)) {
            _pieceColors.remove(pieceColor);
          }
        } else {
          pieceColor = Color((math.Random().nextDouble() * 0xFFFFFF).toInt())
              .withOpacity(1);
        }

        final ImageBox imageBox = ImageBox(
          image: Image.memory(
            Uint8List.fromList(ui.encodePng(temp, level: 1)),
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
            // isAntiAlias: true,
          ),
          // imagePredominantBgColor: imagePredominantBgColor,
          configs: configs,
          isDone: false,
          offsetCenter: offsetCenter,
          posSide: jigsawPosSide,
          radiusPoint: minSize,
          size: Size(widthPerBlockTemp, heightPerBlockTemp),
          pieceColor: pieceColor,
        );

        images[y].add(
          BlockClass(
            widget: JigsawBlockPainting(
              isJigsawReveal: true,
              imageBox: imageBox,
            ),
            offset: offset,
            offsetDefault: Offset(xAxis, yAxis),
          ),
        );
      }
    }

    blocksNotifier.value = images.expand((image) => image).toList();
    // blocksNotifier.value.shuffle();
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

    setState(() {
      // images.clear();
      _isGameFinished = true;
    });
  }

  Future<void> hideLastRevealed() async {
    if (_index == null || !mounted) return;
    setState(() {
      blocksNotifier.value.elementAt(_index!).blockIsDone = false;
    });
  }

  void resetLastRevealed() {
    scheduleMicrotask(() {
      _index = null;
    });
  }

  Future<void> revealPiece() async {
    if (!mounted) return;
    setState(() {
      if (_index == null) {
        if (!blocksNotifier.value
            .any((element) => element.blockIsDone == false)) return;
        final e = blocksNotifier.value
            .firstWhere((element) => element.blockIsDone == false);
        _index = blocksNotifier.value.indexOf(e);

        blocksNotifier.value.elementAt(_index!).blockIsDone = true;
      } else {
        blocksNotifier.value.elementAt(_index!).blockIsDone = true;
      }
    });
    await Future<void>.delayed(const Duration(seconds: 1));
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
          print('puzzle index: $_index');

          final _puzzleCanvas = AspectRatio(
              aspectRatio: 1,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Stack(
                  children: [
                    // Background faded Image
                    if (blocksNotifier.value.isNotEmpty && images.isNotEmpty)
                      Positioned.fill(
                        child: Opacity(
                            opacity: blockNotDone.isEmpty ? 1 : .25,
                            child: widget.imageChild),
                      ),
                    if (!isGameFinished && images.isNotEmpty)
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
                                // if (blockDone.isNotEmpty)
                                //   ...blockDone.map(
                                //     (map) {
                                //       return Positioned(
                                //         left: map.offset.dx,
                                //         top: map.offset.dy,
                                //         child: Container(
                                //           child: map.widget,
                                //         ),
                                //       );
                                //     },
                                //   ),
                                if (blocksNotifier.value.isNotEmpty)
                                  ...blocksNotifier.value.asMap().entries.map(
                                    (map) {
                                      return Positioned(
                                        left: map.value.offsetDefault
                                            .dx, // .offset.dx,
                                        top: map.value.offsetDefault.dy,
                                        child: AnimatedOpacity(
                                          duration: const Duration(seconds: 1),
                                          opacity:
                                              map.value.blockIsDone ? 0 : 1,
                                          child: GestureDetector(
                                            onTapDown: (details) async {
                                              if (map.value.blockIsDone) {
                                                return;
                                              }

                                              scheduleMicrotask(() =>
                                                  configs.onTapPiece?.call());

                                              await Future<void>.delayed(
                                                  const Duration(
                                                      milliseconds:
                                                          180)); //TODO : can optimize ?? whitouth this _index is resetet after new value
                                              _index = map.key;
                                              print('set index');

                                              // map.value.blockIsDone = true;
                                            },
                                            child: map.value.widget,
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

          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(child: StatefulBuilder(builder: (context, state) {
                final Color color = blocksNotifier.value.isEmpty
                    ? Colors.white
                    : Colors.transparent;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  foregroundDecoration: BoxDecoration(
                    color: color,
                  ),
                  child: _puzzleCanvas,
                );
              })),
            ],
          );
        });
  }
}
