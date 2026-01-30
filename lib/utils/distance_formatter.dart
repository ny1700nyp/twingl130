/// Distance formatting used across the app.
///
/// Bucket rules (legacy):
/// - < 100m   => 100m
/// - < 500m   => 500m
/// - < 1km    => 1km
/// - < 5km    => 5km
/// - < 10km   => 10km
/// - < 20km   => 20km
/// - < 50km   => 50km
/// - < 100km  => 100km
/// - >= 100km => exact km with 1 decimal
String formatDistanceMeters(double distanceMeters) {
  if (distanceMeters < 0) return '0m';

  if (distanceMeters < 100) {
    return '100m';
  } else if (distanceMeters < 500) {
    return '500m';
  } else if (distanceMeters < 1000) {
    return '1km';
  } else if (distanceMeters < 5000) {
    return '5km';
  } else if (distanceMeters < 10000) {
    return '10km';
  } else if (distanceMeters < 20000) {
    return '20km';
  } else if (distanceMeters < 50000) {
    return '50km';
  } else if (distanceMeters < 100000) {
    return '100km';
  } else {
    return '${(distanceMeters / 1000).toStringAsFixed(1)}km';
  }
}

