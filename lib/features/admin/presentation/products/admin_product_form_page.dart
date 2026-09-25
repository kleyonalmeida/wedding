import 'dart:typed_data';
import '../../../../core/network/api_client.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/repositories/product_repository.dart';
import '../shell/admin_session_controller.dart';
import '../widgets/admin_page_header.dart';
import '../widgets/admin_state_widgets.dart';

class AdminProductFormPage extends StatefulWidget {
  final String? productId; // se nulo, cria novo.

  const AdminProductFormPage({super.key, this.productId});

  @override
  State<AdminProductFormPage> createState() => _AdminProductFormPageState();
}

class _AdminProductFormPageState extends State<AdminProductFormPage> {
  late ProductRepository _repository;

  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _slug = TextEditingController();
  final _category = TextEditingController();
  final _price = TextEditingController();
  final _displayOrder = TextEditingController(text: '0');
  final _shortDesc = TextEditingController();
  final _desc = TextEditingController();

  bool _active = true;
  bool _featured = false;
  bool _savedActive = true;
  bool _savedFeatured = false;
  String? _persistedId;
  String? _existingImageUrl;

  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;

  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = ProductRepository(AdminSessionController.instance.api);
    _persistedId = widget.productId;
    if (widget.productId != null) {
      _loadProduct();
    }
  }

  Future<void> _loadProduct() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final product = await _repository.get(widget.productId!);
      _name.text = product.name;
      _slug.text = product.slug;
      _category.text = product.category;
      _price.text = (product.priceCents / 100).toStringAsFixed(2);
      _displayOrder.text = product.displayOrder.toString();
      _shortDesc.text = product.shortDescription ?? '';
      _desc.text = product.description ?? '';
      _active = product.active;
      _featured = product.featured;
      _savedActive = product.active;
      _savedFeatured = product.featured;
      _existingImageUrl = product.imageUrl;

      setState(() => _isLoading = false);
    } catch (_) {
      setState(() {
        _error = 'Não foi possível carregar o produto.';
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      final bytes = await file.readAsBytes();
      if (mounted) {
        setState(() {
          _selectedImage = file;
          _selectedImageBytes = bytes;
        });
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final priceParts = _price.text.trim().replaceAll(',', '.').split('.');
      final priceCents = int.parse(priceParts.first) * 100 +
          (priceParts.length == 2
              ? int.parse(priceParts.last.padRight(2, '0'))
              : 0);

      final data = {
        'name': _name.text,
        'slug': _slug.text,
        'category': _category.text,
        'priceCents': priceCents,
        'displayOrder': int.tryParse(_displayOrder.text) ?? 0,
        'shortDescription': _shortDesc.text,
        'description': _desc.text,
      };

      String productId = _persistedId ?? '';
      if (_persistedId == null) {
        final newProduct = await _repository.create(data);
        productId = newProduct.id;
        _persistedId = productId;
      } else {
        await _repository.update(productId, data);
      }

      if (_active != _savedActive || _featured != _savedFeatured) {
        await _repository.patchStatus(productId,
            active: _active, featured: _featured);
        _savedActive = _active;
        _savedFeatured = _featured;
      }

      if (_selectedImage != null) {
        try {
          await _repository.uploadImage(
              productId, _selectedImageBytes!, _selectedImage!.name);
          _selectedImage = null;
          _selectedImageBytes = null;
        } catch (_) {
          if (mounted) {
            setState(() {
              _error =
                  'O produto foi salvo, mas o upload da imagem falhou. Tente salvar novamente.';
              _isLoading = false;
            });
          }
          return;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produto salvo com sucesso.')),
        );
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Erro ao salvar produto. Verifique os dados.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && widget.productId != null && _name.text.isEmpty) {
      return const AdminLoadingState(message: 'Carregando produto...');
    }

    if (_error != null && widget.productId != null && _name.text.isEmpty) {
      return AdminErrorState(message: _error!, onRetry: _loadProduct);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(32),
          child: AdminPageHeader(
            title: widget.productId == null ? 'Novo Produto' : 'Editar Produto',
            subtitle: 'Catálogo',
            trailing: FilledButton.icon(
              onPressed: _isLoading ? null : _save,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save),
              label: const Text('Salvar'),
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 750;
                final gap = compact ? 0.0 : 32.0;
                return Wrap(
                  spacing: gap,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: compact
                          ? constraints.maxWidth
                          : (constraints.maxWidth - gap) * 0.7,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (_error != null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 24),
                                    child: Text(_error!,
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .error)),
                                  ),
                                LayoutBuilder(
                                    builder: (context, fieldConstraints) =>
                                        Wrap(
                                          spacing: 16,
                                          runSpacing: 16,
                                          children: [
                                            SizedBox(
                                              width: compact
                                                  ? fieldConstraints.maxWidth
                                                  : (fieldConstraints.maxWidth -
                                                          16) /
                                                      2,
                                              child: TextFormField(
                                                controller: _name,
                                                decoration: const InputDecoration(
                                                    labelText:
                                                        'Nome do Produto',
                                                    border:
                                                        OutlineInputBorder()),
                                                validator: (v) => v == null ||
                                                        v.trim().isEmpty
                                                    ? 'Obrigatório'
                                                    : null,
                                              ),
                                            ),
                                            SizedBox(
                                              width: compact
                                                  ? fieldConstraints.maxWidth
                                                  : (fieldConstraints.maxWidth -
                                                          16) /
                                                      2,
                                              child: TextFormField(
                                                controller: _price,
                                                decoration: const InputDecoration(
                                                    labelText: 'Preço (R\$)',
                                                    border:
                                                        OutlineInputBorder()),
                                                validator: (v) {
                                                  final value = v?.trim() ?? '';
                                                  if (!RegExp(
                                                          r'^\d+([,.]\d{1,2})?$')
                                                      .hasMatch(value)) {
                                                    return 'Informe um preço válido';
                                                  }
                                                  final amount =
                                                      double.tryParse(
                                                              value.replaceAll(
                                                                  ',', '.')) ??
                                                          0;
                                                  return amount > 0 &&
                                                          amount <= 100000
                                                      ? null
                                                      : 'Preço fora do limite';
                                                },
                                              ),
                                            ),
                                          ],
                                        )),
                                const SizedBox(height: 16),
                                LayoutBuilder(
                                    builder: (context, fieldConstraints) =>
                                        Wrap(
                                          spacing: 16,
                                          runSpacing: 16,
                                          children: [
                                            SizedBox(
                                              width: compact
                                                  ? fieldConstraints.maxWidth
                                                  : (fieldConstraints.maxWidth -
                                                          16) /
                                                      2,
                                              child: TextFormField(
                                                controller: _category,
                                                decoration: const InputDecoration(
                                                    labelText: 'Categoria',
                                                    border:
                                                        OutlineInputBorder()),
                                                validator: (v) => v!.isEmpty
                                                    ? 'Obrigatório'
                                                    : null,
                                              ),
                                            ),
                                            SizedBox(
                                              width: compact
                                                  ? fieldConstraints.maxWidth
                                                  : (fieldConstraints.maxWidth -
                                                          16) /
                                                      2,
                                              child: TextFormField(
                                                controller: _slug,
                                                decoration: const InputDecoration(
                                                    labelText:
                                                        'Slug (URL amigável)',
                                                    border:
                                                        OutlineInputBorder()),
                                                validator: (v) => v!.isEmpty
                                                    ? 'Obrigatório'
                                                    : null,
                                              ),
                                            ),
                                          ],
                                        )),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _displayOrder,
                                  decoration: const InputDecoration(
                                      labelText: 'Ordem de Exibição',
                                      border: OutlineInputBorder()),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _shortDesc,
                                  decoration: const InputDecoration(
                                      labelText: 'Breve Descrição',
                                      border: OutlineInputBorder()),
                                  maxLines: 2,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _desc,
                                  decoration: const InputDecoration(
                                      labelText: 'Descrição Completa',
                                      border: OutlineInputBorder()),
                                  maxLines: 4,
                                ),
                                const SizedBox(height: 24),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Switch(
                                              value: _active,
                                              onChanged: (v) =>
                                                  setState(() => _active = v)),
                                          const Flexible(
                                              child: Text('Produto Ativo')),
                                        ]),
                                    Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Switch(
                                              value: _featured,
                                              onChanged: (v) => setState(
                                                  () => _featured = v)),
                                          const Flexible(
                                              child: Text('Destaque (Home)')),
                                        ]),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: compact
                          ? constraints.maxWidth
                          : (constraints.maxWidth - gap) * 0.3,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text('Imagem Principal',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 16),
                              Container(
                                height: 200,
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outlineVariant),
                                ),
                                child: _selectedImageBytes != null
                                    ? Image.memory(_selectedImageBytes!,
                                        fit: BoxFit.cover)
                                    : _existingImageUrl != null
                                        ? Image.network(
                                            '${ApiClient.baseUrl}$_existingImageUrl',
                                            fit: BoxFit.cover)
                                        : const Center(
                                            child: Text('Nenhuma imagem')),
                              ),
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                onPressed: _pickImage,
                                icon: const Icon(Icons.upload),
                                label: const Text('Selecionar Imagem'),
                              ),
                              if (_selectedImage != null) ...[
                                const SizedBox(height: 8),
                                Text('Selecionado: ${_selectedImage!.name}',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ]
                            ],
                          ),
                        ),
                      ),
                    )
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _slug.dispose();
    _category.dispose();
    _price.dispose();
    _displayOrder.dispose();
    _shortDesc.dispose();
    _desc.dispose();
    super.dispose();
  }
}
