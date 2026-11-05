import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product_model.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/product_card.dart';

class VitrineScreen extends StatefulWidget {
  const VitrineScreen({super.key});

  @override
  State<VitrineScreen> createState() => _VitrineScreenState();
}

class _VitrineScreenState extends State<VitrineScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final isSearching = app.searchQuery.isNotEmpty || app.selectedCategory != null;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: CustomScrollView(
        slivers: [
          // BARRA DE BUSCA DINÂMICA SUPERIOR
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Banner de Localização e Missão
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.lightGreen,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.recycling,
                          color: AppTheme.circularGreen,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Instituto Horizonte Livre (IHL)',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                            Text(
                              '📍 Retirada Presencial na Sede em Mogi das Cruzes - SP',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // BARRA DE BUSCA DINÂMICA (Filtra por título e descrição em tempo real)
                  TextField(
                    controller: _searchController,
                    onChanged: (val) => app.setSearchQuery(val),
                    decoration: InputDecoration(
                      hintText: 'Buscar por título ou descrição em tempo real...',
                      prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted),
                      suffixIcon: app.searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                app.setSearchQuery('');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Chips de Filtro Rápido
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(
                          label: 'Todos',
                          isSelected: app.selectedCategory == null,
                          onSelected: () => app.selectCategory(null),
                        ),
                        const SizedBox(width: 6),
                        _buildFilterChip(
                          label: '🎨 Feito por Nossos Assistidos',
                          isSelected: app.selectedCategory ==
                              ProductCategory.artesanato,
                          onSelected: () => app.selectCategory(
                              ProductCategory.artesanato),
                        ),
                        const SizedBox(width: 6),
                        _buildFilterChip(
                          label: '👕 Garimpo Solidário (Brechó)',
                          isSelected:
                              app.selectedCategory == ProductCategory.brecho,
                          onSelected: () =>
                              app.selectCategory(ProductCategory.brecho),
                        ),
                        const SizedBox(width: 6),
                        _buildFilterChip(
                          label: '🪵 Outros Materiais Circulares',
                          isSelected:
                              app.selectedCategory == ProductCategory.materiais,
                          onSelected: () =>
                              app.selectCategory(ProductCategory.materiais),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // SE BUSCA OU FILTRO ATIVO: MOSTRA GRID DINÂMICA
          if (isSearching)
            _buildFilteredResults(app)
          else ...[
            // MODO PADRÃO: OS 3 CARROSSÉIS HORIZONTAIS
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),

                  // CARROSSEL 1: "🎨 FEITO POR NOSSOS ASSISTIDOS" (Teto R$ 50,00 e tag "Por: [Nome do Assistido]")
                  VitrineCarouselSection(
                    title: '🎨 FEITO POR NOSSOS ASSISTIDOS',
                    subtitle:
                        'Artesanatos feitos nas oficinas do IHL (Teto de R\$ 50,00)',
                    products: app.artisanProducts,
                    badgeText: 'OFICINAS IHL',
                    badgeColor: AppTheme.circularGreen,
                  ),

                  const SizedBox(height: 16),

                  // CARROSSEL 2: "👕 GARIMPO SOLIDÁRIO (BRECHÓ)" (Roupas, calçados e acessórios)
                  VitrineCarouselSection(
                    title: '👕 GARIMPO SOLIDÁRIO (BRECHÓ)',
                    subtitle: 'Roupas, calçados e acessórios doados higienizados',
                    products: app.brechoProducts,
                    badgeText: 'MODA CIRCULAR',
                    badgeColor: AppTheme.accentBlue,
                  ),

                  const SizedBox(height: 16),

                  // CARROSSEL 3: "🪵 OUTROS MATERIAIS CIRCULARES" (Placas de vidro, madeira, paletes)
                  VitrineCarouselSection(
                    title: '🪵 OUTROS MATERIAIS CIRCULARES',
                    subtitle:
                        'Materiais reutilizáveis: placas de vidro, madeira e paletes',
                    products: app.materialProducts,
                    badgeText: 'REAPROVEITAMENTO',
                    badgeColor: const Color(0xFFD97706),
                  ),

                  const SizedBox(height: 28),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: AppTheme.primaryBlue,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppTheme.textPrimary,
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
      ),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppTheme.primaryBlue : AppTheme.borderColor,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    );
  }

  Widget _buildFilteredResults(AppProvider app) {
    final filtered = app.filteredProducts;

    if (filtered.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search_off, size: 48, color: AppTheme.textMuted),
                const SizedBox(height: 12),
                const Text(
                  'Nenhum item disponível encontrado',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Tente buscar com outros termos ou limpar os filtros.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () {
                    _searchController.clear();
                    app.clearFilters();
                  },
                  child: const Text('Limpar Filtros'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.crossAxisExtent;
        // Ajuste responsivo de proporções e pixels para evitar estouros na tela reduzida
        final childAspectRatio = screenWidth < 380
            ? 0.58
            : (screenWidth < 600 ? 0.62 : 0.68);
        final maxCrossAxisExtent = screenWidth < 380 ? 175.0 : 220.0;

        return SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: maxCrossAxisExtent,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: childAspectRatio,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return ProductCard(
                  product: filtered[index],
                  isHorizontalCarousel: false,
                );
              },
              childCount: filtered.length,
            ),
          ),
        );
      },
    );
  }
}

