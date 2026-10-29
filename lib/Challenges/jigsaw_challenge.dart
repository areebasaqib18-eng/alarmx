import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class JigsawChallengeDialog extends StatefulWidget {
  final String? difficulty;

  const JigsawChallengeDialog({
    super.key,
    this.difficulty,
  });

  @override
  State<JigsawChallengeDialog> createState() =>
      _JigsawChallengeDialogState();
}

class _JigsawChallengeDialogState
    extends State<JigsawChallengeDialog> {
  final Random _random = Random();

  static final Map<int, int?> _lastPuzzleByGridSize = {
    2: null,
    3: null,
    4: null,
  };

  int? _selectedGridSize;
  int? _puzzleIndex;

  List<int> _tiles = [];

  int? _selectedIndex;

  bool _isClosing = false;
  bool _isChecking = false;

  String? _errorText;

  final List<_JigsawPuzzle> _puzzles = const [
    // EASY
    _JigsawPuzzle(
      name: 'Burger',
      gridSize: 2,
      type: _PuzzleType.burger,
    ),
    _JigsawPuzzle(
      name: 'Pizza',
      gridSize: 2,
      type: _PuzzleType.pizza,
    ),
    _JigsawPuzzle(
      name: 'Delivery Scooter',
      gridSize: 2,
      type: _PuzzleType.scooter,
    ),
    _JigsawPuzzle(
      name: 'House',
      gridSize: 2,
      type: _PuzzleType.house,
    ),

    // MEDIUM
    _JigsawPuzzle(
      name: 'Car',
      gridSize: 3,
      type: _PuzzleType.car,
    ),
    _JigsawPuzzle(
      name: 'Cat',
      gridSize: 3,
      type: _PuzzleType.cat,
    ),
    _JigsawPuzzle(
      name: 'Donut',
      gridSize: 3,
      type: _PuzzleType.donut,
    ),
_JigsawPuzzle(
  name: 'Apple',
  gridSize: 3,
  type: _PuzzleType.apple,
),
    // HARD
    _JigsawPuzzle(
      name: 'Football',
      gridSize: 4,
      type: _PuzzleType.football,
    ),
    _JigsawPuzzle(
      name: 'Teddy Bear',
      gridSize: 4,
      type: _PuzzleType.teddy,
    ),
    _JigsawPuzzle(
      name: 'Flower',
      gridSize: 4,
      type: _PuzzleType.flower,
    ),
    _JigsawPuzzle(
      name: 'Gift Box',
      gridSize: 4,
      type: _PuzzleType.gift,
    ),
  ];

  @override
  void initState() {
    super.initState();

    if (widget.difficulty != null) {
      final difficulty =
          widget.difficulty!.trim().toLowerCase();

      final gridSize = difficulty == 'easy'
          ? 2
          : difficulty == 'hard'
              ? 4
              : 3;

      _startPuzzle(
        gridSize,
        notify: false,
      );
    }
  }

  // ==========================================================
  // START PUZZLE
  // ==========================================================

  void _startPuzzle(
    int gridSize, {
    bool notify = true,
  }) {
    final availableIndexes = <int>[];

    for (int i = 0; i < _puzzles.length; i++) {
      if (_puzzles[i].gridSize == gridSize) {
        availableIndexes.add(i);
      }
    }

    if (availableIndexes.isEmpty) return;

    final lastPuzzleIndex =
        _lastPuzzleByGridSize[gridSize];

    int selectedIndex;

    do {
      selectedIndex =
          availableIndexes[
              _random.nextInt(
                availableIndexes.length,
              )];
    } while (
        availableIndexes.length > 1 &&
        selectedIndex == lastPuzzleIndex);

    _lastPuzzleByGridSize[gridSize] =
        selectedIndex;

    final totalTiles =
        gridSize * gridSize;

    final newTiles = List<int>.generate(
      totalTiles,
      (index) => index,
    );

    do {
      newTiles.shuffle(_random);
    } while (_isSolvedList(newTiles));

    void apply() {
      _selectedGridSize = gridSize;
      _puzzleIndex = selectedIndex;
      _tiles = newTiles;
      _selectedIndex = null;
      _errorText = null;
    }

    if (notify) {
      setState(apply);
    } else {
      apply();
    }
  }

  bool _isSolvedList(
    List<int> tiles,
  ) {
    for (int i = 0; i < tiles.length; i++) {
      if (tiles[i] != i) {
        return false;
      }
    }

    return true;
  }

  bool _isSolved() {
    return _isSolvedList(_tiles);
  }

  // ==========================================================
  // SELECT / SWAP
  // ==========================================================

  void _selectTile(int index) {
    if (_isClosing || !mounted) return;

    if (_selectedIndex == null) {
      setState(() {
        _selectedIndex = index;
      });
      return;
    }

    if (_selectedIndex == index) {
      setState(() {
        _selectedIndex = null;
      });
      return;
    }

    final firstIndex = _selectedIndex!;

    setState(() {
      final temp = _tiles[firstIndex];

      _tiles[firstIndex] = _tiles[index];
      _tiles[index] = temp;

      _selectedIndex = null;
      _errorText = null;
    });
  }

  // ==========================================================
  // SUBMIT
  // ==========================================================

  Future<void> _submit() async {
    if (_isClosing ||
        _isChecking ||
        !mounted) {
      return;
    }

    _isChecking = true;

    final solved =
        _isSolved() || await _looksSolved();

    _isChecking = false;

    if (!mounted) return;

    if (solved) {
      _isClosing = true;
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _errorText =
          'Not solved yet. Match the reference picture.';
    });
  }

  Future<bool> _looksSolved() async {
    final gridSize = _selectedGridSize;
    final puzzleIndex = _puzzleIndex;

    if (gridSize == null ||
        puzzleIndex == null) {
      return false;
    }

    final puzzle = _puzzles[puzzleIndex];

    final cache = <int, Uint8List>{};

    Future<Uint8List> pixels(
      int tileIndex,
    ) async {
      final cached = cache[tileIndex];

      if (cached != null) {
        return cached;
      }

      const size = 64;

      final recorder =
          ui.PictureRecorder();

      _JigsawTilePainter(
        tileIndex: tileIndex,
        gridSize: gridSize,
        puzzle: puzzle,
      ).paint(
        Canvas(recorder),
         Size(
          size.toDouble(),
          size.toDouble(),
        ),
      );

      final image =
          await recorder.endRecording().toImage(
                size,
                size,
              );

      final data =
          await image.toByteData();

      image.dispose();

      return cache[tileIndex] =
          data!.buffer.asUint8List();
    }

    for (int i = 0;
        i < _tiles.length;
        i++) {
      if (_tiles[i] == i) {
        continue;
      }

      if (!listEquals(
        await pixels(_tiles[i]),
        await pixels(i),
      )) {
        return false;
      }
    }

    return true;
  }

  // ==========================================================
  // DIFFICULTY
  // ==========================================================

  Widget _buildDifficultySelection() {
    return SizedBox(
      width: 320,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Choose Difficulty',
            style: TextStyle(
              color: Color(0xFFB7C0CC),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),

          _difficultyButton(
            title: 'Easy',
            subtitle: '2 × 2 Puzzle',
            color: const Color(0xFF4CAF50),
            onTap: () => _startPuzzle(2),
          ),

          const SizedBox(height: 12),

          _difficultyButton(
            title: 'Medium',
            subtitle: '3 × 3 Puzzle',
            color: const Color(0xFFFFA726),
            onTap: () => _startPuzzle(3),
          ),

          const SizedBox(height: 12),

          _difficultyButton(
            title: 'Hard',
            subtitle: '4 × 4 Puzzle',
            color: const Color(0xFFE85D5D),
            onTap: () => _startPuzzle(4),
          ),
        ],
      ),
    );
  }

  Widget _difficultyButton({
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 68,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              const Color(0xFF2C3541),
          foregroundColor: Colors.white,
          elevation: 0,
          padding:
              const EdgeInsets.symmetric(
            horizontal: 18,
          ),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(14),
            side: BorderSide(
              color:
                  color.withValues(alpha: 0.65),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style:
                        const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style:
                        const TextStyle(
                      color:
                          Color(0xFF9AA7B5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color:
                  Color(0xFF9AA7B5),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // PUZZLE SCREEN
  // ==========================================================

  Widget _buildPuzzle() {
    final puzzle =
        _puzzles[_puzzleIndex!];

    final gridSize =
        _selectedGridSize!;

    final difficulty = gridSize == 2
        ? 'Easy'
        : gridSize == 3
            ? 'Medium'
            : 'Hard';

    return SizedBox(
      width: 320,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                if (widget.difficulty == null)
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedGridSize =
                            null;
                        _puzzleIndex = null;
                        _tiles = [];
                        _selectedIndex = null;
                        _errorText = null;
                      });
                    },
                    icon: const Icon(
                      Icons
                          .arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  )
                else
                  const SizedBox(width: 48),

                Expanded(
                  child: Text(
                    '$difficulty • '
                    '$gridSize×$gridSize',
                    textAlign: TextAlign.center,
                    style:
                        const TextStyle(
                      color:
                          Color(0xFFB7C0CC),
                      fontSize: 13,
                      fontWeight:
                          FontWeight.w500,
                    ),
                  ),
                ),

                const SizedBox(width: 48),
              ],
            ),

            const SizedBox(height: 4),

            Text(
              'Complete the ${puzzle.name} '
              'puzzle to turn off the alarm.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color:
                    Color(0xFFB7C0CC),
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 16),

            const Align(
              alignment:
                  Alignment.centerLeft,
              child: Text(
                'Reference Picture',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 8),

            Container(
              width: double.infinity,
              height: 190,
              padding:
                  const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color:
                    const Color(0xFF11161C),
                borderRadius:
                    BorderRadius.circular(14),
                border: Border.all(
                  color:
                      const Color(0xFF3A4654),
                ),
              ),
              child: ClipRRect(
                borderRadius:
                    BorderRadius.circular(9),
                child: CustomPaint(
                  painter:
                      _JigsawReferencePainter(
                    puzzle: puzzle,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 18),

            Align(
              alignment:
                  Alignment.centerLeft,
              child: Text(
                'Arrange the pieces '
                '($gridSize×$gridSize)',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 8),

            _buildPuzzleBoard(
              puzzle,
              gridSize,
            ),

            const SizedBox(height: 12),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Icon(
                  _selectedIndex == null
                      ? Icons.touch_app_rounded
                      : Icons.swap_horiz_rounded,
                  color:
                      const Color(0xFF7C9CFF),
                  size: 18,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    _selectedIndex == null
                        ? 'Tap a piece to select it'
                        : 'Tap another piece to swap',
                    textAlign:
                        TextAlign.center,
                    style:
                        const TextStyle(
                      color:
                          Color(0xFF9AA7B5),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),

            if (_errorText != null) ...[
              const SizedBox(height: 10),
              Text(
                _errorText!,
                textAlign:
                    TextAlign.center,
                style:
                    const TextStyle(
                  color:
                      Color(0xFFE85D5D),
                  fontSize: 13,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // NEW CLEAR JIGSAW BOARD
  // ==========================================================

  Widget _buildPuzzleBoard(
    _JigsawPuzzle puzzle,
    int gridSize,
  ) {
    return LayoutBuilder(
      builder:
          (context, constraints) {
        final availableWidth =
            constraints.maxWidth - 10;

        // The board includes extra room for
        // visible tabs.
        final puzzleSize = min(
          300.0,
          availableWidth /
              (1 + 0.36 / gridSize),
        );

        final cell =
            puzzleSize / gridSize;

        final tab = cell * 0.18;

        final boardSize =
            puzzleSize + tab * 2;

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color:
                const Color(0xFF0D1218),
            borderRadius:
                BorderRadius.circular(16),
            border: Border.all(
              color:
                  const Color(0xFF293441),
              width: 1,
            ),
          ),
          padding:
              const EdgeInsets.all(5),
          child: Center(
            child: SizedBox(
              width: boardSize,
              height: boardSize,
              child: Stack(
                clipBehavior:
                    Clip.none,
                children: [
                  // ------------------------------------------------
                  // VISUAL JIGSAW PIECES
                  // ------------------------------------------------

                  for (int index = 0;
                      index < _tiles.length;
                      index++)
                    Positioned(
                      left:
                          (index % gridSize) *
                              cell,
                      top:
                          (index ~/ gridSize) *
                              cell,
                      width:
                          cell + tab * 2,
                      height:
                          cell + tab * 2,
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter:
                              _JigsawTilePainter(
                            tileIndex:
                                _tiles[index],
                            gridSize:
                                gridSize,
                            puzzle:
                                puzzle,
                            isSelected:
                                _selectedIndex ==
                                    index,
                          ),
                        ),
                      ),
                    ),

                  // ------------------------------------------------
                  // CLEAN TOUCH AREAS
                  // These remain square internally so selecting
                  // pieces is easy even when tabs overlap.
                  // ------------------------------------------------

                  for (int index = 0;
                      index < _tiles.length;
                      index++)
                    Positioned(
                      left: tab +
                          (index % gridSize) *
                              cell,
                      top: tab +
                          (index ~/ gridSize) *
                              cell,
                      width: cell,
                      height: cell,
                      child: GestureDetector(
                        behavior:
                            HitTestBehavior.opaque,
                        onTap: () =>
                            _selectTile(index),
                        child:
                            const SizedBox.expand(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final showingDifficulty =
        _selectedGridSize == null &&
            widget.difficulty == null;

    return AlertDialog(
      backgroundColor:
          const Color(0xFF202833),
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(20),
      ),
      title: const Text(
        'Jigsaw Puzzle',
        style: TextStyle(
          color: Colors.white,
          fontWeight:
              FontWeight.w600,
        ),
      ),
      content:
          showingDifficulty
              ? _buildDifficultySelection()
              : _buildPuzzle(),
      actions:
          showingDifficulty
              ? null
              : [
                  SizedBox(
                    width: double.infinity,
                    child:
                        ElevatedButton(
                      onPressed: _submit,
                      style:
                          ElevatedButton
                              .styleFrom(
                        backgroundColor:
                            const Color(
                          0xFF7C9CFF,
                        ),
                        foregroundColor:
                            Colors.white,
                        minimumSize:
                            const Size(
                          double.infinity,
                          48,
                        ),
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            12,
                          ),
                        ),
                      ),
                      child: const Text(
                        'Submit',
                        style:
                            TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
    );
  }
}

// ============================================================
// PUZZLE DATA
// ============================================================

enum _PuzzleType {
  burger,
  pizza,
  scooter,
  house,
  car,
  cat,
  donut,
  apple,
  football,
  teddy,
  flower,
  gift,
}

class _JigsawPuzzle {
  final String name;
  final int gridSize;
  final _PuzzleType type;

  const _JigsawPuzzle({
    required this.name,
    required this.gridSize,
    required this.type,
  });
}

// ============================================================
// REFERENCE PAINTER
// ============================================================

class _JigsawReferencePainter
    extends CustomPainter {
  final _JigsawPuzzle puzzle;

  const _JigsawReferencePainter({
    required this.puzzle,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final scale =
        min(
          size.width / 300,
          size.height / 300,
        );

    final width =
        300 * scale;

    final height =
        300 * scale;

    final offsetX =
        (size.width - width) / 2;

    final offsetY =
        (size.height - height) / 2;

    canvas.save();

    canvas.translate(
      offsetX,
      offsetY,
    );

    _paintPuzzleScene(
      canvas,
      scale: scale,
      type: puzzle.type,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(
    covariant
        _JigsawReferencePainter
            oldDelegate,
  ) {
    return oldDelegate.puzzle.type !=
        puzzle.type;
  }
}

// ============================================================
// JIGSAW TILE PAINTER
// ============================================================

class _JigsawTilePainter
    extends CustomPainter {
  final int tileIndex;
  final int gridSize;
  final _JigsawPuzzle puzzle;
  final bool isSelected;

  const _JigsawTilePainter({
    required this.tileIndex,
    required this.gridSize,
    required this.puzzle,
    this.isSelected = false,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    // The actual logical cell is smaller than
    // the painter canvas. Extra space allows
    // tabs and holes to be visible.
    final cellSize =
        size.width / 1.36;

    final tab =
        cellSize * 0.18;

    final column =
        tileIndex % gridSize;

    final row =
        tileIndex ~/ gridSize;

    final scale =
        (gridSize * cellSize) / 300;

    final piecePath =
        _createJigsawPiecePath(
      size,
      row,
      column,
      gridSize,
    );

    // ----------------------------------------------------------
    // SHADOW
    // ----------------------------------------------------------

    canvas.save();

    canvas.translate(
      1.5,
      2.0,
    );

    canvas.drawPath(
      piecePath,
      Paint()
        ..color =
            const Color(0x99000000)
        ..style =
            PaintingStyle.fill
        ..maskFilter =
            const MaskFilter.blur(
          BlurStyle.normal,
          2.5,
        ),
    );

    canvas.restore();

    // ----------------------------------------------------------
    // BRIGHT IMAGE
    // ----------------------------------------------------------

    canvas.save();

    canvas.clipPath(
      piecePath,
    );

    final imagePaint =
        Paint()
          ..colorFilter =
              const ColorFilter.matrix([
        1.15, 0, 0, 0, 6,
        0, 1.15, 0, 0, 6,
        0, 0, 1.15, 0, 6,
        0, 0, 0, 1, 0,
      ]);

    canvas.saveLayer(
      null,
      imagePaint,
    );

    canvas.translate(
      tab -
          column * cellSize,
      tab -
          row * cellSize,
    );

    _paintPuzzleScene(
      canvas,
      scale: scale,
      type: puzzle.type,
    );

    canvas.restore();

    canvas.restore();

    // ----------------------------------------------------------
    // VERY CLEAR DARK OUTLINE
    // ----------------------------------------------------------

    canvas.drawPath(
      piecePath,
      Paint()
        ..color =
            const Color(0xFF11161C)
        ..style =
            PaintingStyle.stroke
        ..strokeWidth = 3.4
        ..strokeJoin =
            StrokeJoin.round
        ..strokeCap =
            StrokeCap.round,
    );

    // Thin highlight just inside the dark
    // outline.
    canvas.drawPath(
      piecePath,
      Paint()
        ..color =
            const Color(0x66FFFFFF)
        ..style =
            PaintingStyle.stroke
        ..strokeWidth = 0.9,
    );

    // Selected piece.
    if (isSelected) {
      canvas.drawPath(
        piecePath,
        Paint()
          ..color =
              const Color(0xFF7C9CFF)
          ..style =
              PaintingStyle.stroke
          ..strokeWidth = 4.5
          ..strokeJoin =
              StrokeJoin.round,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant
        _JigsawTilePainter
            oldDelegate,
  ) {
    return oldDelegate.tileIndex !=
            tileIndex ||
        oldDelegate.gridSize !=
            gridSize ||
        oldDelegate.puzzle.type !=
            puzzle.type ||
        oldDelegate.isSelected !=
            isSelected;
  }
}

// ============================================================
// CLEAR INTERLOCKING JIGSAW PIECE
// ============================================================

Path _createJigsawPiecePath(
  Size size,
  int row,
  int column,
  int gridSize,
) {
  final cell = size.width / 1.36;
  final tab = cell * 0.18;

  final pieceLeft = tab;
  final pieceTop = tab;
  final pieceRight = tab + cell;
  final pieceBottom = tab + cell;

  int horizontalEdge(int r, int c) {
    return ((r * gridSize + c).isEven) ? 1 : -1;
  }

  int verticalEdge(int r, int c) {
    return ((r * gridSize + c).isEven) ? 1 : -1;
  }

  final topType = row == 0
      ? 0
      : -verticalEdge(row - 1, column);

  final rightType = column == gridSize - 1
      ? 0
      : horizontalEdge(row, column);

  final bottomType = row == gridSize - 1
      ? 0
      : verticalEdge(row, column);

  final leftType = column == 0
      ? 0
      : -horizontalEdge(row, column - 1);

  final path = Path()
    ..moveTo(pieceLeft, pieceTop);

  // TOP
  _addJigsawEdge(
    path,
    Offset(pieceLeft, pieceTop),
    Offset(pieceRight, pieceTop),
    const Offset(0, -1),
    topType,
    tab,
  );

  // RIGHT
  _addJigsawEdge(
    path,
    Offset(pieceRight, pieceTop),
    Offset(pieceRight, pieceBottom),
    const Offset(1, 0),
    rightType,
    tab,
  );

  // BOTTOM
  _addJigsawEdge(
    path,
    Offset(pieceRight, pieceBottom),
    Offset(pieceLeft, pieceBottom),
    const Offset(0, 1),
    bottomType,
    tab,
  );

  // LEFT
  _addJigsawEdge(
    path,
    Offset(pieceLeft, pieceBottom),
    Offset(pieceLeft, pieceTop),
    const Offset(-1, 0),
    leftType,
    tab,
  );

  path.close();
  return path;
}



// ============================================================
// BIG ROUND TAB / HOLE
// ============================================================

void _addJigsawEdge(
  Path path,
  Offset start,
  Offset end,
  Offset outward,
  int type,
  double tab,
) {
  if (type == 0) {
    path.lineTo(
      end.dx,
      end.dy,
    );
    return;
  }

  final dx =
      end.dx - start.dx;

  final dy =
      end.dy - start.dy;

  final length =
      sqrt(
        dx * dx +
            dy * dy,
      );

  if (length <= 0) {
    return;
  }

  final ux =
      dx / length;

  final uy =
      dy / length;

  // Stronger, clearer tabs.
  final depth =
      tab * 1.20;

  Offset point(
    double along,
    double distance,
  ) {
    return Offset(
      start.dx +
          ux * along +
          outward.dx *
              distance *
              type,
      start.dy +
          uy * along +
          outward.dy *
              distance *
              type,
    );
  }

  final a =
      length * 0.30;

  final b =
      length * 0.39;

  final c =
      length * 0.61;

  final d =
      length * 0.70;

  // Straight beginning.
  final startPoint =
      point(a, 0);

  path.lineTo(
    startPoint.dx,
    startPoint.dy,
  );

  // ----------------------------------------------------------
  // FIRST NECK
  // ----------------------------------------------------------

  final p1 =
      point(
    b,
    depth * 0.12,
  );

  final c1 =
      point(
    a + length * 0.04,
    depth * 0.02,
  );

  final c2 =
      point(
    b - length * 0.02,
    depth * 0.10,
  );

  path.cubicTo(
    c1.dx,
    c1.dy,
    c2.dx,
    c2.dy,
    p1.dx,
    p1.dy,
  );

  // ----------------------------------------------------------
  // ROUND OUTER / INNER TAB
  // ----------------------------------------------------------

  final p2 =
      point(
    length * 0.50,
    depth,
  );

  final c3 =
      point(
    b,
    depth * 0.78,
  );

  final c4 =
      point(
    length * 0.44,
    depth,
  );

  path.cubicTo(
    c3.dx,
    c3.dy,
    c4.dx,
    c4.dy,
    p2.dx,
    p2.dy,
  );

  // ----------------------------------------------------------
  // SECOND HALF
  // ----------------------------------------------------------

  final c5 =
      point(
    length * 0.56,
    depth,
  );

  final c6 =
      point(
    c,
    depth * 0.78,
  );

  path.cubicTo(
    c5.dx,
    c5.dy,
    c6.dx,
    c6.dy,
    point(
      c,
      depth * 0.12,
    ).dx,
    point(
      c,
      depth * 0.12,
    ).dy,
  );

  // ----------------------------------------------------------
  // SECOND NECK
  // ----------------------------------------------------------

  final p3 =
      point(
    d,
    0,
  );

  final c7 =
      point(
    c + length * 0.02,
    depth * 0.10,
  );

  final c8 =
      point(
    d - length * 0.04,
    depth * 0.02,
  );

  path.cubicTo(
    c7.dx,
    c7.dy,
    c8.dx,
    c8.dy,
    p3.dx,
    p3.dy,
  );

  path.lineTo(
    end.dx,
    end.dy,
  );
}

// ============================================================
// SCENE SWITCH
// ============================================================

void _paintPuzzleScene(
  Canvas canvas, {
  required double scale,
  required _PuzzleType type,
}) {
  switch (type) {
    case _PuzzleType.burger:
      _paintBurger(canvas, scale);
      break;

    case _PuzzleType.pizza:
      _paintPizza(canvas, scale);
      break;

    case _PuzzleType.scooter:
      _paintScooter(canvas, scale);
      break;

    case _PuzzleType.house:
      _paintHouse(canvas, scale);
      break;

    case _PuzzleType.car:
      _paintCar(canvas, scale);
      break;

    case _PuzzleType.cat:
      _paintCat(canvas, scale);
      break;

    case _PuzzleType.donut:
      _paintDonut(canvas, scale);
      break;
case _PuzzleType.apple:
  _paintApple(canvas, scale);
  break;

    case _PuzzleType.football:
      _paintFootball(canvas, scale);
      break;

    case _PuzzleType.teddy:
      _paintTeddy(canvas, scale);
      break;

    case _PuzzleType.flower:
      _paintFlower(canvas, scale);
      break;

    case _PuzzleType.gift:
      _paintGift(canvas, scale);
      break;
  }
}

// ============================================================
// DRAWING HELPERS
// ============================================================

void _fill(
  Canvas canvas,
  Color color,
  double scale,
  double left,
  double top,
  double width,
  double height,
) {
  canvas.drawRect(
    Rect.fromLTWH(
      left * scale,
      top * scale,
      width * scale,
      height * scale,
    ),
    Paint()..color = color,
  );
}

void _circle(
  Canvas canvas,
  Color color,
  double scale,
  double x,
  double y,
  double radius,
) {
  canvas.drawCircle(
    Offset(
      x * scale,
      y * scale,
    ),
    radius * scale,
    Paint()..color = color,
  );
}

void _line(
  Canvas canvas,
  Color color,
  double scale,
  Offset a,
  Offset b, {
  double width = 4,
}) {
  final paint = Paint()
    ..color = color
    ..style =
        PaintingStyle.stroke
    ..strokeWidth =
        width * scale
    ..strokeCap =
        StrokeCap.round;

  canvas.drawLine(
    Offset(
      a.dx * scale,
      a.dy * scale,
    ),
    Offset(
      b.dx * scale,
      b.dy * scale,
    ),
    paint,
  );
}

// ============================================================
// BURGER
// ============================================================

void _paintBurger(
  Canvas canvas,
  double scale,
) {
  // Fresh warm background.
  _fill(
    canvas,
    const Color(0xFFFFE3A8),
    scale,
    0,
    0,
    300,
    300,
  );

  _fill(
    canvas,
    const Color(0xFFE6A15B),
    scale,
    0,
    190,
    300,
    110,
  );

  // Table lines.
  for (int y = 205;
      y <= 280;
      y += 25) {
    _line(
      canvas,
      const Color(0xFFC77A3F),
      scale,
      Offset(0, y.toDouble()),
      Offset(300, y.toDouble()),
      width: 3,
    );
  }

  // Plate.
  canvas.drawOval(
    Rect.fromLTWH(
      35 * scale,
      205 * scale,
      230 * scale,
      65 * scale,
    ),
    Paint()
      ..color =
          const Color(0xFFFDFDFD),
  );

  canvas.drawOval(
    Rect.fromLTWH(
      50 * scale,
      215 * scale,
      200 * scale,
      42 * scale,
    ),
    Paint()
      ..color =
          const Color(0xFFDDE5EA),
  );

  // Bottom bun.
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(
        70 * scale,
        155 * scale,
        160 * scale,
        52 * scale,
      ),
      Radius.circular(
        20 * scale,
      ),
    ),
    Paint()
      ..color =
          const Color(0xFFD98832),
  );

  // Meat.
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(
        72 * scale,
        130 * scale,
        156 * scale,
        30 * scale,
      ),
      Radius.circular(
        8 * scale,
      ),
    ),
    Paint()
      ..color =
          const Color(0xFF693A25),
  );

  // Cheese.
  final cheese = Path()
    ..moveTo(
      70 * scale,
      150 * scale,
    )
    ..lineTo(
      230 * scale,
      150 * scale,
    )
    ..lineTo(
      214 * scale,
      175 * scale,
    )
    ..lineTo(
      195 * scale,
      166 * scale,
    )
    ..lineTo(
      175 * scale,
      176 * scale,
    )
    ..lineTo(
      150 * scale,
      166 * scale,
    )
    ..lineTo(
      125 * scale,
      176 * scale,
    )
    ..lineTo(
      100 * scale,
      166 * scale,
    )
    ..lineTo(
      82 * scale,
      175 * scale,
    )
    ..close();

  canvas.drawPath(
    cheese,
    Paint()
      ..color =
          const Color(0xFFFFD43B),
  );

  // Lettuce.
  final lettuce = Path()
    ..moveTo(
      70 * scale,
      125 * scale,
    )
    ..lineTo(
      230 * scale,
      125 * scale,
    )
    ..lineTo(
      215 * scale,
      140 * scale,
    )
    ..lineTo(
      195 * scale,
      133 * scale,
    )
    ..lineTo(
      175 * scale,
      142 * scale,
    )
    ..lineTo(
      150 * scale,
      133 * scale,
    )
    ..lineTo(
      125 * scale,
      142 * scale,
    )
    ..lineTo(
      105 * scale,
      133 * scale,
    )
    ..lineTo(
      85 * scale,
      142 * scale,
    )
    ..close();

  canvas.drawPath(
    lettuce,
    Paint()
      ..color =
          const Color(0xFF49B84E),
  );

  // Tomato.
  canvas.drawOval(
    Rect.fromLTWH(
      85 * scale,
      108 * scale,
      130 * scale,
      27 * scale,
    ),
    Paint()
      ..color =
          const Color(0xFFE94343),
  );

  // Top bun.
  canvas.drawOval(
    Rect.fromLTWH(
      68 * scale,
      55 * scale,
      164 * scale,
      78 * scale,
    ),
    Paint()
      ..color =
          const Color(0xFFECA83C),
  );

  final seedPaint =
      Paint()
        ..color =
            const Color(0xFFFFE8AE);

  final seeds = [
    const Offset(95, 82),
    const Offset(120, 70),
    const Offset(148, 82),
    const Offset(175, 70),
    const Offset(202, 88),
    const Offset(135, 98),
    const Offset(185, 100),
  ];

  for (final p in seeds) {
    canvas.drawOval(
      Rect.fromLTWH(
        (p.dx - 4) * scale,
        (p.dy - 2) * scale,
        8 * scale,
        4 * scale,
      ),
      seedPaint,
    );
  }

  // Decorative sides.
  _fill(
    canvas,
    const Color(0xFFE84A45),
    scale,
    15,
    60,
    32,
    75,
  );

  _fill(
    canvas,
    Colors.white,
    scale,
    19,
    76,
    24,
    20,
  );

  _fill(
    canvas,
    const Color(0xFFFFC928),
    scale,
    253,
    60,
    32,
    75,
  );

  _fill(
    canvas,
    Colors.white,
    scale,
    257,
    76,
    24,
    20,
  );
}

// ============================================================
// PIZZA
// ============================================================

void _paintPizza(
  Canvas canvas,
  double scale,
) {
  _fill(
    canvas,
    const Color(0xFFFFDDA8),
    scale,
    0,
    0,
    300,
    300,
  );

  // Checker table.
  const tile = 30.0;

  for (int row = 0;
      row < 10;
      row++) {
    for (int col = 0;
        col < 10;
        col++) {
      _fill(
        canvas,
        (row + col).isEven
            ? const Color(0xFFFFEBC9)
            : const Color(0xFFD99A5C),
        scale,
        col * tile,
        row * tile,
        tile,
        tile,
      );
    }
  }

  // Plate.
  canvas.drawCircle(
    Offset(
      150 * scale,
      160 * scale,
    ),
    108 * scale,
    Paint()
      ..color =
          const Color(0xFFFDFDFD),
  );

  canvas.drawCircle(
    Offset(
      150 * scale,
      160 * scale,
    ),
    96 * scale,
    Paint()
      ..color =
          const Color(0xFFE3EAF0),
  );

  // Pizza.
  final crust = Path()
    ..moveTo(
      58 * scale,
      100 * scale,
    )
    ..quadraticBezierTo(
      150 * scale,
      55 * scale,
      242 * scale,
      100 * scale,
    )
    ..lineTo(
      150 * scale,
      248 * scale,
    )
    ..close();

  canvas.drawPath(
    crust,
    Paint()
      ..color =
          const Color(0xFFC86F2E),
  );

  final cheese = Path()
    ..moveTo(
      70 * scale,
      105 * scale,
    )
    ..quadraticBezierTo(
      150 * scale,
      70 * scale,
      230 * scale,
      105 * scale,
    )
    ..lineTo(
      150 * scale,
      225 * scale,
    )
    ..close();

  canvas.drawPath(
    cheese,
    Paint()
      ..color =
          const Color(0xFFFFD447),
  );

  final pepperoni = [
    const Offset(110, 105),
    const Offset(150, 96),
    const Offset(190, 110),
    const Offset(125, 145),
    const Offset(175, 150),
    const Offset(150, 185),
    const Offset(120, 190),
    const Offset(182, 195),
  ];

  for (final p in pepperoni) {
    _circle(
      canvas,
      const Color(0xFFE84A3D),
      scale,
      p.dx,
      p.dy,
      12,
    );

    _circle(
      canvas,
      const Color(0xFFFF755F),
      scale,
      p.dx - 3,
      p.dy - 3,
      3,
    );
  }

  final olives = [
    const Offset(95, 125),
    const Offset(205, 135),
    const Offset(140, 125),
    const Offset(160, 205),
  ];

  for (final p in olives) {
    _circle(
      canvas,
      const Color(0xFF527F43),
      scale,
      p.dx,
      p.dy,
      7,
    );

    _circle(
      canvas,
      const Color(0xFF26351F),
      scale,
      p.dx,
      p.dy,
      2.5,
    );
  }

  _circle(
    canvas,
    const Color(0xFF4EAC58),
    scale,
    115,
    180,
    6,
  );

  _circle(
    canvas,
    const Color(0xFF4EAC58),
    scale,
    195,
    175,
    6,
  );
}

// ============================================================
// SCOOTER
// ============================================================

void _paintScooter(
  Canvas canvas,
  double scale,
) {
  _fill(
    canvas,
    const Color(0xFF8DDCF7),
    scale,
    0,
    0,
    300,
    300,
  );

  // Buildings.
  _fill(
    canvas,
    const Color(0xFFFFBE68),
    scale,
    0,
    55,
    65,
    150,
  );

  _fill(
    canvas,
    const Color(0xFFE98268),
    scale,
    235,
    45,
    65,
    160,
  );

  for (int y = 75;
      y <= 170;
      y += 30) {
    _fill(
      canvas,
      const Color(0xFF73D3F0),
      scale,
      12,
      y.toDouble(),
      15,
      18,
    );

    _fill(
      canvas,
      const Color(0xFF73D3F0),
      scale,
      38,
      y.toDouble(),
      15,
      18,
    );

    _fill(
      canvas,
      const Color(0xFFFFD85E),
      scale,
      248,
      y.toDouble(),
      15,
      18,
    );

    _fill(
      canvas,
      const Color(0xFFFFD85E),
      scale,
      275,
      y.toDouble(),
      15,
      18,
    );
  }

  // Road.
  _fill(
    canvas,
    const Color(0xFF50575E),
    scale,
    0,
    205,
    300,
    95,
  );

  for (int x = 0;
      x < 300;
      x += 70) {
    _fill(
      canvas,
      Colors.white,
      scale,
      x.toDouble(),
      245,
      35,
      7,
    );
  }

  // Wheels.
  _circle(
    canvas,
    const Color(0xFF20252A),
    scale,
    82,
    220,
    27,
  );

  _circle(
    canvas,
    const Color(0xFF20252A),
    scale,
    215,
    220,
    27,
  );

  _circle(
    canvas,
    const Color(0xFFD9E0E5),
    scale,
    82,
    220,
    10,
  );

  _circle(
    canvas,
    const Color(0xFFD9E0E5),
    scale,
    215,
    220,
    10,
  );

  // Scooter body.
  final body = Path()
    ..moveTo(
      70 * scale,
      185 * scale,
    )
    ..quadraticBezierTo(
      105 * scale,
      150 * scale,
      175 * scale,
      165 * scale,
    )
    ..lineTo(
      215 * scale,
      190 * scale,
    )
    ..lineTo(
      70 * scale,
      190 * scale,
    )
    ..close();

  canvas.drawPath(
    body,
    Paint()
      ..color =
          const Color(0xFFE84747),
  );

  _fill(
    canvas,
    const Color(0xFFFFCB42),
    scale,
    105,
    110,
    70,
    58,
  );

  _fill(
    canvas,
    const Color(0xFFE84747),
    scale,
    132,
    110,
    15,
    58,
  );

  _line(
    canvas,
    const Color(0xFF20252A),
    scale,
    const Offset(180, 165),
    const Offset(220, 95),
    width: 7,
  );

  _line(
    canvas,
    const Color(0xFF20252A),
    scale,
    const Offset(220, 95),
    const Offset(250, 95),
    width: 7,
  );

  _circle(
    canvas,
    const Color(0xFF343A40),
    scale,
    218,
    82,
    13,
  );

  _circle(
    canvas,
    const Color(0xFFFFF19A),
    scale,
    225,
    170,
    9,
  );
}

// ============================================================
// HOUSE
// ============================================================

void _paintHouse(
  Canvas canvas,
  double scale,
) {
  _fill(
    canvas,
    const Color(0xFF82D9F7),
    scale,
    0,
    0,
    300,
    300,
  );

  _circle(
    canvas,
    const Color(0xFFFFD34E),
    scale,
    45,
    48,
    25,
  );

  // Clouds.
  _circle(
    canvas,
    Colors.white,
    scale,
    105,
    45,
    17,
  );

  _circle(
    canvas,
    Colors.white,
    scale,
    125,
    43,
    23,
  );

  _circle(
    canvas,
    Colors.white,
    scale,
    150,
    48,
    16,
  );

  // Grass.
  _fill(
    canvas,
    const Color(0xFF63C65A),
    scale,
    0,
    190,
    300,
    110,
  );

  // Path.
  final path = Path()
    ..moveTo(
      135 * scale,
      300 * scale,
    )
    ..lineTo(
      165 * scale,
      300 * scale,
    )
    ..lineTo(
      158 * scale,
      225 * scale,
    )
    ..lineTo(
      142 * scale,
      225 * scale,
    )
    ..close();

  canvas.drawPath(
    path,
    Paint()
      ..color =
          const Color(0xFFDDB27A),
  );

  // House.
  _fill(
    canvas,
    const Color(0xFFFFD47C),
    scale,
    75,
    130,
    150,
    105,
  );

  // Roof.
  final roof = Path()
    ..moveTo(
      55 * scale,
      135 * scale,
    )
    ..lineTo(
      150 * scale,
      55 * scale,
    )
    ..lineTo(
      245 * scale,
      135 * scale,
    )
    ..close();

  canvas.drawPath(
    roof,
    Paint()
      ..color =
          const Color(0xFFE05252),
  );

  // Door.
  _fill(
    canvas,
    const Color(0xFF70452F),
    scale,
    132,
    175,
    36,
    60,
  );

  _circle(
    canvas,
    const Color(0xFFFFD34E),
    scale,
    160,
    207,
    3,
  );

  // Windows.
  _fill(
    canvas,
    const Color(0xFF67D7F0),
    scale,
    90,
    160,
    34,
    34,
  );

  _fill(
    canvas,
    const Color(0xFF67D7F0),
    scale,
    176,
    160,
    34,
    34,
  );

  for (final x in [
    107.0,
    193.0,
  ]) {
    _line(
      canvas,
      Colors.white,
      scale,
      Offset(x, 160),
      Offset(x, 194),
      width: 3,
    );
  }

  _line(
    canvas,
    Colors.white,
    scale,
    const Offset(90, 177),
    const Offset(124, 177),
    width: 3,
  );

  _line(
    canvas,
    Colors.white,
    scale,
    const Offset(176, 177),
    const Offset(210, 177),
    width: 3,
  );

  // Trees.
  for (final x in [
    40.0,
    260.0,
  ]) {
    _line(
      canvas,
      const Color(0xFF70452F),
      scale,
      Offset(x, 215),
      Offset(x, 160),
      width: 10,
    );

    _circle(
      canvas,
      const Color(0xFF42A951),
      scale,
      x - 10,
      145,
      25,
    );

    _circle(
      canvas,
      const Color(0xFF62BC57),
      scale,
      x + 12,
      145,
      25,
    );
  }
}

// ============================================================
// CAR
// ============================================================

void _paintCar(
  Canvas canvas,
  double scale,
) {
  _fill(
    canvas,
    const Color(0xFF7FD9F7),
    scale,
    0,
    0,
    300,
    300,
  );

  _circle(
    canvas,
    const Color(0xFFFFD34E),
    scale,
    245,
    48,
    27,
  );

  // Cloud.
  _circle(
    canvas,
    Colors.white,
    scale,
    45,
    60,
    18,
  );

  _circle(
    canvas,
    Colors.white,
    scale,
    68,
    58,
    25,
  );

  _circle(
    canvas,
    Colors.white,
    scale,
    95,
    63,
    17,
  );

  // Road.
  _fill(
    canvas,
    const Color(0xFF50575E),
    scale,
    0,
    195,
    300,
    105,
  );

  for (int x = 0;
      x < 300;
      x += 65) {
    _fill(
      canvas,
      Colors.white,
      scale,
      x.toDouble(),
      245,
      35,
      7,
    );
  }

  // Car body.
  final body = Path()
    ..moveTo(
      48 * scale,
      205 * scale,
    )
    ..lineTo(
      78 * scale,
      150 * scale,
    )
    ..quadraticBezierTo(
      95 * scale,
      130 * scale,
      125 * scale,
      130 * scale,
    )
    ..lineTo(
      190 * scale,
      130 * scale,
    )
    ..quadraticBezierTo(
      215 * scale,
      132 * scale,
      235 * scale,
      165 * scale,
    )
    ..lineTo(
      255 * scale,
      205 * scale,
    )
    ..close();

  canvas.drawPath(
    body,
    Paint()
      ..color =
          const Color(0xFF3D8FE8),
  );

  // Windows.
  final glass =
      Paint()
        ..color =
            const Color(0xFFB9F1FA);

  final leftWindow = Path()
    ..moveTo(
      105 * scale,
      140 * scale,
    )
    ..lineTo(
      145 * scale,
      140 * scale,
    )
    ..lineTo(
      145 * scale,
      174 * scale,
    )
    ..lineTo(
      90 * scale,
      174 * scale,
    )
    ..close();

  canvas.drawPath(
    leftWindow,
    glass,
  );

  final rightWindow = Path()
    ..moveTo(
      152 * scale,
      140 * scale,
    )
    ..lineTo(
      188 * scale,
      140 * scale,
    )
    ..lineTo(
      215 * scale,
      174 * scale,
    )
    ..lineTo(
      152 * scale,
      174 * scale,
    )
    ..close();

  canvas.drawPath(
    rightWindow,
    glass,
  );

  // Wheels.
  for (final x in [
    90.0,
    210.0,
  ]) {
    _circle(
      canvas,
      const Color(0xFF20252A),
      scale,
      x,
      210,
      26,
    );

    _circle(
      canvas,
      const Color(0xFFD5DCE1),
      scale,
      x,
      210,
      10,
    );
  }

  _circle(
    canvas,
    const Color(0xFFFFF19A),
    scale,
    244,
    185,
    8,
  );

  _circle(
    canvas,
    const Color(0xFFFFF19A),
    scale,
    56,
    185,
    8,
  );
}

// ============================================================
// CAT
// ============================================================

void _paintCat(
  Canvas canvas,
  double scale,
) {
  _fill(
    canvas,
    const Color(0xFFD9C4FF),
    scale,
    0,
    0,
    300,
    300,
  );

  // Floor.
  _fill(
    canvas,
    const Color(0xFFD19A6A),
    scale,
    0,
    200,
    300,
    100,
  );

  // Window.
  _fill(
    canvas,
    const Color(0xFF6ED5F4),
    scale,
    25,
    35,
    75,
    90,
  );

  _line(
    canvas,
    Colors.white,
    scale,
    const Offset(62, 35),
    const Offset(62, 125),
    width: 4,
  );

  _line(
    canvas,
    Colors.white,
    scale,
    const Offset(25, 80),
    const Offset(100, 80),
    width: 4,
  );

  // Tail.
  final tail = Path()
    ..moveTo(
      205 * scale,
      205 * scale,
    )
    ..cubicTo(
      270 * scale,
      215 * scale,
      265 * scale,
      140 * scale,
      225 * scale,
      150 * scale,
    );

  canvas.drawPath(
    tail,
    Paint()
      ..color =
          const Color(0xFFFFB34F)
      ..style =
          PaintingStyle.stroke
      ..strokeWidth =
          18 * scale
      ..strokeCap =
          StrokeCap.round,
  );

  // Body.
  canvas.drawOval(
    Rect.fromLTWH(
      75 * scale,
      205 * scale,
      160 * scale,
      65 * scale,
    ),
    Paint()
      ..color =
          const Color(0xFFFFB34F),
  );

  // Head.
  _circle(
    canvas,
    const Color(0xFFFFB34F),
    scale,
    150,
    130,
    65,
  );

  // Ears.
  final leftEar = Path()
    ..moveTo(
      100 * scale,
      110 * scale,
    )
    ..lineTo(
      112 * scale,
      65 * scale,
    )
    ..lineTo(
      140 * scale,
      105 * scale,
    )
    ..close();

  final rightEar = Path()
    ..moveTo(
      160 * scale,
      105 * scale,
    )
    ..lineTo(
      188 * scale,
      65 * scale,
    )
    ..lineTo(
      200 * scale,
      110 * scale,
    )
    ..close();

  canvas.drawPath(
    leftEar,
    Paint()
      ..color =
          const Color(0xFFFFB34F),
  );

  canvas.drawPath(
    rightEar,
    Paint()
      ..color =
          const Color(0xFFFFB34F),
  );

  // Eyes.
  _circle(
    canvas,
    const Color(0xFF253238),
    scale,
    128,
    125,
    8,
  );

  _circle(
    canvas,
    const Color(0xFF253238),
    scale,
    172,
    125,
    8,
  );

  _circle(
    canvas,
    const Color(0xFFE96B7B),
    scale,
    150,
    150,
    7,
  );

  // Collar.
  _fill(
    canvas,
    const Color(0xFFE85D6A),
    scale,
    115,
    182,
    70,
    12,
  );

  _circle(
    canvas,
    const Color(0xFFFFD34E),
    scale,
    150,
    194,
    6,
  );

  // Ball.
  _circle(
    canvas,
    const Color(0xFFEA5B5B),
    scale,
    55,
    230,
    18,
  );

  _line(
    canvas,
    Colors.white,
    scale,
    const Offset(44, 230),
    const Offset(66, 230),
    width: 3,
  );
}

// ============================================================
// DONUT
// ============================================================

void _paintDonut(
  Canvas canvas,
  double scale,
) {
  _fill(
    canvas,
    const Color(0xFFFFD1E5),
    scale,
    0,
    0,
    300,
    300,
  );

  _fill(
    canvas,
    const Color(0xFFD59B68),
    scale,
    0,
    205,
    300,
    95,
  );

  // Donut shadow.
  _circle(
    canvas,
    const Color(0xFFB66F46),
    scale,
    140,
    148,
    82,
  );

  // Donut base.
  _circle(
    canvas,
    const Color(0xFFE0A05B),
    scale,
    140,
    137,
    80,
  );

  // Pink icing.
  _circle(
    canvas,
    const Color(0xFFFF72A8),
    scale,
    140,
    130,
    64,
  );

  // Hole.
  _circle(
    canvas,
    const Color(0xFFD59B68),
    scale,
    140,
    130,
    25,
  );

  final sprinkleColors = [
    const Color(0xFF53B6E8),
    const Color(0xFFFFD33F),
    const Color(0xFF69C86B),
    const Color(0xFFE85A6C),
  ];

  final sprinkles = [
    const Offset(90, 105),
    const Offset(120, 82),
    const Offset(165, 90),
    const Offset(188, 115),
    const Offset(185, 150),
    const Offset(160, 175),
    const Offset(115, 172),
    const Offset(88, 145),
  ];

  for (int i = 0;
      i < sprinkles.length;
      i++) {
    final p =
        sprinkles[i];

    _line(
      canvas,
      sprinkleColors[
          i % sprinkleColors.length],
      scale,
      Offset(
        p.dx - 5,
        p.dy - 2,
      ),
      Offset(
        p.dx + 5,
        p.dy + 2,
      ),
      width: 5,
    );
  }

  // Plate highlight.
  canvas.drawOval(
    Rect.fromLTWH(
      35 * scale,
      195 * scale,
      210 * scale,
      55 * scale,
    ),
    Paint()
      ..color =
          const Color(0xFFE9EEF0),
  );
}

// ============================================================
// APPLE
// ============================================================

void _paintApple(
  Canvas canvas,
  double scale,
) {
  // Background
  _fill(
    canvas,
    const Color(0xFFFFE0E6),
    scale,
    0,
    0,
    300,
    300,
  );

  // Apple body
  final applePath = Path()
    ..moveTo(150 * scale, 115 * scale)
    ..cubicTo(
      115 * scale, 75 * scale,
      65 * scale, 100 * scale,
      65 * scale, 155 * scale,
    )
    ..cubicTo(
      65 * scale, 205 * scale,
      115 * scale, 250 * scale,
      150 * scale, 225 * scale,
    )
    ..cubicTo(
      185 * scale, 250 * scale,
      235 * scale, 205 * scale,
      235 * scale, 155 * scale,
    )
    ..cubicTo(
      235 * scale, 100 * scale,
      185 * scale, 75 * scale,
      150 * scale, 115 * scale,
    )
    ..close();

  canvas.drawPath(
    applePath,
    Paint()..color = const Color(0xFFE53935),
  );

  // Stem
  _line(
    canvas,
    const Color(0xFF654321),
    scale,
    const Offset(150, 112),
    const Offset(155, 82),
    width: 9,
  );

  // Leaf
  final leafPath = Path()
    ..moveTo(153 * scale, 95 * scale)
    ..quadraticBezierTo(
      175 * scale, 55 * scale,
      205 * scale, 78 * scale,
    )
    ..quadraticBezierTo(
      185 * scale, 105 * scale,
      153 * scale, 95 * scale,
    )
    ..close();

  canvas.drawPath(
    leafPath,
    Paint()..color = const Color(0xFF43A047),
  );

  // Highlight
  canvas.drawOval(
    Rect.fromLTWH(
      90 * scale,
      125 * scale,
      18 * scale,
      42 * scale,
    ),
    Paint()..color = const Color(0xFFFF8A80),
  );
}
// ============================================================
// FOOTBALL
// ============================================================

void _paintFootball(
  Canvas canvas,
  double scale,
) {
  _fill(
    canvas,
    const Color(0xFF7FD9F4),
    scale,
    0,
    0,
    300,
    300,
  );

  _fill(
    canvas,
    const Color(0xFF68717A),
    scale,
    0,
    65,
    300,
    80,
  );

  // Stadium lights/flags.
  for (int i = 0; i < 10; i++) {
    _circle(
      canvas,
      i.isEven
          ? const Color(0xFFFF5F61)
          : const Color(0xFFFFD34E),
      scale,
      15 + i * 30,
      90,
      8,
    );
  }

  // Grass.
  _fill(
    canvas,
    const Color(0xFF43B85A),
    scale,
    0,
    145,
    300,
    155,
  );

  final fieldPaint =
      Paint()
        ..color =
            Colors.white
                .withValues(
          alpha: 0.9,
        )
        ..style =
            PaintingStyle.stroke
        ..strokeWidth =
            3 * scale;

  canvas.drawRect(
    Rect.fromLTWH(
      15 * scale,
      155 * scale,
      270 * scale,
      135 * scale,
    ),
    fieldPaint,
  );

  canvas.drawCircle(
    Offset(
      150 * scale,
      222 * scale,
    ),
    35 * scale,
    fieldPaint,
  );

  _line(
    canvas,
    Colors.white,
    scale,
    const Offset(150, 155),
    const Offset(150, 290),
    width: 3,
  );

  // Goal.
  _line(
    canvas,
    Colors.white,
    scale,
    const Offset(105, 165),
    const Offset(195, 165),
    width: 6,
  );

  _line(
    canvas,
    Colors.white,
    scale,
    const Offset(105, 165),
    const Offset(105, 205),
    width: 6,
  );

  _line(
    canvas,
    Colors.white,
    scale,
    const Offset(195, 165),
    const Offset(195, 205),
    width: 6,
  );

  // Ball.
  _circle(
    canvas,
    Colors.white,
    scale,
    150,
    220,
    48,
  );

  final path =
      Path();

  const radius = 17.0;

  for (int i = 0;
      i < 5;
      i++) {
    final angle =
        -pi / 2 +
            (2 * pi * i / 5);

    final x =
        150 +
            radius *
                cos(angle);

    final y =
        220 +
            radius *
                sin(angle);

    if (i == 0) {
      path.moveTo(
        x * scale,
        y * scale,
      );
    } else {
      path.lineTo(
        x * scale,
        y * scale,
      );
    }
  }

  path.close();

  canvas.drawPath(
    path,
    Paint()
      ..color =
          const Color(0xFF20252A),
  );
}

// ============================================================
// TEDDY
// ============================================================

void _paintTeddy(
  Canvas canvas,
  double scale,
) {
  _fill(
    canvas,
    const Color(0xFFFFE0A9),
    scale,
    0,
    0,
    300,
    300,
  );

  _fill(
    canvas,
    const Color(0xFFBD8B61),
    scale,
    0,
    210,
    300,
    90,
  );

  // Gift/background.
  _fill(
    canvas,
    const Color(0xFF8DD8EF),
    scale,
    25,
    30,
    75,
    65,
  );

  _fill(
    canvas,
    const Color(0xFFFFD34E),
    scale,
    35,
    40,
    55,
    45,
  );

  // Teddy ears.
  _circle(
    canvas,
    const Color(0xFFB9783F),
    scale,
    105,
    90,
    31,
  );

  _circle(
    canvas,
    const Color(0xFFB9783F),
    scale,
    195,
    90,
    31,
  );

  _circle(
    canvas,
    const Color(0xFFD89B61),
    scale,
    105,
    90,
    17,
  );

  _circle(
    canvas,
    const Color(0xFFD89B61),
    scale,
    195,
    90,
    17,
  );

  // Body.
  canvas.drawOval(
    Rect.fromLTWH(
      90 * scale,
      125 * scale,
      120 * scale,
      110 * scale,
    ),
    Paint()
      ..color =
          const Color(0xFFB9783F),
  );

  // Head.
  _circle(
    canvas,
    const Color(0xFFB9783F),
    scale,
    150,
    125,
    68,
  );

  // Muzzle.
  _circle(
    canvas,
    const Color(0xFFD9A16B),
    scale,
    150,
    150,
    28,
  );

  // Eyes.
  _circle(
    canvas,
    const Color(0xFF39251A),
    scale,
    126,
    120,
    7,
  );

  _circle(
    canvas,
    const Color(0xFF39251A),
    scale,
    174,
    120,
    7,
  );

  _circle(
    canvas,
    const Color(0xFF39251A),
    scale,
    150,
    150,
    8,
  );

  // Bow.
  final bow =
      Paint()
        ..color =
            const Color(0xFFE65367);

  canvas.drawOval(
    Rect.fromLTWH(
      150 * scale,
      185 * scale,
      35 * scale,
      28 * scale,
    ),
    bow,
  );

  canvas.drawOval(
    Rect.fromLTWH(
      115 * scale,
      185 * scale,
      35 * scale,
      28 * scale,
    ),
    bow,
  );

  _circle(
    canvas,
    const Color(0xFFFFD34E),
    scale,
    150,
    199,
    8,
  );
}

// ============================================================
// FLOWER
// ============================================================

void _paintFlower(
  Canvas canvas,
  double scale,
) {
  _fill(
    canvas,
    const Color(0xFF91DDF6),
    scale,
    0,
    0,
    300,
    300,
  );

  _circle(
    canvas,
    const Color(0xFFFFD34E),
    scale,
    250,
    45,
    27,
  );

  // Clouds.
  _circle(
    canvas,
    Colors.white,
    scale,
    50,
    55,
    18,
  );

  _circle(
    canvas,
    Colors.white,
    scale,
    75,
    50,
    25,
  );

  _circle(
    canvas,
    Colors.white,
    scale,
    102,
    58,
    16,
  );

  // Grass.
  _fill(
    canvas,
    const Color(0xFF60C45A),
    scale,
    0,
    170,
    300,
    130,
  );

  // Main stem.
  _line(
    canvas,
    const Color(0xFF3F964A),
    scale,
    const Offset(150, 155),
    const Offset(150, 285),
    width: 12,
  );

  // Leaves.
  final leafPaint =
      Paint()
        ..color =
            const Color(0xFF3FA64D);

  final leftLeaf = Path()
    ..moveTo(
      150 * scale,
      225 * scale,
    )
    ..quadraticBezierTo(
      105 * scale,
      205 * scale,
      90 * scale,
      225 * scale,
    )
    ..quadraticBezierTo(
      120 * scale,
      245 * scale,
      150 * scale,
      225 * scale,
    )
    ..close();

  canvas.drawPath(
    leftLeaf,
    leafPaint,
  );

  final rightLeaf = Path()
    ..moveTo(
      150 * scale,
      245 * scale,
    )
    ..quadraticBezierTo(
      195 * scale,
      220 * scale,
      215 * scale,
      245 * scale,
    )
    ..quadraticBezierTo(
      180 * scale,
      260 * scale,
      150 * scale,
      245 * scale,
    )
    ..close();

  canvas.drawPath(
    rightLeaf,
    leafPaint,
  );

  // Flower petals.
  const centerX = 150.0;
  const centerY = 125.0;

  final petalColors = [
    const Color(0xFFFF5F9C),
    const Color(0xFFFF79AA),
    const Color(0xFFFF69A2),
    const Color(0xFFFF91B9),
  ];

  for (int i = 0;
      i < 10;
      i++) {
    final angle =
        2 * pi * i / 10;

    final x =
        centerX +
            52 * cos(angle);

    final y =
        centerY +
            52 * sin(angle);

    canvas.drawOval(
      Rect.fromCenter(
        center:
            Offset(
          x * scale,
          y * scale,
        ),
        width:
            70 * scale,
        height:
            48 * scale,
      ),
      Paint()
        ..color =
            petalColors[
                i %
                    petalColors.length],
    );
  }

  _circle(
    canvas,
    const Color(0xFFFFD34E),
    scale,
    centerX,
    centerY,
    36,
  );

  // Small flowers.
  for (final p in [
    const Offset(45, 220),
    const Offset(255, 210),
    const Offset(65, 275),
    const Offset(235, 275),
  ]) {
    _line(
      canvas,
      const Color(0xFF3F964A),
      scale,
      Offset(
        p.dx,
        p.dy,
      ),
      Offset(
        p.dx,
        p.dy + 25,
      ),
      width: 4,
    );

    _circle(
      canvas,
      const Color(0xFFFFA8C8),
      scale,
      p.dx,
      p.dy,
      10,
    );

    _circle(
      canvas,
      const Color(0xFFFFD34E),
      scale,
      p.dx,
      p.dy,
      4,
    );
  }
}

// ============================================================
// GIFT
// ============================================================

void _paintGift(
  Canvas canvas,
  double scale,
) {
  _fill(
    canvas,
    const Color(0xFFE1CCFF),
    scale,
    0,
    0,
    300,
    300,
  );

  _fill(
    canvas,
    const Color(0xFFC79C70),
    scale,
    0,
    215,
    300,
    85,
  );

  // Confetti.
  final confetti = [
    const Offset(20, 30),
    const Offset(55, 90),
    const Offset(95, 35),
    const Offset(145, 25),
    const Offset(205, 50),
    const Offset(260, 30),
    const Offset(285, 100),
    const Offset(30, 155),
    const Offset(270, 170),
  ];

  final confettiColors = [
    const Color(0xFFE65367),
    const Color(0xFFFFD34E),
    const Color(0xFF55A9D9),
    const Color(0xFF6CC36C),
  ];

  for (int i = 0;
      i < confetti.length;
      i++) {
    final p =
        confetti[i];

    _line(
      canvas,
      confettiColors[
          i % confettiColors.length],
      scale,
      Offset(
        p.dx - 4,
        p.dy - 5,
      ),
      Offset(
        p.dx + 4,
        p.dy + 5,
      ),
      width: 5,
    );
  }

  // Balloons.
  final balloons = [
    (
      35.0,
      155.0,
      const Color(0xFFE65367),
    ),
    (
      75.0,
      135.0,
      const Color(0xFFFFD34E),
    ),
    (
      245.0,
      140.0,
      const Color(0xFF5FA8D8),
    ),
    (
      275.0,
      165.0,
      const Color(0xFF6CC36C),
    ),
  ];

  for (final b in balloons) {
    canvas.drawOval(
      Rect.fromCenter(
        center:
            Offset(
          b.$1 * scale,
          b.$2 * scale,
        ),
        width:
            45 * scale,
        height:
            58 * scale,
      ),
      Paint()
        ..color = b.$3,
    );

    _line(
      canvas,
      const Color(0xFF555555),
      scale,
      Offset(
        b.$1,
        b.$2 + 29,
      ),
      Offset(
        b.$1,
        230,
      ),
      width: 2,
    );
  }

  // Gift shadow.
  canvas.drawRect(
    Rect.fromLTWH(
      70 * scale,
      170 * scale,
      160 * scale,
      65 * scale,
    ),
    Paint()
      ..color =
          const Color(0x55333333),
  );

  // Gift box.
  _fill(
    canvas,
    const Color(0xFFE94E67),
    scale,
    70,
    120,
    160,
    110,
  );

  _fill(
    canvas,
    const Color(0xFFD63E57),
    scale,
    70,
    160,
    160,
    10,
  );

  // Ribbon.
  _fill(
    canvas,
    const Color(0xFFFFD34E),
    scale,
    137,
    105,
    26,
    125,
  );

  _fill(
    canvas,
    const Color(0xFFFFD34E),
    scale,
    60,
    118,
    180,
    20,
  );

  // Bow.
  canvas.drawOval(
    Rect.fromLTWH(
      105 * scale,
      70 * scale,
      55 * scale,
      48 * scale,
    ),
    Paint()
      ..color =
          const Color(0xFFFFD34E),
  );

  canvas.drawOval(
    Rect.fromLTWH(
      150 * scale,
      70 * scale,
      55 * scale,
      48 * scale,
    ),
    Paint()
      ..color =
          const Color(0xFFFFD34E),
  );

  _circle(
    canvas,
    const Color(0xFFFFB81F),
    scale,
    150,
    98,
    13,
  );

  // Decorative dots.
  for (final p in [
    const Offset(92, 145),
    const Offset(198, 145),
    const Offset(100, 195),
    const Offset(200, 195),
  ]) {
    _circle(
      canvas,
      const Color(0xFFFFA0AE),
      scale,
      p.dx,
      p.dy,
      5,
    );
  }
}