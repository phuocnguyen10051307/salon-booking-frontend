import 'package:flutter_test/flutter_test.dart';
import 'package:salon_booking_frontend/core/constants/api_constants.dart';

void main() {
  group('AppUrlConfig', () {
    test('dart-define takes precedence over development dotenv values', () {
      final url = AppUrlConfig.resolve(
        key: 'SOCKET_BASE_URL',
        dartDefine: 'https://salon-production.up.railway.app/',
        environment: const {'SOCKET_BASE_URL_ANDROID': 'http://10.0.2.2:3000'},
        isRelease: false,
        isAndroid: true,
        isSocket: true,
      );

      expect(url, 'https://salon-production.up.railway.app');
    });

    test('development Android uses the platform dotenv fallback', () {
      final url = AppUrlConfig.resolve(
        key: 'API_BASE_URL',
        dartDefine: '',
        environment: const {
          'API_BASE_URL': 'http://localhost:3000/v1',
          'API_BASE_URL_ANDROID': 'http://10.0.2.2:3000/v1/',
        },
        isRelease: false,
        isAndroid: true,
        isSocket: false,
      );

      expect(url, 'http://10.0.2.2:3000/v1');
    });

    test('empty URL fails instead of silently using a malformed fallback', () {
      expect(
        () => AppUrlConfig.resolve(
          key: 'SOCKET_BASE_URL',
          dartDefine: '',
          environment: const {},
          isRelease: false,
          isAndroid: true,
          isSocket: true,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('release requires an explicit dart-define', () {
      expect(
        () => AppUrlConfig.resolve(
          key: 'SOCKET_BASE_URL',
          dartDefine: '',
          environment: const {
            'SOCKET_BASE_URL_ANDROID': 'https://ignored.example.com',
          },
          isRelease: true,
          isAndroid: true,
          isSocket: true,
        ),
        throwsA(isA<StateError>()),
      );
    });

    for (final localUrl in const [
      'https://localhost:3000',
      'https://127.0.0.1:3000',
      'https://10.0.2.2:3000',
      'https://192.168.1.20:3000',
      'https://172.16.0.20:3000',
      'https://169.254.10.20:3000',
      'https://100.64.10.20:3000',
    ]) {
      test('release rejects local socket URL $localUrl', () {
        expect(
          () => AppUrlConfig.validate(
            localUrl,
            key: 'SOCKET_BASE_URL',
            isRelease: true,
            isSocket: true,
          ),
          throwsA(isA<StateError>()),
        );
      });
    }

    test('release rejects insecure HTTP', () {
      expect(
        () => AppUrlConfig.validate(
          'http://salon-production.up.railway.app',
          key: 'SOCKET_BASE_URL',
          isRelease: true,
          isSocket: true,
        ),
        throwsA(isA<StateError>()),
      );
    });

    for (final invalidPath in const ['/v1', '/api', '/socket.io', '/chat']) {
      test('socket origin rejects path $invalidPath', () {
        expect(
          () => AppUrlConfig.validate(
            'https://salon-production.up.railway.app$invalidPath',
            key: 'SOCKET_BASE_URL',
            isRelease: true,
            isSocket: true,
          ),
          throwsA(isA<StateError>()),
        );
      });
    }

    test('valid Railway API and socket URLs pass release validation', () {
      expect(
        AppUrlConfig.validate(
          'https://salon-production.up.railway.app/v1/',
          key: 'API_BASE_URL',
          isRelease: true,
          isSocket: false,
        ),
        'https://salon-production.up.railway.app/v1',
      );
      expect(
        AppUrlConfig.validate(
          'https://salon-production.up.railway.app/',
          key: 'SOCKET_BASE_URL',
          isRelease: true,
          isSocket: true,
        ),
        'https://salon-production.up.railway.app',
      );
    });
  });
}
