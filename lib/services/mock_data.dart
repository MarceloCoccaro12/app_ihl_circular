import '../models/user_model.dart';
import '../models/product_model.dart';
import '../models/donation_model.dart';
import '../models/transaction_model.dart';

class MockData {
  static List<UserModel> getInitialUsers() {
    return [
      UserModel(
        id: 'usr_mariana',
        name: 'Mariana Souza',
        email: 'mariana.souza@email.com',
        phone: '(11) 98765-4321',
        role: UserRole.comum,
        termsAccepted: true,
        termsAcceptedAt: DateTime.now().subtract(const Duration(days: 10)),
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
      UserModel(
        id: 'usr_admin_carlos',
        name: 'Carlos Ribeiro (Monitor IHL)',
        email: 'admin@ihl.org.br',
        phone: '(11) 97654-3210',
        role: UserRole.admin,
        termsAccepted: true,
        termsAcceptedAt: DateTime.now().subtract(const Duration(days: 60)),
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
      ),
    ];
  }

  static List<ProductModel> getInitialProducts() {
    final now = DateTime.now();

    return [
      // 🎨 CARROSSEL 1: "FEITO POR NOSSOS ASSISTIDOS" (Teto R$ 50,00 + Tag "Por: [Nome do Assistido]")
      ProductModel(
        id: 'prod_art_1',
        title: 'Tapete Tear Ecológico Retalhos',
        description:
            'Tapete artesanal confeccionado com fios de malha reaproveitados da indústria têxtil do Alto Tietê. Alta durabilidade e acabamento manual.',
        category: ProductCategory.artesanato,
        price: 42.0,
        imageUrl:
            'https://images.unsplash.com/photo-1600121848594-d8644e57abab?auto=format&fit=crop&w=700&q=80',
        authorPcd: 'João M.',
        conditionOrSize: 'Peça Única • 80x50cm',
        status: ProductStatus.available,
      ),
      ProductModel(
        id: 'prod_art_2',
        title: 'Luminária Rústica Vidro & Macramê',
        description:
            'Garrafa de azeite higienizada e customizada com nós de macramê em cordão de algodão cru. Acompanha fiação segura com interruptor.',
        category: ProductCategory.artesanato,
        price: 48.0,
        imageUrl:
            'https://images.unsplash.com/photo-1513519245088-0e12902e5a38?auto=format&fit=crop&w=700&q=80',
        authorPcd: 'Ana Clara S.',
        conditionOrSize: 'Peça Única • Bivolt',
        status: ProductStatus.available,
      ),
      ProductModel(
        id: 'prod_art_3',
        title: 'Kit 3 Sabonetes Artesanais & Base Madeira',
        description:
            'Sabonetes vegetais hidratantes com essência de alecrim e capim-limão cultivados na horta do IHL. Base em madeira de demolição lixada.',
        category: ProductCategory.artesanato,
        price: 35.0,
        imageUrl:
            'https://images.unsplash.com/photo-1607006314177-3e817d23d854?auto=format&fit=crop&w=700&q=80',
        authorPcd: 'Lucas P.',
        conditionOrSize: 'Kit c/ 3 unidades',
        status: ProductStatus.available,
      ),
      ProductModel(
        id: 'prod_art_4',
        title: 'Quadro Mosaico em Azulejo Reciclado',
        description:
            'Composição artística floral utilizando sobras de azulejos descartados da construção civil. Moldura ecológica em pinus reflorestado.',
        category: ProductCategory.artesanato,
        price: 50.0, // Teto máximo permitido de R$ 50,00
        imageUrl:
            'https://images.unsplash.com/photo-1579783900882-c0d3dad7b119?auto=format&fit=crop&w=700&q=80',
        authorPcd: 'Beatriz L.',
        conditionOrSize: 'Dimensões 30x30cm',
        status: ProductStatus.available,
      ),
      ProductModel(
        id: 'prod_art_5',
        title: 'Porta-Chaves Madeira de Demolição',
        description:
            'Porta-chaves com 4 ganchos metálicos fixados em tábua de peroba recuperada. Trabalho de pirografia feito com suporte adaptado.',
        category: ProductCategory.artesanato,
        price: 28.0,
        imageUrl:
            'https://images.unsplash.com/photo-1544816155-12df9643f363?auto=format&fit=crop&w=700&q=80',
        authorPcd: 'Carlos E.',
        conditionOrSize: 'Madeira Maciça • 4 ganchos',
        status: ProductStatus.reserved,
        reservedByUserId: 'usr_mariana',
        reservedByName: 'Mariana Souza',
        reservedAt: now.subtract(const Duration(hours: 20)),
        expiresAt: now.add(const Duration(hours: 148)), // 168 horas = 7 dias
      ),

      // 👕 CARROSSEL 2: "GARIMPO SOLIDÁRIO (BRECHÓ)" (Roupas, Calçados e Acessórios)
      ProductModel(
        id: 'prod_bre_1',
        title: 'Jaqueta Jeans Clássica Vintage',
        description:
            'Peça garimpada em ótimo estado de conservação, tamanho G. Tecido 100% algodão sem marcas de desgaste. Higienizada e revisada pela equipe.',
        category: ProductCategory.brecho,
        price: 45.0,
        imageUrl:
            'https://images.unsplash.com/photo-1576995853123-5a10305d93c0?auto=format&fit=crop&w=700&q=80',
        conditionOrSize: 'Tamanho G • Ótimo estado',
        status: ProductStatus.available,
      ),
      ProductModel(
        id: 'prod_bre_2',
        title: 'Vestido Midi Floral Primavera',
        description:
            'Vestido com estampa floral delicada em viscose fluida. Forro interno macio e caimento solto. Perfeito para o dia a dia.',
        category: ProductCategory.brecho,
        price: 38.0,
        imageUrl:
            'https://images.unsplash.com/photo-1572804013309-59a88b7e92f1?auto=format&fit=crop&w=700&q=80',
        conditionOrSize: 'Tamanho M • Como novo',
        status: ProductStatus.available,
      ),
      ProductModel(
        id: 'prod_bre_3',
        title: 'Tênis Esportivo Casual Unissex',
        description:
            'Calçado esportivo amortecido em excelente estado de sola e cabedal. Ideal para caminhadas e uso diário.',
        category: ProductCategory.brecho,
        price: 65.0,
        imageUrl:
            'https://images.unsplash.com/photo-1542291026-7eec264c27ff?auto=format&fit=crop&w=700&q=80',
        conditionOrSize: 'Tamanho 41 • Pouco uso',
        status: ProductStatus.available,
      ),
      ProductModel(
        id: 'prod_bre_4',
        title: 'Camisa Social Manga Longa Linho',
        description:
            'Camisa masculina de corte slim, cor bege suave. Botões originais e costura reforçada. Peça doada de acervo de alta costura.',
        category: ProductCategory.brecho,
        price: 40.0,
        imageUrl:
            'https://images.unsplash.com/photo-1602810318383-e386cc2a3ccf?auto=format&fit=crop&w=700&q=80',
        conditionOrSize: 'Tamanho M • Impecável',
        status: ProductStatus.available,
      ),

      // 🪵 CARROSSEL 3: "OUTROS MATERIAIS CIRCULARES" (Placas de Vidro, Madeira, Paletes)
      ProductModel(
        id: 'prod_mat_1',
        title: 'Lote com 2 Paletes Tratados (Padrão PBR)',
        description:
            'Paletes de madeira lixados e prontos para projetos DIY como sofás, camas ou suportes de jardim vertical. Madeiras higienizadas.',
        category: ProductCategory.materiais,
        price: 30.0,
        imageUrl:
            'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?auto=format&fit=crop&w=700&q=80',
        conditionOrSize: 'Lote c/ 2 unidades • 120x100cm',
        status: ProductStatus.available,
      ),
      ProductModel(
        id: 'prod_mat_2',
        title: 'Conjunto 6 Garrafas Âmbar p/ Decoração',
        description:
            'Garrafas de vidro âmbar esterilizadas, ideais para vasos de flores secas, luminárias de filamento ou artesanato de mesa.',
        category: ProductCategory.materiais,
        price: 20.0,
        imageUrl:
            'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?auto=format&fit=crop&w=700&q=80',
        conditionOrSize: 'Kit c/ 6 unidades • Vidro Âmbar',
        status: ProductStatus.available,
      ),
      ProductModel(
        id: 'prod_mat_3',
        title: 'Caixotes de Madeira Rústica Higienizados (Par)',
        description:
            'Dois caixotes resistentes de madeira pinus para nichos de parede, estantes organizadoras ou floreiras ecológicas.',
        category: ProductCategory.materiais,
        price: 25.0,
        imageUrl:
            'https://images.unsplash.com/photo-1595428774223-ef52624120d2?auto=format&fit=crop&w=700&q=80',
        conditionOrSize: 'Par • Madeira Pinus Lixada',
        status: ProductStatus.available,
      ),
      ProductModel(
        id: 'prod_mat_4',
        title: 'Fardo de Retalhos de Algodão 5kg',
        description:
            'Retalhos limpos e separados por cores, provenientes de sobras de confecção. Ideais para patchwork, enchimento ou tear.',
        category: ProductCategory.materiais,
        price: 35.0,
        imageUrl:
            'https://images.unsplash.com/photo-1528458876885-5b6eac83d32b?auto=format&fit=crop&w=700&q=80',
        conditionOrSize: 'Fardo de 5kg • 100% Algodão',
        status: ProductStatus.available,
      ),
    ];
  }

  static List<DonationScheduleModel> getInitialDonations() {
    final now = DateTime.now();

    return [
      DonationScheduleModel(
        id: 'don_1',
        donorUserId: 'usr_mariana',
        donorName: 'Mariana Souza',
        donorPhone: '(11) 98765-4321',
        donorEmail: 'mariana.souza@email.com',
        title: '3 Sacolas de Roupas de Inverno',
        description:
            'Blusas de lã, casacos e calças jeans em ótimo estado de conservação.',
        category: DonationCategory.brecho,
        scheduledDate: now.add(const Duration(days: 2)),
        scheduledTimeSlot: '13:30 - 15:00',
        status: DonationStatus.scheduled,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      DonationScheduleModel(
        id: 'don_2',
        donorUserId: 'usr_roberto',
        donorName: 'Roberto Alves',
        donorPhone: '(11) 99123-4567',
        donorEmail: 'roberto.alves@gmail.com',
        title: 'Lote de 4 Paletes de Madeira',
        description:
            'Paletes de madeira maciça que sobraram de mudança residencial em Mogi.',
        category: DonationCategory.materiais,
        scheduledDate: now.add(const Duration(days: 3)),
        scheduledTimeSlot: '09:00 - 10:30',
        status: DonationStatus.scheduled,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      DonationScheduleModel(
        id: 'don_3',
        donorUserId: 'usr_fernanda',
        donorName: 'Fernanda Lima',
        donorPhone: '(11) 98234-5678',
        donorEmail: 'fe.lima@outlook.com',
        title: 'Calçados e Bolsas de Couro Sintético',
        description: '5 pares de calçados higienizados e 3 bolsas.',
        category: DonationCategory.brecho,
        scheduledDate: now.subtract(const Duration(days: 4)),
        scheduledTimeSlot: '15:00 - 16:30',
        status: DonationStatus.received,
        createdAt: now.subtract(const Duration(days: 6)),
        receivedAt: now.subtract(const Duration(days: 4)),
        receivedByAdminId: 'usr_admin_carlos',
      ),
    ];
  }

  static List<SalesTransactionModel> getInitialTransactions() {
    final now = DateTime.now();

    return [
      SalesTransactionModel(
        id: 'tx_1',
        productId: 'prod_history_1',
        productTitle: 'Cachecol Artesanal em Lã Merino',
        category: ProductCategory.artesanato,
        amount: 50.0,
        paymentMethod: 'PIX IHL',
        buyerUserId: 'usr_mariana',
        buyerName: 'Mariana Souza',
        confirmedByAdminId: 'usr_admin_carlos',
        confirmedAt: now.subtract(const Duration(days: 7)),
      ),
      SalesTransactionModel(
        id: 'tx_2',
        productId: 'prod_history_2',
        productTitle: 'Casaco Sobretudo Preto Vintage',
        category: ProductCategory.brecho,
        amount: 75.0,
        paymentMethod: 'Cartão Débito',
        buyerUserId: 'usr_mariana',
        buyerName: 'Mariana Souza',
        confirmedByAdminId: 'usr_admin_carlos',
        confirmedAt: now.subtract(const Duration(days: 14)),
      ),
      SalesTransactionModel(
        id: 'tx_3',
        productId: 'prod_history_3',
        productTitle: 'Banco Rústico de Jardim com Palete',
        category: ProductCategory.materiais,
        amount: 45.0,
        paymentMethod: 'Dinheiro',
        buyerUserId: 'usr_andre',
        buyerName: 'André Silveira',
        confirmedByAdminId: 'usr_admin_carlos',
        confirmedAt: now.subtract(const Duration(days: 3)),
      ),
    ];
  }
}
