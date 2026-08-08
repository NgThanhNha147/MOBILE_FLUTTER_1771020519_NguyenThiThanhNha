import 'package:flutter_test/flutter_test.dart';
import 'package:pcm_mobile/core/utils/form_validators.dart';

void main() {
  group('FormValidators.validateEmail', () {
    test('accepts a valid email', () {
      expect(FormValidators.validateEmail('nha@example.com'), isNull);
    });

    test('rejects an invalid email', () {
      expect(FormValidators.validateEmail('not-an-email'), isNotNull);
    });
  });

  group('FormValidators.validatePassword', () {
    test('accepts a strong password', () {
      expect(FormValidators.validatePassword('Portfolio@123'), isNull);
    });

    test('rejects a short password', () {
      expect(FormValidators.validatePassword('Ab1!'), isNotNull);
    });
  });

  test('validates Vietnamese phone numbers', () {
    expect(FormValidators.validatePhoneNumber('0912 345 678'), isNull);
    expect(FormValidators.validatePhoneNumber('12345'), isNotNull);
  });
}
