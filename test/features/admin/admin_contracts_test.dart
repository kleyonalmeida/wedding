import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:wedding_app/core/network/api_client.dart';
import 'package:wedding_app/features/admin/data/models/audit_log.dart';
import 'package:wedding_app/features/admin/data/models/product.dart';
import 'package:wedding_app/features/admin/data/repositories/attendance_repository.dart';
import 'package:wedding_app/features/admin/data/repositories/product_repository.dart';
import 'package:wedding_app/features/admin/data/repositories/settings_repository.dart';
import 'package:wedding_app/features/admin/presentation/admin_route.dart';
import 'package:wedding_app/features/admin/presentation/attendance/admin_attendance_detail_page.dart';
import 'package:wedding_app/features/admin/presentation/attendance/admin_attendance_page.dart';
import 'package:wedding_app/features/admin/presentation/audit/admin_audit_detail_page.dart';
import 'package:wedding_app/features/admin/presentation/products/admin_product_form_page.dart';
import 'package:wedding_app/features/admin/presentation/products/admin_products_page.dart';

void main() {
  test('rotas de detalhe e criação preservam o identificador', () {
    expect(resolveAdminPage('/admin/presenca/abc'),
        isA<AdminAttendanceDetailPage>());
    expect(
        (resolveAdminPage('/admin/presenca/abc') as AdminAttendanceDetailPage)
            .rsvpId,
        'abc');
    expect((resolveAdminPage('/admin/logs/def') as AdminAuditDetailPage).logId,
        'def');
    expect(
        (resolveAdminPage('/admin/produtos/novo') as AdminProductFormPage)
            .productId,
        isNull);
    expect(
        (resolveAdminPage('/admin/produtos/xyz') as AdminProductFormPage)
            .productId,
        'xyz');
  });

  test('paginação e filtros são restaurados pela URL', () {
    final attendance =
        resolveAdminPage('/admin/presenca?page=3&search=Jo%C3%A3o&status=false')
            as AdminAttendancePage;
    expect(attendance.initialPage, 3);
    expect(attendance.initialSearch, 'João');
    expect(attendance.initialStatus, false);
    final products = resolveAdminPage('/admin/produtos?page=2');
    expect((products as AdminProductsPage).initialPage, 2);
  });

  test('produto usa imagem principal retornada no detalhe', () {
    final product = Product.fromJson({
      'id': '1',
      'name': 'Presente',
      'images': [
        {'imageUrl': '/other', 'isPrimary': false},
        {'imageUrl': '/main', 'isPrimary': true},
      ],
    });
    expect(product.imageUrl, '/main');
  });

  test('log interpreta timestamp e valores JSON do backend', () {
    final log = AuditLog.fromJson({
      'id': '1',
      'timestampUtc': '2026-09-24T12:00:00Z',
      'action': 'Update',
      'entityType': 'Gift',
      'entityId': null,
      'userId': null,
      'oldValues': '{"active":true}',
      'newValues': '{"active":false}',
      'success': true,
    });
    expect(log.timestampUtc.isUtc, isTrue);
    expect(log.userId, isNull);
    expect(log.success, isTrue);
    expect(AuditLog.prettyValues(log.newValues), contains('"active": false'));
  });

  test('status envia ambos os campos; settings usa a lista exigida pela API',
      () async {
    final requests = <http.Request>[];
    final api = ApiClient(client: MockClient((request) async {
      requests.add(request);
      return http.Response('{}', 200);
    }));
    addTearDown(api.dispose);
    await ProductRepository(api)
        .patchStatus('gift', active: false, featured: true);
    await SettingsRepository(api).patch({'site_title': 'Teste'});
    expect(jsonDecode(requests[0].body), {'active': false, 'featured': true});
    expect(jsonDecode(requests[1].body), {
      'settings': [
        {'key': 'site_title', 'value': 'Teste'}
      ]
    });
  });

  test('busca de presença codifica caracteres especiais', () async {
    late Uri uri;
    final api = ApiClient(client: MockClient((request) async {
      uri = request.url;
      return http.Response(
          '{"data":[],"totalPages":0,"page":1,"total":0}', 200);
    }));
    addTearDown(api.dispose);
    await AttendanceRepository(api).list(search: 'João & Ana');
    expect(uri.queryParameters['search'], 'João & Ana');
  });

  test('erro de código MFA não derruba sessão; 401 em me derruba', () async {
    final api = ApiClient(
        client: MockClient((request) async => http.Response('', 401)));
    addTearDown(api.dispose);
    var unauthorized = 0;
    api.onUnauthorized = () => unauthorized++;
    await expectLater(
        api.post('/api/admin/auth/mfa/verify', {'code': '000000'}),
        throwsA(isA<ApiException>()));
    expect(unauthorized, 0);
    await expectLater(
        api.get('/api/admin/auth/me'), throwsA(isA<ApiException>()));
    expect(unauthorized, 1);
  });
}
