// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';

import 'jigsaw.dart';

class JigsawConfigs {
  const JigsawConfigs({
    //this.gridSize = 3,
    this.yPieces = 2,
    this.xPieces = 2,
    this.autoStartPuzzle = false,
    this.onAutoStarted,
    this.onBlockFitted,
    this.onFinished,
    this.onTapPiece,
    this.carouselDirection = Axis.horizontal,
    this.carouselSize = 0,
    this.outlineCanvas = true,
    this.outlinesWidthFactor = 1,
    this.autoStartDelay,
    this.autoStartOnTapImage = false,
    this.snapSensitivity = .5,
    this.revealColorsPieces,
  });

  ///Number of horizontal pieces
  final int xPieces;

  ///Number of vertical pieces
  final int yPieces;

  final List<Color>? revealColorsPieces;

  final VoidCallback? onBlockFitted;
  final VoidCallback? onFinished;
  final VoidCallback? onTapPiece;

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

void tryAutoStartPuzzle(GlobalKey<JigsawWidgetState> puzzleKey,
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