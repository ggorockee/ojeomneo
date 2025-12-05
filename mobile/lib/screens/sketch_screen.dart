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

    final renderBox =
        _canvasKey.currentContext?.findRenderObject() as RenderBox?;
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
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            StatefulBuilder(
              builder: (context, setState) => Column(
                children: [
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: AppTheme.primaryColor,
                      inactiveTrackColor: AppTheme.dividerColor,
                      thumbColor: AppTheme.primaryColor,
                      overlayColor: AppTheme.primaryColor.withAlpha(51),
                    ),
                    child: Slider(
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
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '1',
                        style: TextStyle(color: AppTheme.onSurfaceVariant),
                      ),
                      Container(
                        width: provider.currentWidth * 2,
                        height: provider.currentWidth * 2,
                        decoration: BoxDecoration(
                          color: provider.currentColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const Text(
                        '20',
                        style: TextStyle(color: AppTheme.onSurfaceVariant),
                      ),
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
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '내 기분 그리기',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.onSurface,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, color: AppTheme.onSurfaceVariant),
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
                child: Column(
                  children: [
                    // Canvas area
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final canvasSize = Size(
                              constraints.maxWidth,
                              constraints.maxHeight,
                            );
                            return Container(
                              key: _canvasKey,
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceVariant,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppTheme.outlineColor,
                                  width: 1,
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: provider.hasDrawing
                                  ? SketchCanvas(size: canvasSize)
                                  : _EmptyCanvasPlaceholder(
                                      onTap: () {},
                                      child: SketchCanvas(size: canvasSize),
                                    ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Text input
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.edit_note_rounded,
                              color: AppTheme.textHint,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _textController,
                                decoration: const InputDecoration(
                                  hintText: '지금 기분을 한 줄로 표현해보세요 (선택)',
                                  hintStyle: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.textHint,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                  filled: false,
                                ),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.onSurface,
                                ),
                                maxLines: 1,
                                textInputAction: TextInputAction.done,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tool bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Color picker
                          _ToolButton(
                            icon: Icons.palette_rounded,
                            color: provider.currentColor,
                            isActive: true,
                            onTap: _showColorPicker,
                            tooltip: '색상',
                          ),
                          const SizedBox(width: 8),

                          // Stroke width
                          _ToolButton(
                            icon: Icons.line_weight_rounded,
                            onTap: _showStrokeWidthPicker,
                            tooltip: '굵기',
                          ),
                          const SizedBox(width: 8),

                          // Undo
                          _ToolButton(
                            icon: Icons.undo_rounded,
                            onTap:
                                provider.hasDrawing ? provider.undoLastStroke : null,
                            tooltip: '되돌리기',
                          ),
                          const SizedBox(width: 8),

                          // Clear
                          _ToolButton(
                            icon: Icons.delete_outline_rounded,
                            onTap: provider.hasDrawing ? provider.clearCanvas : null,
                            tooltip: '지우기',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Analyze button
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                      child: _GradientButton(
                        onPressed: isAnalyzing ? null : _analyzeSketch,
                        isEnabled: provider.hasDrawing && !isAnalyzing,
                        isLoading: isAnalyzing,
                        label: isAnalyzing ? '분석 중...' : '메뉴 추천받기',
                        icon: isAnalyzing ? null : Icons.auto_awesome_rounded,
                      ),
                    ),
                  ],
                ),
              ),

              // Loading overlay
              if (isAnalyzing) _LoadingOverlay(),
            ],
          );
        },
      ),
    );
  }
}

class _EmptyCanvasPlaceholder extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;

  const _EmptyCanvasPlaceholder({
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.gesture_rounded,
                    size: 48,
                    color: AppTheme.textDisabled.withAlpha(128),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '여기에 기분을 그려주세요',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppTheme.textHint.withAlpha(180),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final bool isActive;
  final VoidCallback? onTap;
  final String tooltip;

  const _ToolButton({
    required this.icon,
    this.color,
    this.isActive = false,
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
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isActive
                  ? AppTheme.toolButtonActive
                  : (isEnabled
                      ? AppTheme.toolButtonInactive
                      : AppTheme.toolButtonInactive.withAlpha(128)),
              borderRadius: BorderRadius.circular(14),
              border: color != null ? Border.all(color: color!, width: 2) : null,
            ),
            child: Icon(
              icon,
              color: isActive
                  ? Colors.white
                  : (isEnabled
                      ? (color ?? AppTheme.onSurfaceVariant)
                      : AppTheme.textDisabled),
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isEnabled;
  final bool isLoading;
  final String label;
  final IconData? icon;

  const _GradientButton({
    this.onPressed,
    required this.isEnabled,
    this.isLoading = false,
    required this.label,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isEnabled ? onPressed : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: isEnabled ? AppTheme.primaryGradient : null,
          color: isEnabled ? null : AppTheme.buttonDisabled,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isEnabled ? AppTheme.primaryButtonShadow : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            else if (icon != null) ...[
              Icon(
                icon,
                size: 20,
                color: isEnabled ? Colors.white : AppTheme.textHint,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isEnabled ? Colors.white : AppTheme.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withAlpha(77),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppTheme.softShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppTheme.primaryColor,
                  ),
                  backgroundColor: AppTheme.dividerColor,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '그림을 분석하고 있어요...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                '잠시만 기다려주세요',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
