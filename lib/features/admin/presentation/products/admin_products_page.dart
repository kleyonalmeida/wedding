import 'package:flutter/material.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/models/product.dart';
import '../shell/admin_session_controller.dart';
import '../widgets/admin_page_header.dart';
import '../widgets/admin_state_widgets.dart';
import '../widgets/admin_responsive_records.dart';

class AdminProductsPage extends StatefulWidget {
  final int initialPage;
  const AdminProductsPage({super.key, this.initialPage = 1});

  @override
  State<AdminProductsPage> createState() => _AdminProductsPageState();
}

class _AdminProductsPageState extends State<AdminProductsPage> {
  late ProductRepository _repository;
  PaginatedProducts? _data;
  bool _isLoading = false;
  String? _error;
  late int _page;

  @override
  void initState() {
    super.initState();
    _page = widget.initialPage;
    _repository = ProductRepository(AdminSessionController.instance.api);
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final result = await _repository.list(page: _page);
      if (mounted) {
        setState(() {
          _data = result;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Não foi possível carregar o catálogo.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteProduct(Product product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover produto?'),
        content: Text(
            'Tem certeza que deseja remover o produto "${product.name}"? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remover')),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _repository.delete(product.id);
        await _loadProducts(); // recarrega a lista
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro ao remover o produto.')),
          );
        }
      }
    }
  }

  Future<void> _toggleStatus(Product product,
      {bool? active, bool? featured}) async {
    try {
      await _repository.patchStatus(
        product.id,
        active: active ?? product.active,
        featured: featured ?? product.featured,
      );
      await _loadProducts();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Erro ao atualizar o status do produto.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(32),
          child: AdminPageHeader(
            title: 'Catálogo de Produtos',
            subtitle: 'Produtos',
            trailing: FilledButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, '/admin/produtos/novo')
                      .then((_) => _loadProducts()),
              icon: const Icon(Icons.add),
              label: const Text('Novo Produto'),
            ),
          ),
        ),
        Expanded(
          child: _buildContent(),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading && _data == null) {
      return const AdminLoadingState(message: 'Carregando catálogo...');
    }

    if (_error != null) {
      return AdminErrorState(message: _error!, onRetry: _loadProducts);
    }

    if (_data == null || _data!.data.isEmpty) {
      return const AdminEmptyState(
          message: 'Nenhum produto cadastrado no catálogo.');
    }

    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: AdminResponsiveRecords(
                cards: _data!.data
                    .map((product) => Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(product.name,
                                      style: theme.textTheme.titleMedium),
                                  Text(
                                      '${product.category} • R\$ ${(product.priceCents / 100).toStringAsFixed(2)}'),
                                  Text(product.active ? 'Ativo' : 'Inativo'),
                                  if (product.featured)
                                    const Text('Em destaque'),
                                  Wrap(children: [
                                    TextButton(
                                        onPressed: () => _toggleStatus(product,
                                            active: !product.active),
                                        child: Text(product.active
                                            ? 'Desativar'
                                            : 'Ativar')),
                                    TextButton(
                                        onPressed: () => _toggleStatus(product,
                                            featured: !product.featured),
                                        child: Text(product.featured
                                            ? 'Remover destaque'
                                            : 'Destacar')),
                                    TextButton(
                                        onPressed: () => Navigator.pushNamed(
                                                context,
                                                '/admin/produtos/${product.id}')
                                            .then((_) => _loadProducts()),
                                        child: const Text('Editar')),
                                    TextButton(
                                        onPressed: () =>
                                            _deleteProduct(product),
                                        child: const Text('Remover')),
                                  ]),
                                ]),
                          ),
                        ))
                    .toList(),
                table: DataTable(
                  showCheckboxColumn: false,
                  columns: const [
                    DataColumn(label: Text('Nome do Produto')),
                    DataColumn(label: Text('Categoria')),
                    DataColumn(label: Text('Preço')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Ações')),
                  ],
                  rows: _data!.data.map((product) {
                    return DataRow(
                      cells: [
                        DataCell(Text(product.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w500))),
                        DataCell(Text(product.category)),
                        DataCell(Text(
                            'R\$ ${(product.priceCents / 100).toStringAsFixed(2)}')),
                        DataCell(Wrap(
                          spacing: 8,
                          children: [
                            Chip(
                              label: Text(product.active ? 'Ativo' : 'Inativo',
                                  style: theme.textTheme.labelSmall),
                              backgroundColor: product.active
                                  ? theme.colorScheme.primaryContainer
                                      .withValues(alpha: 0.4)
                                  : theme.colorScheme.surfaceContainerHigh,
                              side: BorderSide.none,
                              padding: EdgeInsets.zero,
                            ),
                            if (product.featured)
                              Chip(
                                label: const Icon(Icons.star,
                                    size: 14, color: Colors.orange),
                                backgroundColor:
                                    Colors.orange.withValues(alpha: 0.1),
                                side: BorderSide.none,
                                padding: EdgeInsets.zero,
                              )
                          ],
                        )),
                        DataCell(Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: product.active ? 'Desativar' : 'Ativar',
                              icon: Icon(
                                  product.active
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  size: 20),
                              onPressed: () => _toggleStatus(product,
                                  active: !product.active),
                            ),
                            IconButton(
                              tooltip: product.featured
                                  ? 'Remover Destaque'
                                  : 'Destacar',
                              icon: Icon(
                                  product.featured
                                      ? Icons.star
                                      : Icons.star_border,
                                  size: 20,
                                  color:
                                      product.featured ? Colors.orange : null),
                              onPressed: () => _toggleStatus(product,
                                  featured: !product.featured),
                            ),
                            IconButton(
                              tooltip: 'Editar',
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () => Navigator.pushNamed(
                                      context, '/admin/produtos/${product.id}')
                                  .then((_) => _loadProducts()),
                            ),
                            IconButton(
                              tooltip: 'Remover',
                              icon: Icon(Icons.delete_outline,
                                  size: 20, color: theme.colorScheme.error),
                              onPressed: () => _deleteProduct(product),
                            ),
                          ],
                        )),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),

            // Pagination footer
            if (_data!.totalPages > 1)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: _page > 1
                          ? () {
                              Navigator.pushNamed(
                                  context, '/admin/produtos?page=${_page - 1}');
                            }
                          : null,
                      child: const Text('Anterior'),
                    ),
                    const SizedBox(width: 16),
                    Text('Página $_page de ${_data!.totalPages}',
                        style: theme.textTheme.labelSmall),
                    const SizedBox(width: 16),
                    TextButton(
                      onPressed: _page < _data!.totalPages
                          ? () {
                              Navigator.pushNamed(
                                  context, '/admin/produtos?page=${_page + 1}');
                            }
                          : null,
                      child: const Text('Próxima'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