/// Widget dedicado de carrossel com scroll lateral interativo, suporte a arrasto
/// e ajuste dinâmico de pixels para acompanhar qualquer tamanho de tela (modo reduzido ou expandido).
class VitrineCarouselSection extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<ProductModel> products;
  final String badgeText;
  final Color badgeColor;

  const VitrineCarouselSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.products,
    required this.badgeText,
    required this.badgeColor,
  });

  @override
  State<VitrineCarouselSection> createState() => _VitrineCarouselSectionState();
}

class _VitrineCarouselSectionState extends State<VitrineCarouselSection> {
  final ScrollController _scrollController = ScrollController();
  bool _canScrollLeft = false;
  bool _canScrollRight = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final offset = _scrollController.offset;
    final canLeft = offset > 4;
    final canRight = offset < maxScroll - 4;
    if (canLeft != _canScrollLeft || canRight != _canScrollRight) {
      if (mounted) {
        setState(() {
          _canScrollLeft = canLeft;
          _canScrollRight = canRight;
        });
      }
    }
  }

  void _scrollSideways(double delta) {
    if (!_scrollController.hasClients) return;
    final target = (_scrollController.offset + delta).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isReducedMode = screenWidth < 520;

    // Ajuste responsivo de pixels para que os cards e as imagens acompanhem o tamanho da tela
    final cardWidth = isReducedMode
        ? (screenWidth * 0.65).clamp(190.0, 230.0)
        : 220.0;

    // Altura da imagem com base no aspect ratio 1.55
    final imageHeight = cardWidth / 1.55;
    // Altura total do carrossel considerando imagem, textos e scrollbar lateral
    final carouselHeight = imageHeight + 128.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: widget.badgeColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  widget.badgeText,
                  style: TextStyle(
                    color: widget.badgeColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (widget.products.isNotEmpty) ...[
                const SizedBox(width: 8),
                // Botões de rolagem lateral (Scroll arrows)
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left, size: 20),
                        onPressed: _canScrollLeft
                            ? () => _scrollSideways(-cardWidth * 1.3)
                            : null,
                        tooltip: 'Rolar lateralmente para esquerda',
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 16,
                        color: AppTheme.borderColor,
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right, size: 20),
                        onPressed: _canScrollRight
                            ? () => _scrollSideways(cardWidth * 1.3)
                            : null,
                        tooltip: 'Rolar lateralmente para direita',
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 10),

        if (widget.products.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              'Nenhum item disponível nesta categoria no momento.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
          )
        else
          SizedBox(
            height: carouselHeight,
            child: RawScrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              trackVisibility: true,
              thickness: 5,
              radius: const Radius.circular(6),
              thumbColor: AppTheme.primaryBlue.withAlpha(120),
              trackColor: Colors.black.withAlpha(12),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.separated(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
                itemCount: widget.products.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  return ProductCard(
                    product: widget.products[index],
                    width: cardWidth,
                    isHorizontalCarousel: true,
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}
