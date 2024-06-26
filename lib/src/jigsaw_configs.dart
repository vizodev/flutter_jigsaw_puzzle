// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';

import 'jigsaw.dart';

class JigsawConfigs {
  const JigsawConfigs({
    this.yPieces = 2,
    this.xPieces = 2,
    this.screenAspectRatio,
    this.screenViewPadding,
    //
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
    this.debugSnappingDistance = false,
    this.snapSensitivity = .6,
    this.revealColorsPieces,
    this.backgroundColor,
  });
            // (useMobileXVariation || !screenIsTablet)
            //     ? screenAspectRatio != null
            //     : true,
            // "When [useMobileXVariation] is enabled, the system will also need the aspect ratio");

  ///Number of horizontal pieces
  final int xPieces;

  ///Number of vertical pieces
  final int yPieces;

  /// Because piece matching are having problems/variations when on mobile screen.
  /// We found that the system is using 100% screen size, including the notch size/bottom nav size
  final EdgeInsets? screenViewPadding;

  final Offset? screenAspectRatio;

  ///Colors used in [JigsawReveal], if total pieces ([xGrid] * [yGrid]) < Colors , then pieces will repeat colors
  ///If [revealColorsPiece] is null, widget will provide Random Colors
  ///If [revealColorsPiece.lengh] >= total pieces ([xGrid] * [yGrid]) then piece color wont repeat
  final List<Color>? revealColorsPieces;
  final Color? backgroundColor;

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

  /// Piece matching - related to [snapSensitivity]
  final bool debugSnappingDistance;

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
