enum WebScrollMode { smooth, native }

WebScrollMode resolveWebScrollMode([Uri? uri]) {
  final value = (uri ?? Uri.base).queryParameters['scroll']?.toLowerCase();
  return value == 'native' ? WebScrollMode.native : WebScrollMode.smooth;
}
