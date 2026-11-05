import 'package:flutter_test/flutter_test.dart';
import 'package:ihl_circular/models/product_model.dart';
import 'package:ihl_circular/models/donation_model.dart';
import 'package:ihl_circular/models/user_model.dart';
import 'package:ihl_circular/services/ihl_repository.dart';

void main() {
  group('1. Testes de Unidade - IHL Circular', () {
    late IhlRepository repository;

    setUp(() {
      repository = IhlRepository();
    });

    test('1.1 Cadastro de Usuário e Governança LGPD (Nome, E-mail, Celular)', () {
      final testEmail = 'voluntario_${DateTime.now().millisecondsSinceEpoch}@ihl.org.br';
      
      // Validação de rejeição sem aceite dos termos LGPD
      expect(
        () => repository.registerUser(
          name: 'Voluntário Teste',
          email: testEmail,
          phone: '(11) 98765-0000',
          role: UserRole.comum,
          termsAccepted: false,
        ),
        throwsException,
      );

      // Cadastro válido com consentimento
      final user = repository.registerUser(
        name: 'Voluntário Teste',
        email: testEmail,
        phone: '(11) 98765-0000',
        role: UserRole.comum,
        termsAccepted: true,
      );

      expect(user.id, isNotEmpty);
      expect(user.name, equals('Voluntário Teste'));
      expect(user.email, equals(testEmail));
      expect(user.phone, equals('(11) 98765-0000'));
      expect(user.termsAccepted, isTrue);
      expect(user.termsAcceptedAt, isNotNull);

      // Rejeição de duplicidade de e-mail
      expect(
        () => repository.registerUser(
          name: 'Duplicado',
          email: testEmail,
          phone: '(11) 91111-2222',
          role: UserRole.comum,
          termsAccepted: true,
        ),
        throwsException,
      );
    });

    test('1.2 Publicação de Item no Estoque Circular & Validação de Teto PcD', () {
      // 1.2.1 Rejeição de Artesanato PcD acima de R$ 50,00
      expect(
        () => repository.addProduct(
          title: 'Escultura Decorativa',
          description: 'Peça de argila',
          category: ProductCategory.artesanato,
          price: 55.00,
          imageUrl: 'https://sample.com/escultura.jpg',
          authorPcd: 'Carlos E.',
        ),
        throwsException,
      );

      // 1.2.2 Rejeição de Artesanato PcD sem autor assistido
      expect(
        () => repository.addProduct(
          title: 'Cachepot Cerâmica',
          description: 'Sem identificação do autor assistido',
          category: ProductCategory.artesanato,
          price: 30.00,
          imageUrl: 'https://sample.com/cachepot.jpg',
          authorPcd: '',
        ),
        throwsException,
      );

      // 1.2.3 Cadastro Válido de Artesanato PcD (<= R$ 50 com autor)
      final artProduct = repository.addProduct(
        title: 'Mosaico Sustentável',
        description: 'Mosaico feito com sobras de cerâmica do Alto Tietê',
        category: ProductCategory.artesanato,
        price: 49.90,
        imageUrl: 'https://sample.com/mosaico.jpg',
        authorPcd: 'Felipe A. (Oficina Mosaico IHL)',
        conditionOrSize: 'Peça Única • 30x30cm',
      );
      expect(artProduct.id, isNotEmpty);
      expect(artProduct.isAvailable, isTrue);
      expect(artProduct.authorPcd, equals('Felipe A. (Oficina Mosaico IHL)'));

      // 1.2.4 Cadastro de Peça de Brechó (sem teto de 50)
      final brechoProduct = repository.addProduct(
        title: 'Sobretudo de Lã Vintage',
        description: 'Peça garimpada para o brechó em excelente estado',
        category: ProductCategory.brecho,
        price: 85.00,
        imageUrl: 'https://sample.com/sobretudo.jpg',
        conditionOrSize: 'Tamanho G',
      );
      expect(brechoProduct.category, equals(ProductCategory.brecho));
      expect(brechoProduct.price, equals(85.00));

      // 1.2.5 Cadastro de Materiais Circulares (paletes, garrafas para upcycling)
      final matProduct = repository.addProduct(
        title: 'Lote de 10 Garrafas Âmbar',
        description: 'Garrafas esterilizadas prontas para artesanato',
        category: ProductCategory.materiais,
        price: 25.00,
        imageUrl: 'https://sample.com/garrafas.jpg',
      );
      expect(matProduct.category, equals(ProductCategory.materiais));
    });

    test('1.3 Busca Dinâmica por Materiais e Filtragem por Categoria', () {
      final resultsAll = repository.getAvailableProducts();
      expect(resultsAll.isNotEmpty, isTrue);

      // Busca textual por 'palete' ou 'garrafa'
      final searchPalete = resultsAll.where((p) =>
        p.title.toLowerCase().contains('palete') ||
        p.description.toLowerCase().contains('palete')
      ).toList();
      expect(searchPalete.isNotEmpty, isTrue);
      expect(searchPalete.first.category, equals(ProductCategory.materiais));

      // Filtragem por categoria de brechó
      final brechoOnly = resultsAll.where((p) => p.category == ProductCategory.brecho).toList();
      expect(brechoOnly.every((p) => p.category == ProductCategory.brecho), isTrue);
    });

    test('1.4 Agendamento de Doação Presencial de Materiais/Brechó', () {
      final scheduleDate = DateTime.now().add(const Duration(days: 3));
      final donation = repository.scheduleDonation(
        donorUserId: 'usr_mariana',
        donorName: 'Mariana Souza',
        donorPhone: '(11) 98765-4321',
        donorEmail: 'mariana.souza@email.com',
        title: 'Caixa de Roupas Infantis',
        description: 'Roupas higienizadas para o brechó beneficente',
        category: DonationCategory.brecho,
        scheduledDate: scheduleDate,
        scheduledTimeSlot: '10:30 - 12:00',
        imageUrl: 'https://sample.com/doacao.jpg',
      );

      expect(donation.id, isNotEmpty);
      expect(donation.status, equals(DonationStatus.scheduled));
      expect(donation.isScheduled, isTrue);
      expect(donation.scheduledTimeSlot, equals('10:30 - 12:00'));
    });

    test('1.5 Cálculo de Impacto Social e Ambiental (Horas de Terapias de Reabilitação)', () {
      // Regra de impacto: R$ 50,00 arrecadados financiam 1 hora de terapia clínica de reabilitação PcD
      const valorArrecadado1 = 50.00;
      expect(valorArrecadado1 / 50.0, equals(1.0)); // 1 hora exata

      const valorArrecadado2 = 125.00;
      expect(valorArrecadado2 / 50.0, equals(2.5)); // 2 horas e meia

      // Cria um item dedicado para garantir disponibilidade
      final item = repository.addProduct(
        title: 'Item Para Teste de Impacto',
        description: 'Desc',
        category: ProductCategory.brecho,
        price: 100.0,
        imageUrl: 'https://sample.com/img.jpg',
      );

      repository.reserveProduct(
        productId: item.id,
        userId: 'usr_mariana',
        userName: 'Mariana Souza',
      );

      final tx = repository.confirmPaymentAndFulfill(
        productId: item.id,
        paymentMethod: 'PIX IHL',
        adminId: 'admin_carlos',
      );

      expect(tx.therapyHoursGenerated, equals(2.0)); // 100 / 50 = 2 horas
    });

    test('1.6 Regra do Cronômetro de Reserva de 168 Horas (7 Dias) e Expiração', () {
      // Cria um item novo dedicado para o teste do cronômetro
      final item = repository.addProduct(
        title: 'Item Cronômetro 168h',
        description: 'Desc',
        category: ProductCategory.materiais,
        price: 30.0,
        imageUrl: 'https://sample.com/img.jpg',
      );

      final success = repository.reserveProduct(
        productId: item.id,
        userId: 'usr_cronometro',
        userName: 'Comprador Cronômetro',
      );
      expect(success, isTrue);

      final reserved = repository.getAllProducts().firstWhere((p) => p.id == item.id);
      expect(reserved.isReserved, isTrue);
      expect(reserved.reservedAt, isNotNull);
      expect(reserved.expiresAt, isNotNull);
      
      // Confirma que a validade é de exatamente 168 horas (7 dias)
      final hours = reserved.expiresAt!.difference(reserved.reservedAt!).inHours;
      expect(hours, equals(168));
    });
  });
}
