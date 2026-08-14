import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Builds the map pins so the driver app matches the customer app's ride flow:
/// a tinted teardrop (`ic_location_fill.svg`) with a white "hole" — green for
/// pickup, red for dropoff — instead of Google's default hue markers. Ported
/// from customer-app `lib/core/utils/map_marker_utils.dart` so both apps read
/// as one product.
class MapMarkerUtils {
  MapMarkerUtils._();

  static const Color _pickupColor = Color(0xFF24A12F); // green
  static const Color _dropoffColor = Color(0xFFE11E3F); // red
  static const Color _restaurantColor = Color(0xFFB25E1C); // brown/orange

  /// Logical size of the pin on screen, and the raster upscale used so it
  /// stays crisp on high-density displays.
  static const double _pinDisplaySize = 44;
  static const double _pinRasterScale = 3;

  static Future<BitmapDescriptor> createPickupMarker() =>
      _createCompositeMarker(backgroundColor: _pickupColor);

  static Future<BitmapDescriptor> createDropoffMarker() =>
      _createCompositeMarker(backgroundColor: _dropoffColor);

  /// Brown/orange pin for a food-order restaurant (the pickup point in the food
  /// flow, distinct from the green passenger-pickup pin).
  static Future<BitmapDescriptor> createRestaurantMarker() =>
      _createCompositeMarker(backgroundColor: _restaurantColor);

  static Future<BitmapDescriptor> _createCompositeMarker({
    required Color backgroundColor,
    Color iconColor = Colors.white,
    double size = _pinDisplaySize * _pinRasterScale,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    // The SVG pin is authored at 24×24; scale the canvas up to `size`.
    final loader = SvgAssetLoader('assets/images/icons/ic_location_fill.svg');
    final pictureInfo = await vg.loadPicture(loader, null);

    final scale = size / 24.0;
    canvas.save();
    canvas.scale(scale, scale);

    // Soft shadow under the pin tip.
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 1);
    canvas.drawCircle(const Offset(12, 22), 2, shadowPaint);

    // Tint the pin shape.
    final pinPaint = ui.Paint()
      ..colorFilter = ui.ColorFilter.mode(backgroundColor, ui.BlendMode.srcIn);
    canvas.saveLayer(const ui.Rect.fromLTWH(0, 0, 24, 24), pinPaint);
    canvas.drawPicture(pictureInfo.picture);
    canvas.restore();

    // White dot in the pin's hole.
    final holePaint = Paint()..color = iconColor;
    canvas.drawCircle(const Offset(12, 11), 3.5, holePaint);
    canvas.restore();

    final image = await recorder.endRecording().toImage(
      size.toInt(),
      size.toInt(),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    pictureInfo.picture.dispose();

    if (byteData == null) return BitmapDescriptor.defaultMarker;
    return BitmapDescriptor.bytes(
      byteData.buffer.asUint8List(),
      imagePixelRatio: _pinRasterScale,
    );
  }
}
