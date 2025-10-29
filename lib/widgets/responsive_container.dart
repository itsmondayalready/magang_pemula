import 'package:flutter/material.dart';
import '../utils/responsive.dart';

/// Widget untuk membatasi lebar konten pada layar besar (tablet/desktop)
/// agar tidak terlalu lebar dan tetap mudah dibaca
class ResponsiveContainer extends StatelessWidget {
  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth,
  });

  final Widget child;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final width = maxWidth ?? context.maxContentWidth;
    
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width),
        child: child,
      ),
    );
  }
}
