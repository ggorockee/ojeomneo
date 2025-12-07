import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '펜 굵기',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurface,
              ),
            ),
            SizedBox(height: 16.h),
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
                      Text(
                        '1',
                        style: TextStyle(
                          color: AppTheme.onSurfaceVariant,
                          fontSize: 14.sp,
                        ),
                      ),
                      Container(
                        width: (provider.currentWidth * 2).w,
                        height: (provider.currentWidth * 2).w,
                        decoration: BoxDecoration(
                          color: provider.currentColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Text(
                        '20',
                        style: TextStyle(
                          color: AppTheme.onSurfaceVariant,
                          fontSize: 14.sp,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
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
        title: Text(
          '내 기분 그리기',
          style: TextStyle(
            fontSize: 18.sp,
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
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
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
                                borderRadius: BorderRadius.circular(20.r),
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
                    SizedBox(height: 16.h),

                    // Text input
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 18.w,
                          vertical: 14.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit_note_rounded,
                              color: AppTheme.textHint,
                              size: 20.sp,
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: TextField(
                                controller: _textController,
                                decoration: InputDecoration(
                                  hintText: '지금 기분을 한 줄로 표현해보세요 (선택)',
                                  hintStyle: TextStyle(
                                    fontSize: 14.sp,
                                    color: AppTheme.textHint,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                  filled: false,
                                ),
                                style: TextStyle(
                                  fontSize: 14.sp,
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
                    SizedBox(height: 16.h),

                    // Tool bar
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
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
                          SizedBox(width: 8.w),

                          // Stroke width
                          _ToolButton(
                            icon: Icons.line_weight_rounded,
                            onTap: _showStrokeWidthPicker,
                            tooltip: '굵기',
                          ),
                          SizedBox(width: 8.w),

                          // Undo
                          _ToolButton(
                            icon: Icons.undo_rounded,
                            onTap:
                                provider.hasDrawing ? provider.undoLastStroke : null,
                            tooltip: '되돌리기',
                          ),
                          SizedBox(width: 8.w),

                          // Clear
                          _ToolButton(
                            icon: Icons.delete_outline_rounded,
                            onTap: provider.hasDrawing ? provider.clearCanvas : null,
                            tooltip: '지우기',
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Analyze button
                    Padding(
                      padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 40.h),
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
                    size: 48.sp,
                    color: AppTheme.textDisabled.withAlpha(128),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    '여기에 기분을 그려주세요',
                    style: TextStyle(
                      fontSize: 15.sp,
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
          borderRadius: BorderRadius.circular(14.r),
          child: Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              color: isActive
                  ? AppTheme.toolButtonActive
                  : (isEnabled
                      ? AppTheme.toolButtonInactive
                      : AppTheme.toolButtonInactive.withAlpha(128)),
              borderRadius: BorderRadius.circular(14.r),
              border: color != null ? Border.all(color: color!, width: 2) : null,
            ),
            child: Icon(
              icon,
              color: isActive
                  ? Colors.white
                  : (isEnabled
                      ? (color ?? AppTheme.onSurfaceVariant)
                      : AppTheme.textDisabled),
              size: 22.sp,
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
        padding: EdgeInsets.symmetric(vertical: 18.h),
        decoration: BoxDecoration(
          gradient: isEnabled ? AppTheme.primaryGradient : null,
          color: isEnabled ? null : AppTheme.buttonDisabled,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              SizedBox(
                width: 20.w,
                height: 20.w,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            else if (icon != null) ...[
              Icon(
                icon,
                size: 20.sp,
                color: isEnabled ? Colors.white : AppTheme.textHint,
              ),
              SizedBox(width: 8.w),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 16.sp,
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
          padding: EdgeInsets.symmetric(horizontal: 48.w, vertical: 32.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: AppTheme.softShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 48.w,
                height: 48.w,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppTheme.primaryColor,
                  ),
                  backgroundColor: AppTheme.dividerColor,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                '그림을 분석하고 있어요...',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurface,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                '잠시만 기다려주세요',
                style: TextStyle(
                  fontSize: 14.sp,
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
