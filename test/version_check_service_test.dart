import 'package:flutter_test/flutter_test.dart';
import 'package:Checkin/core/services/version_check_service.dart';

void main() {
  test('releasesPageUrl is correct', () {
    expect(releasesPageUrl, 'https://github.com/mirarr-app/Checkin/releases');
  });
}
