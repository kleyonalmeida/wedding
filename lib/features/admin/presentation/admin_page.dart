import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import 'admin_image_picker_io.dart'
    if (dart.library.html) 'admin_image_picker_web.dart' as picker;

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final ApiClient api = ApiClient();
  final email = TextEditingController();
  final password = TextEditingController();
  final code = TextEditingController();
  final currentPassword = TextEditingController();
  final newPassword = TextEditingController();
  final name = TextEditingController();
  final slug = TextEditingController();
  final price = TextEditingController();
  final displayOrder = TextEditingController();
  final category = TextEditingController();
  final description = TextEditingController();
  String phase = 'loading';
  String section = 'Produtos';
  String? error;
  String? sharedKey;
  String? editingId;
  (String, Uint8List)? selectedImage;
  List<dynamic> products = [];
  int productPage = 1;
  int productTotalPages = 1;
  int dataPage = 1;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  @override
  void dispose() {
    api.dispose();
    for (final c in [
      email,
      password,
      code,
      currentPassword,
      newPassword,
      name,
      slug,
      price,
      displayOrder,
      category,
      description
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadSession() async {
    try {
      await api.fetchCsrf();
      final me = await api.get('/api/admin/auth/me');
      if (!mounted) return;
      setState(() {
        phase = me['mustChangePassword'] == true
            ? 'password'
            : me['mfaEnabled'] != true
                ? 'enroll'
                : 'ready';
        error = null;
      });
      if (phase == 'ready') await _loadProducts();
    } catch (_) {
      if (mounted) setState(() => phase = 'login');
    }
  }

  Future<void> _login() async {
    try {
      setState(() => error = null);
      final result = await api.post('/api/admin/auth/login',
          {'username': email.text.trim(), 'password': password.text});
      password.clear();
      if (result['requiresTwoFactor'] == true) {
        setState(() => phase = 'verify');
      } else {
        await _loadSession();
      }
    } catch (_) {
      setState(() => error =
          'Não foi possível entrar. Confira os dados e tente novamente.');
    }
  }

  Future<void> _verify({bool recovery = false}) async {
    try {
      await api.post('/api/admin/auth/mfa/${recovery ? 'recovery' : 'verify'}',
          {'code': code.text.trim()});
      code.clear();
      await _loadSession();
    } catch (_) {
      setState(() => error = 'Código inválido.');
    }
  }

  Future<void> _changePassword() async {
    try {
      await api.post('/api/admin/security/password', {
        'currentPassword': currentPassword.text,
        'newPassword': newPassword.text
      });
      currentPassword.clear();
      newPassword.clear();
      await _loadSession();
    } catch (_) {
      setState(() =>
          error = 'Não foi possível trocar a senha. Verifique os requisitos.');
    }
  }

  Future<void> _enroll() async {
    try {
      final result = await api.post('/api/admin/security/mfa/enroll', {});
      setState(() => sharedKey = result['sharedKey'] as String);
    } catch (_) {
      setState(() =>
          error = 'Não foi possível iniciar a autenticação em duas etapas.');
    }
  }

  Future<void> _confirmMfa() async {
    try {
      final result = await api
          .post('/api/admin/security/mfa/confirm', {'code': code.text.trim()});
      if (!mounted) return;
      final codes = (result['recoveryCodes'] as List?)?.join('\n') ?? '';
      await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
                title: const Text('Guarde os códigos de recuperação'),
                content: SelectableText(codes),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Guardei os códigos'))
                ],
              ));
      setState(() {
        phase = 'login';
        sharedKey = null;
        code.clear();
      });
    } catch (_) {
      setState(() => error = 'Código inválido.');
    }
  }

  Future<void> _loadProducts() async {
    try {
      final result =
          await api.get('/api/admin/products?page=$productPage&pageSize=20');
      if (mounted) {
        setState(() {
          products = result['data'] as List;
          productTotalPages = (result['totalPages'] as int).clamp(1, 1000000);
          error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => error = 'Não foi possível carregar os produtos.');
      }
    }
  }

  void _edit(Map<String, dynamic>? product) {
    editingId = product?['id'] as String?;
    name.text = product?['name'] ?? '';
    slug.text = product?['slug'] ?? '';
    price.text = product == null
        ? ''
        : ((product['priceCents'] as num) / 100).toStringAsFixed(2);
    displayOrder.text = product == null ? '0' : '${product['displayOrder']}';
    category.text = product?['category'] ?? '';
    description.text = product?['description'] ?? '';
    selectedImage = null;
    setState(() => section = 'Editar produto');
  }

  Future<void> _saveProduct() async {
    final cents = (double.tryParse(price.text.replaceAll(',', '.')) ?? 0) * 100;
    if (name.text.trim().isEmpty ||
        slug.text.trim().isEmpty ||
        category.text.trim().isEmpty ||
        cents <= 0) {
      setState(() =>
          error = 'Preencha nome, identificador, categoria e preço válido.');
      return;
    }
    try {
      final body = {
        'name': name.text.trim(),
        'slug': slug.text.trim(),
        'priceCents': cents.round(),
        'category': category.text.trim(),
        'description': description.text.trim(),
        'shortDescription': null,
        'displayOrder': int.tryParse(displayOrder.text) ?? 0
      };
      final result = editingId == null
          ? await api.post('/api/admin/products', body)
          : await api.put('/api/admin/products/$editingId', body);
      final id = result['id'] as String;
      if (selectedImage case final image?) {
        await api.upload('/api/admin/products/$id/images', image.$2, image.$1);
      }
      await _loadProducts();
      if (mounted) {
        setState(() {
          section = 'Produtos';
          error = null;
        });
      }
    } catch (_) {
      setState(() => error = 'Não foi possível salvar o produto.');
    }
  }

  Future<void> _deleteProduct(String id) async {
    try {
      await api.delete('/api/admin/products/$id');
      await _loadProducts();
    } catch (_) {
      setState(() => error = 'Não foi possível remover o produto.');
    }
  }

  Future<void> _setStatus(Map<String, dynamic> product,
      {bool? active, bool? featured}) async {
    try {
      await api.patch('/api/admin/products/${product['id']}/status', {
        'active': active ?? product['active'],
        'featured': featured ?? product['featured'],
      });
      await _loadProducts();
    } catch (_) {
      setState(() => error = 'Não foi possível atualizar o produto.');
    }
  }

  Widget _field(TextEditingController controller, String label,
          {bool secret = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
            controller: controller,
            obscureText: secret,
            decoration: InputDecoration(
                labelText: label, border: const OutlineInputBorder())),
      );

  Widget _accountCard(String title, List<Widget> children) => Center(
          child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Card(
            child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 20),
                ...children
              ]),
        )),
      ));

  Widget _authContent() {
    switch (phase) {
      case 'loading':
        return const Center(child: CircularProgressIndicator());
      case 'login':
        return _accountCard('Acesso administrativo', [
          _field(email, 'Email'),
          _field(password, 'Senha', secret: true),
          FilledButton(onPressed: _login, child: const Text('Entrar')),
        ]);
      case 'verify':
        return _accountCard('Verificação em duas etapas', [
          _field(code, 'Código do aplicativo ou recuperação'),
          FilledButton(
              onPressed: () => _verify(),
              child: const Text('Verificar código')),
          TextButton(
              onPressed: () => _verify(recovery: true),
              child: const Text('Usar código de recuperação')),
        ]);
      case 'password':
        return _accountCard('Troque a senha inicial', [
          _field(currentPassword, 'Senha atual', secret: true),
          _field(newPassword, 'Nova senha', secret: true),
          FilledButton(
              onPressed: _changePassword,
              child: const Text('Salvar nova senha')),
        ]);
      case 'enroll':
        return _accountCard('Configure a autenticação em duas etapas', [
          if (sharedKey == null)
            FilledButton(onPressed: _enroll, child: const Text('Gerar chave')),
          if (sharedKey != null) ...[
            const Text('Adicione esta chave ao seu aplicativo autenticador:'),
            SelectableText(sharedKey!),
            const SizedBox(height: 16),
            _field(code, 'Código de 6 dígitos'),
            FilledButton(
                onPressed: _confirmMfa, child: const Text('Ativar proteção')),
          ],
        ]);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _productList() => Column(children: [
        Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
                onPressed: () => _edit(null),
                icon: const Icon(Icons.add),
                label: const Text('Novo produto'))),
        const SizedBox(height: 12),
        for (final raw in products)
          Builder(builder: (context) {
            final item = Map<String, dynamic>.from(raw as Map);
            return Card(
                child: ListTile(
              title: Text(item['name'] ?? ''),
              subtitle: Text(
                  '${item['category']} · R\$ ${((item['priceCents'] as num) / 100).toStringAsFixed(2)} · ${item['active'] == true ? 'Ativo' : 'Inativo'}'),
              trailing: Wrap(spacing: 4, children: [
                IconButton(
                    tooltip: item['active'] == true ? 'Desativar' : 'Ativar',
                    icon: Icon(item['active'] == true
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: () =>
                        _setStatus(item, active: item['active'] != true)),
                IconButton(
                    tooltip: item['featured'] == true
                        ? 'Remover destaque'
                        : 'Destacar',
                    icon: Icon(item['featured'] == true
                        ? Icons.star
                        : Icons.star_border),
                    onPressed: () =>
                        _setStatus(item, featured: item['featured'] != true)),
                IconButton(
                    tooltip: 'Editar',
                    icon: const Icon(Icons.edit),
                    onPressed: () => _edit(item)),
                IconButton(
                    tooltip: 'Remover',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _deleteProduct(item['id'] as String)),
              ]),
            ));
          }),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          TextButton(
              onPressed: productPage > 1
                  ? () {
                      productPage--;
                      _loadProducts();
                    }
                  : null,
              child: const Text('Anterior')),
          Text('$productPage / $productTotalPages'),
          TextButton(
              onPressed: productPage < productTotalPages
                  ? () {
                      productPage++;
                      _loadProducts();
                    }
                  : null,
              child: const Text('Próxima')),
        ]),
      ]);

  Widget _productForm() => ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 650),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _field(name, 'Nome'),
          _field(slug, 'Identificador (slug)'),
          _field(price, 'Preço em reais'),
          _field(category, 'Categoria'),
          _field(displayOrder, 'Ordem de exibição'),
          _field(description, 'Descrição'),
          OutlinedButton.icon(
              onPressed: () async {
                final image = await picker.pickAdminImage();
                if (mounted && image != null) {
                  setState(() => selectedImage = image);
                }
              },
              icon: const Icon(Icons.image),
              label: Text(selectedImage?.$1 ?? 'Selecionar foto')),
          const SizedBox(height: 12),
          FilledButton(
              onPressed: _saveProduct, child: const Text('Salvar produto')),
          TextButton(
              onPressed: () => setState(() => section = 'Produtos'),
              child: const Text('Voltar')),
        ],
      ));

  Future<dynamic> _loadSection() async {
    final endpoint = switch (section) {
      'Dashboard' => '/api/admin/dashboard/summary',
      'Pagamentos' => '/api/admin/payments?page=$dataPage',
      'Presença' => '/api/admin/attendance?page=$dataPage',
      'Logs' => '/api/admin/audit-logs?page=$dataPage',
      'Configurações' => '/api/admin/settings',
      _ => '/api/admin/me',
    };
    return api.get(endpoint);
  }

  Widget _dataSection() => FutureBuilder<dynamic>(
        key: ValueKey('$section-$dataPage'),
        future: _loadSection(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
                child: snapshot.hasError
                    ? const Text('Falha ao carregar dados.')
                    : const CircularProgressIndicator());
          }
          final data = snapshot.data;
          if (section == 'Dashboard' && data is Map) {
            return Wrap(spacing: 12, runSpacing: 12, children: [
              for (final entry in data.entries)
                Card(
                    child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(entry.key.toString(),
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                              for (final metric in (entry.value as Map).entries)
                                Text('${metric.key}: ${metric.value}')
                            ])))
            ]);
          }
          final rows = data is List
              ? data
              : data is Map
                  ? (data['data'] ?? data['items'] ?? []) as List
                  : <dynamic>[];
          if (rows.isEmpty) return const Text('Nenhum registro encontrado.');
          final total = data is Map ? (data['total'] as num?)?.toInt() : null;
          final pageSize =
              data is Map ? (data['pageSize'] as num?)?.toInt() ?? 20 : 20;
          return Column(children: [
            for (final raw in rows)
              Builder(builder: (context) {
                final row = raw as Map;
                final title = row['name'] ??
                    row['nome'] ??
                    row['senderName'] ??
                    row['action'] ??
                    row['key'] ??
                    'Registro';
                final detail = row['description'] ??
                    row['status'] ??
                    row['email'] ??
                    row['value'] ??
                    '';
                return Card(
                    child: ListTile(
                        title: Text('$title'), subtitle: Text('$detail')));
              }),
            if (total != null)
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                TextButton(
                    onPressed:
                        dataPage > 1 ? () => setState(() => dataPage--) : null,
                    child: const Text('Anterior')),
                Text(
                    '$dataPage / ${((total + pageSize - 1) ~/ pageSize).clamp(1, 1000000)}'),
                TextButton(
                    onPressed: dataPage * pageSize < total
                        ? () => setState(() => dataPage++)
                        : null,
                    child: const Text('Próxima')),
              ])
          ]);
        },
      );

  static const _navItems = [
    (label: 'Dashboard', icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard),
    (label: 'Produtos', icon: Icons.inventory_2_outlined, activeIcon: Icons.inventory_2),
    (label: 'Pagamentos', icon: Icons.payment_outlined, activeIcon: Icons.payment),
    (label: 'Presença', icon: Icons.people_outline, activeIcon: Icons.people),
    (label: 'Logs', icon: Icons.list_alt_outlined, activeIcon: Icons.list_alt),
    (label: 'Configurações', icon: Icons.settings_outlined, activeIcon: Icons.settings),
    (label: 'Segurança', icon: Icons.security_outlined, activeIcon: Icons.security),
  ];

  int get _selectedIndex {
    final idx = _navItems.indexWhere((e) => e.label == section);
    return idx < 0 ? 1 : idx; // fallback to Produtos
  }

  @override
  Widget build(BuildContext context) {
    final ready = phase == 'ready';
    return Scaffold(
      appBar: AppBar(
          title: const Text('Administração do casamento'),
          actions: ready
              ? [
                  IconButton(
                      tooltip: 'Sair',
                      onPressed: () async {
                        await api.post('/api/admin/auth/logout', {});
                        if (mounted) setState(() => phase = 'login');
                      },
                      icon: const Icon(Icons.logout)),
                ]
              : null),
      body: SafeArea(
        child: ready
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Side navigation ──────────────────────────────
                  NavigationRail(
                    selectedIndex: _selectedIndex,
                    labelType: NavigationRailLabelType.all,
                    onDestinationSelected: (i) => setState(() {
                      section = _navItems[i].label;
                      dataPage = 1;
                    }),
                    destinations: [
                      for (final item in _navItems)
                        NavigationRailDestination(
                          icon: Icon(item.icon),
                          selectedIcon: Icon(item.activeIcon),
                          label: Text(item.label),
                        ),
                    ],
                  ),
                  const VerticalDivider(thickness: 1, width: 1),
                  // ── Main content ──────────────────────────────────
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (error != null)
                            Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Text(error!,
                                    style: const TextStyle(color: Colors.red))),
                          Text(section,
                              style:
                                  Theme.of(context).textTheme.headlineMedium),
                          const SizedBox(height: 16),
                          if (section == 'Produtos')
                            _productList()
                          else if (section == 'Editar produto')
                            _productForm()
                          else if (section == 'Segurança')
                            Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _field(currentPassword, 'Senha atual',
                                      secret: true),
                                  _field(newPassword, 'Nova senha',
                                      secret: true),
                                  FilledButton(
                                      onPressed: _changePassword,
                                      child: const Text('Trocar senha')),
                                ])
                          else
                            _dataSection(),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (error != null)
                      Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(error!,
                              style: const TextStyle(color: Colors.red))),
                    _authContent(),
                  ],
                ),
              ),
      ),
    );
  }
}

