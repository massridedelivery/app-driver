const _dir = 'assets/images/icons/vehicles';

/// The Mass 3D icon for a trip, same set and mapping as the customer app:
/// food / messenger by service, rides by the job's vehicle type name
/// (`driver_info.vehicle_type_name`, e.g. "motorcycle", "premium").
String serviceIconAsset({String? service, String? vehicleTypeName}) {
  switch (service?.toLowerCase()) {
    case 'food':
      return '$_dir/ic3d_food.png';
    case 'messenger':
      return '$_dir/ic3d_messenger.png';
  }
  final n = (vehicleTypeName ?? '').toLowerCase();
  if (n.isEmpty) return '$_dir/ic3d_ride.png';
  if (n.contains('bike') || n.contains('motorcycle')) {
    return '$_dir/ic_car_scooter.png';
  }
  if (n.contains('luxury')) return '$_dir/ic_car_luxury.png';
  if (n.contains('premium')) return '$_dir/ic_car_premium.png';
  if (n.contains('xl') ||
      n.contains('van') ||
      n.contains('suv') ||
      n.contains('6')) {
    return '$_dir/ic_car_xl.png';
  }
  if (n.contains('comfort')) return '$_dir/ic_car_comfort.png';
  if (n.contains('tuk')) return '$_dir/ic_car_tuktuk.png';
  // economy / saver / taxi and anything else → the sedan.
  return '$_dir/ic_car_economy.png';
}

/// Thai name for the card title ("มอเตอร์ไซค์ · งาน #03d8f5"), from the same
/// inputs as [serviceIconAsset].
String serviceLabel({String? service, String? vehicleTypeName}) {
  switch (service?.toLowerCase()) {
    case 'food':
      return 'ส่งอาหาร';
    case 'messenger':
      return 'ส่งพัสดุ';
  }
  final n = (vehicleTypeName ?? '').toLowerCase();
  if (n.isEmpty) return 'เรียกรถ';
  if (n.contains('bike') || n.contains('motorcycle')) return 'มอเตอร์ไซค์';
  if (n.contains('taxi')) return 'แท็กซี่';
  if (n.contains('tuk')) return 'ตุ๊กตุ๊ก';
  if (n.contains('luxury')) return 'รถหรู';
  if (n.contains('premium')) return 'รถพรีเมียม';
  if (n.contains('xl') ||
      n.contains('van') ||
      n.contains('suv') ||
      n.contains('6')) {
    return 'รถ 6 ที่นั่ง';
  }
  return 'รถยนต์';
}
