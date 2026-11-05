import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product_model.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class AddProductDialog extends StatefulWidget {
  final ProductCategory? initialCategory;

  const AddProductDialog({super.key, this.initialCategory});

  @override
  State<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> {
  final _formKey = GlobalKey<FormState>();

  late ProductCategory _selectedCategory;
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _authorController = TextEditingController();
  final _conditionOrSizeController = TextEditingController();
  final _imageUrlController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? ProductCategory.artesanato;
    _applyCategoryDefaults(_selectedCategory);
  }

  void _applyCategoryDefaults(ProductCategory category) {
    if (category == ProductCategory.artesanato) {
      _imageUrlController.text =
          'https://images.unsplash.com/photo-1544816155-12df9643f363?auto=format&fit=crop&w=700&q=80';
      _conditionOrSizeController.text = 'Peça Única Artesanal';
    } else if (category == ProductCategory.brecho) {
      _imageUrlController.text =
          'https://images.unsplash.com/photo-1576995853123-5a10305d93c0?auto=format&fit=crop&w=700&q=80';
      _conditionOrSizeController.text = 'Tamanho M • Higienizado';
    } else {
      _imageUrlController.text =
          'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?auto=format&fit=crop&w=700&q=80';
      _conditionOrSizeController.text = 'Material para Upcycling';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _authorController.dispose();
    _conditionOrSizeController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final price = double.tryParse(_priceController.text.replaceAll(',', '.')) ?? 0.0;

    // Validação estrita da Regra 2: Teto de R$ 50,00 nos Artesanatos PcD
    if (_selectedCategory == ProductCategory.artesanato && price > 50.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.darkRed,
          content: Text(
            '⚠️ Regra IHL: Peças da categoria "Artesanato" têm limite máximo de preço de R\$ 50,00.',
          ),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final appProvider = context.read<AppProvider>();
      await appProvider.addProduct(
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        category: _selectedCategory,
        price: price,
        imageUrl: _imageUrlController.text.trim(),
        authorPcd: _selectedCategory == ProductCategory.artesanato
            ? _authorController.text.trim()
            : null,
        conditionOrSize: _conditionOrSizeController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.circularGreen,
            content: Text(
              'Item "${_titleController.text}" cadastrado com sucesso!',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.darkRed,
            content: Text('Erro ao cadastrar: ${e.toString()}'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArtisan = _selectedCategory == ProductCategory.artesanato;
    final isBrecho = _selectedCategory == ProductCategory.brecho;

    return AlertDialog(
      title: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.primaryBlue.withAlpha(25),
            child: const Icon(Icons.add_shopping_cart, color: AppTheme.primaryBlue),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isArtisan
                  ? '🎨 Cadastrar Novo Artesanato'
                  : (isBrecho
                      ? '👕 Cadastrar Peça de Brechó'
                      : '🪵 Cadastrar Outros Itens Circulares'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Seletor de Categoria
                const Text(
                  'Categoria do Item:',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<ProductCategory>(
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: ProductCategory.values.map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Text('${cat.iconEmoji} ${cat.label}'),
                    );
                  }).toList(),
                  onChanged: (cat) {
                    if (cat != null) {
                      setState(() {
                        _selectedCategory = cat;
                        _applyCategoryDefaults(cat);
                      });
                    }
                  },
                ),

                const SizedBox(height: 12),

                // Alerta da Regra 2 para Artesanato PcD
                if (isArtisan)
                  Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, size: 18, color: AppTheme.warningOrange),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Regra de Negócio: Artesanatos PcD têm limite máximo de preço de R\$ 50,00 e crédito nominal obrigatório ao autor.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF92400E),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Título
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Título do Item *',
                    hintText: 'Ex: Tapete Tear Ecológico Retalhos',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Informe o título do item';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                // Campo de Autor PcD (Obrigatório se Artesanato)
                if (isArtisan) ...[
                  TextFormField(
                    controller: _authorController,
                    decoration: const InputDecoration(
                      labelText: 'Nome do Assistido Autor *',
                      hintText: 'Ex: João M.',
                      prefixIcon: Icon(Icons.palette, color: AppTheme.accentBlue),
                    ),
                    validator: (val) {
                      if (isArtisan && (val == null || val.trim().isEmpty)) {
                        return 'Obrigatório identificar o autor assistido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                ],

                // Campo Tamanho / Estado de Conservação
                TextFormField(
                  controller: _conditionOrSizeController,
                  decoration: InputDecoration(
                    labelText: isBrecho
                        ? 'Tamanho e Estado de Conservação *'
                        : 'Especificação / Dimensões',
                    hintText: isBrecho
                        ? 'Ex: Tamanho M • Ótimo estado'
                        : 'Ex: 120x100cm • Madeira pinus',
                  ),
                ),

                const SizedBox(height: 12),

                // Preço (R$)
                TextFormField(
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: isArtisan ? 'Preço (R\$) [Máx R\$ 50,00] *' : 'Preço (R\$) *',
                    hintText: 'Ex: 35.00',
                    prefixText: 'R\$ ',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Informe o valor em R\$';
                    }
                    final num = double.tryParse(val.replaceAll(',', '.'));
                    if (num == null || num <= 0) {
                      return 'Informe um valor válido maior que zero';
                    }
                    if (isArtisan && num > 50.0) {
                      return 'O valor máximo para artesanato é R\$ 50,00';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                // Descrição
                TextFormField(
                  controller: _descController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Descrição detalhada *',
                    hintText: 'Dimensões, técnica, materiais reutilizados...',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Informe a descrição do produto';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                // Imagem URL
                TextFormField(
                  controller: _imageUrlController,
                  decoration: const InputDecoration(
                    labelText: 'URL da Foto *',
                    hintText: 'https://...',
                    prefixIcon: Icon(Icons.image, color: AppTheme.textMuted),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Informe a URL da foto';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.circularGreen,
            minimumSize: const Size(120, 42),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Salvar Item'),
        ),
      ],
    );
  }
}
