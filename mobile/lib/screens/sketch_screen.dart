import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';

import '../config/app_theme.dart';
import '../services/sketch_provider.dart';
import '../utils/app_messages.dart';
import '../widgets/sketch_canvas.dart';
import 'result_screen.dart';

class SketchScreen extends StatefulWidget {
  const SketchScreen({super.key});

  @override
  State<SketchScreen> createState() => _SketchScreenState();
}

class _SketchScreenState extends State<SketchScreen> {
  final TextEditingController _textController = TextEditingController();
  final GlobalKey _canvasKey = GlobalKey();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _analyzeSketch() async {
    final provider = context.read<SketchProvider>();

    if (!provider.hasDrawing) {
      _showSnackBar(AppMessages.sketchEmpty);
      return;
    }

    final renderBox = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final imageBytes = await provider.captureCanvas(renderBox.size);
    if (imageBytes == null) {
      _showSnackBar(AppMessages.imageCaptureFailed);
      return;
    }

    await provider.analyzeSketch(
      imageBytes,
      text: _textController.text.isNotEmpty ? _textController.text : null,
    );

    if (provider.state == SketchState.success && provider.result != null) {
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ResultScreen(result: provider.result!),
          ),
        );
      }
    } else if (provider.state == SketchState.error) {
      _showSnackBar(provider.errorMessage ?? AppMessages.sketchAnalyzeFailed);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showColorPicker() {
    final provider = context.read<SketchProvider>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('색상 선택'),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: provider.currentColor,
            onColorChanged: (color) {
              provider.setStrokeColor(color);
            },
            availableColors: const [
              Colors.black,
              Colors.grey,
              Colors.brown,
              Colors.red,
              Colors.orange,
              Colors.amber,
              Colors.yellow,
              Colors.lime,
              Colors.green,
              Colors.teal,
              Colors.cyan,
              Colors.blue,
              Colors.indigo,
              Colors.purple,
              Colors.pink,
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showStrokeWidthPicker() {
    final provider = context.read<SketchProvider>();

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '펜 굵기',
              style: AppTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            StatefulBuilder(
              builder: (context, setState) => Column(
                children: [
                  Slider(
                    value: provider.currentWidth,
                    min: 1,
                    max: 20,
                    divisions: 19,
                    label: provider.currentWidth.round().toString(),
                    onChanged: (value) {
                      setState(() {});
                      provider.setStrokeWidth(value);
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('1'),
                      Container(
                        width: provider.currentWidth * 2,
                        height: provider.currentWidth * 2,
                        decoration: BoxDecoration(
                          color: provider.currentColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const Text('20'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 기분 그리기'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: '히스토리',
            onPressed: () => Navigator.of(context).pushNamed('/history'),
          ),
        ],
      ),
      body: Consumer<SketchProvider>(
        builder: (context, provider, child) {
          final isAnalyzing = provider.state == SketchState.analyzing;

          return Stack(
            children: [
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Canvas area
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final canvasSize = Size(
                              constraints.maxWidth,
                              constraints.maxHeight,
                            );
                            return Container(
                              key: _canvasKey,
                              child: SketchCanvas(size: canvasSize),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Text input
                      TextField(
                        controller: _textController,
                        decoration: const InputDecoration(
                          hintText: '지금 기분을 한 줄로 표현해보세요 (선택)',
                          prefixIcon: Icon(Icons.edit_note_rounded),
                        ),
                        maxLines: 1,
                        textInputAction: TextInputAction.done,
                      ),
                      const SizedBox(height: 16),

                      // Tool bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Color picker
                          _ToolButton(
                            icon: Icons.palette_rounded,
                            color: provider.currentColor,
                            onTap: _showColorPicker,
                            tooltip: '색상',
                          ),
                          const SizedBox(width: 12),

                          // Stroke width
                          _ToolButton(
                            icon: Icons.line_weight_rounded,
                            onTap: _showStrokeWidthPicker,
                            tooltip: '굵기',
                          ),
                          const SizedBox(width: 12),

                          // Undo
                          _ToolButton(
                            icon: Icons.undo_rounded,
                            onTap: provider.hasDrawing
                                ? provider.undoLastStroke
                                : null,
                            tooltip: '되돌리기',
                          ),
                          const SizedBox(width: 12),

                          // Clear
                          _ToolButton(
                            icon: Icons.delete_outline_rounded,
                            onTap: provider.hasDrawing
                                ? provider.clearCanvas
                                : null,
                            tooltip: '지우기',
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Analyze button
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: isAnalyzing ? null : _analyzeSketch,
                          icon: isAnalyzing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.auto_awesome_rounded),
                          label: Text(isAnalyzing ? '분석 중...' : '메뉴 추천받기'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Loading overlay
              if (isAnalyzing)
                Container(
                  color: Colors.black.withAlpha(77),
                  child: Center(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 24),
                            Text(
                              '그림을 분석하고 있어요...',
                              style: AppTheme.titleMedium.copyWith(
                                color: AppTheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '잠시만 기다려주세요',
                              style: AppTheme.bodyMedium.copyWith(
                                color: AppTheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;
  final String tooltip;

  const _ToolButton({
    required this.icon,
    this.color,
    this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isEnabled
                  ? AppTheme.surfaceVariant.withAlpha(128)
                  : AppTheme.surfaceVariant.withAlpha(51),
              borderRadius: BorderRadius.circular(12),
              border: color != null
                  ? Border.all(color: color!, width: 2)
                  : null,
            ),
            child: Icon(
              icon,
              color: isEnabled
                  ? (color ?? AppTheme.onSurface)
                  : AppTheme.onSurfaceVariant.withAlpha(77),
            ),
          ),
        ),
      ),
    );
  }
}
