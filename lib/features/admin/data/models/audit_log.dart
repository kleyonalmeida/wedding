import 'dart:convert';

class AuditLog {
  final String id;
  final String action;
  final String entityType;
  final String? entityId;
  final String? userId;
  final String description;
  final DateTime timestampUtc;
  final String? oldValues;
  final String? newValues;
  final String? ipAddress;
  final String? userAgent;
  final String? correlationId;
  final bool success;

  AuditLog({
    required this.id,
    required this.action,
    required this.entityType,
    required this.entityId,
    required this.userId,
    required this.description,
    required this.timestampUtc,
    required this.oldValues,
    required this.newValues,
    required this.ipAddress,
    required this.userAgent,
    required this.correlationId,
    required this.success,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    return AuditLog(
      id: json['id'].toString(),
      action: json['action']?.toString() ?? '',
      entityType: json['entityType']?.toString() ?? '',
      entityId: json['entityId'] as String?,
      userId: json['userId'] as String?,
      description: json['description'] as String? ?? '',
      timestampUtc: DateTime.parse(json['timestampUtc'] as String),
      oldValues: json['oldValues'] as String?,
      newValues: json['newValues'] as String?,
      ipAddress: json['ipAddress']?.toString(),
      userAgent: json['userAgent'] as String?,
      correlationId: json['correlationId'] as String?,
      success: json['success'] as bool? ?? false,
    );
  }

  static String prettyValues(String? value) {
    if (value == null || value.isEmpty) return '—';
    try {
      return const JsonEncoder.withIndent('  ').convert(jsonDecode(value));
    } catch (_) {
      return value;
    }
  }
}

class PaginatedAuditLogs {
  final List<AuditLog> data;
  final int totalPages;
  final int page;
  final int pageSize;
  final int total;

  PaginatedAuditLogs(
      this.data, this.totalPages, this.page, this.pageSize, this.total);
}
