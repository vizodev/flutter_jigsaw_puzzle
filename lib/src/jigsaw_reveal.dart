// ignore_for_file:  sort_constructors_first
// TODO remove me
// ignore_for_file: public_member_api_docs

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:bitmap/bitmap.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_jigsaw_puzzle/src/extensions.dart';
import 'package:flutter_jigsaw_puzzle/src/jigsaw.dart';
import 'package:flutter_jigsaw_puzzle/src/jigsaw_colors.dart';
// import 'package:image/image.dart' as ui;

import '../flutter_jigsaw_puzzle.dart';
import 'image_box.dart';
import 'puzzle_piece/jigsaw_block_painting.dart';
import 'puzzle_piece/piece_block.dart';

final _random = math.Random().toSuperRandom();

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
  Bitmap? fullImage; // ui.Image? fullImage;
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
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }

      await SchedulerBinding.instance.endOfFrame;
      SchedulerBinding.instance.addPostFrameCallback((_) => generate());
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(widget.imageChild.image, context);
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Future<ui.Image?>
  Future<Bitmap> _getImageFromWidget() async {
    final RenderRepaintBoundary boundary = _repaintKey.currentContext!
        .findRenderObject()! as RenderRepaintBoundary;

    screenSize = boundary.size;
    final Bitmap bitmap = await Bitmap.fromProvider(widget.imageChild.image);
    return bitmap;

    // final img = await boundary.toImage();
    // final byteData = await img.toByteData(format: ImageByteFormat.png);
    // final pngBytes = byteData?.buffer.asUint8List();
    // if (pngBytes == null) {
    //   //InvalidImageException();
    //   return null;
    // }
    // return ui.decodeImage(List<int>.from(pngBytes));
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

        // final ui.Image temp = ui.copyCrop(
        //   fullImage!,
        //   xAxis.round(),
        //   yAxis.round(),
        //   widthPerBlockTemp.round(),
        //   heightPerBlockTemp.round(),
        // );
        final Uint8List cropped = fullImage!
            .apply(
              BitmapCrop.fromLTWH(
                  left: xAxis.truncate(),
                  top: yAxis.truncate(),
                  width: widthPerBlockTemp.floor(),
                  height: heightPerBlockTemp.truncate()),
            )
            .buildHeaded();

        final Offset offset = Offset(
            screenSize!.width / 2 - widthPerBlockTemp / 2,
            screenSize!.height / 2 - heightPerBlockTemp / 2);

        Color? pieceColor;
        if (configs.revealColorsPieces != null &&
            configs.revealColorsPieces!.isNotEmpty) {
          pieceColor = _pieceColors[(_random.nextInt(_pieceColors.length))];

          if (configs.revealColorsPieces!.length >= (xGrid * yGrid)) {
            _pieceColors.remove(pieceColor);
          }
        } else {
          pieceColor =
              Color((_random.nextDouble() * 0xFFFFFF).toInt()).withOpacity(1);
        }

        final ImageBox imageBox = ImageBox(
          image: Image.memory(
            // Uint8List.fromList(ui.encodePng(temp, level: 4)),
            cropped,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
            excludeFromSemantics: true,
          ),
          // imagePredominantBgColor: imagePredominantBgColor,
          pieceColor: pieceColor,
          configs: configs,
          isDone: false,
          size: Size(widthPerBlockTemp, heightPerBlockTemp),
          offsetCenter: offsetCenter,
          posSide: jigsawPosSide,
          radiusPoint: jointSize,
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
    // TODO: hack!
    // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
    // blocksNotifier.notifyListeners();
    print('GENERATE!');
    // if (mounted) setState(() {});
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
    if (mounted) {
      setState(() => _isGameFinished = true);
    }
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
            .any((element) => element.blockIsDone == false)) {
          return;
        }
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
          // final List<BlockClass> blockDone =
          //     blocks.where((block) => block.blockIsDone).toList();
          print('puzzle index: $_index');

          const padding = EdgeInsets.all(20);
          final _puzzleCanvas = AspectRatio(
            aspectRatio: 1,
            child: Padding(
              padding: padding,
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
                        child: CustomPaint(
                          painter: JigsawPainterBackground(
                            blocks,
                            configs: configs,
                          ),
                          child: Stack(
                            children: [
                              if (blocksNotifier.value.isNotEmpty)
                                ...blocksNotifier.value
                                    .asMap()
                                    .entries
                                    .map((map) {
                                  return Positioned(
                                    left: map
                                        .value.offsetDefault.dx, // .offset.dx,
                                    top: map.value.offsetDefault.dy,
                                    child: AnimatedOpacity(
                                      duration: const Duration(seconds: 1),
                                      opacity: map.value.blockIsDone ? 0 : 1,
                                      child: GestureDetector(
                                        onTapDown: (details) async {
                                          if (map.value.blockIsDone) {
                                            return;
                                          }

                                          scheduleMicrotask(
                                              () => configs.onTapPiece?.call());

                                          await Future<void>.delayed(const Duration(
                                              milliseconds:
                                                  180)); //TODO : can optimize ?? without this _index is reset after new value
                                          _index = map.key;
                                          print('set index');
                                        },
                                        child: map.value.widget,
                                      ),
                                    ),
                                  );
                                }),
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
            ),
          );

          return Stack(
            fit: StackFit.expand,
            alignment: Alignment.center,
            children: [
              Container(
                child: _puzzleCanvas,
              ),

              /// To prevent image to appear during loading
              IgnorePointer(
                child: Container(
                  foregroundDecoration: BoxDecoration(
                      color: blocksNotifier.value.isEmpty || images.isEmpty
                          ? (widget.configs.backgroundColor ?? Colors.white)
                          : Colors.transparent),
                  margin: padding,
                ),
              ),
            ],
          );
        });
  }
}
