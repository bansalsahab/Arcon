import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class Skeleton {
  static Widget box({double height = 12, double? width, double radius = 8}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }

  static Widget line({double width = double.infinity}) => box(height: 12, width: width);

  static Widget tile({double height = 56}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        height: height,
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  static List<Widget> tiles(int n, {double height = 56}) =>
      List.generate(n, (_) => tile(height: height));
}
