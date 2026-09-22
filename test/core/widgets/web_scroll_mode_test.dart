import 'package:flutter_test/flutter_test.dart';
import 'package:wedding_app/core/widgets/web_scroll_mode.dart';

void main() {
  test('uses smooth mode by default', () {
    expect(
      resolveWebScrollMode(Uri.parse('https://example.com/')),
      WebScrollMode.smooth,
    );
  });

  test('enables native mode from the query string', () {
    expect(
      resolveWebScrollMode(Uri.parse('https://example.com/?scroll=native')),
      WebScrollMode.native,
    );
  });

  test('accepts the mode name without case sensitivity', () {
    expect(
      resolveWebScrollMode(Uri.parse('https://example.com/?scroll=NATIVE')),
      WebScrollMode.native,
    );
  });
}
