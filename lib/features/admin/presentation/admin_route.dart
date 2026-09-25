import 'package:flutter/material.dart';
import 'attendance/admin_attendance_detail_page.dart';
import 'attendance/admin_attendance_page.dart';
import 'audit/admin_audit_detail_page.dart';
import 'audit/admin_audit_page.dart';
import 'dashboard/admin_dashboard_page.dart';
import 'payments/admin_payment_detail_page.dart';
import 'payments/admin_payments_page.dart';
import 'products/admin_product_form_page.dart';
import 'products/admin_products_page.dart';
import 'security/admin_security_page.dart';
import 'settings/admin_settings_page.dart';

Widget resolveAdminPage(String path) {
  final uri = Uri.parse(path);
  path = uri.path;
  final page = int.tryParse(uri.queryParameters['page'] ?? '') ?? 1;
  final safePage = page < 1 ? 1 : page;
  if (path == '/admin' || path == '/admin/dashboard') {
    return const AdminDashboardPage();
  }
  if (path == '/admin/produtos') {
    return AdminProductsPage(initialPage: safePage);
  }
  if (path == '/admin/produtos/novo') return const AdminProductFormPage();
  if (path.startsWith('/admin/produtos/') &&
      path.length > '/admin/produtos/'.length) {
    return AdminProductFormPage(
        productId: path.substring('/admin/produtos/'.length));
  }
  if (path == '/admin/pagamentos') {
    return AdminPaymentsPage(initialPage: safePage);
  }
  if (path.startsWith('/admin/pagamentos/') &&
      path.length > '/admin/pagamentos/'.length) {
    return AdminPaymentDetailPage(
        paymentId: path.substring('/admin/pagamentos/'.length));
  }
  if (path == '/admin/presenca') {
    return AdminAttendancePage(
      initialPage: safePage,
      initialSearch: uri.queryParameters['search'],
      initialStatus: switch (uri.queryParameters['status']) {
        'true' => true,
        'false' => false,
        _ => null,
      },
    );
  }
  if (path.startsWith('/admin/presenca/') &&
      path.length > '/admin/presenca/'.length) {
    return AdminAttendanceDetailPage(
        rsvpId: path.substring('/admin/presenca/'.length));
  }
  if (path == '/admin/logs') return AdminAuditPage(initialPage: safePage);
  if (path.startsWith('/admin/logs/') && path.length > '/admin/logs/'.length) {
    return AdminAuditDetailPage(logId: path.substring('/admin/logs/'.length));
  }
  if (path == '/admin/configuracoes') return const AdminSettingsPage();
  if (path == '/admin/seguranca') return const AdminSecurityPage();
  return const Center(child: Text('Página administrativa não encontrada'));
}
