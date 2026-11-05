# IHL CIRCULAR — Aplicativo Móvel & PWA (Flutter)
### Instituto Horizonte Livre • Mogi das Cruzes / SP

O **IHL Circular** é uma solução digital multiplataforma (Android, iOS e Web/PWA) desenvolvida em **Flutter (Dart)** voltada à economia circular, brechó beneficente e geração direta de recursos para terapias de reabilitação (fonoaudiologia, fisioterapia e terapia ocupacional) de Pessoas com Deficiência (PcD).

---

## 🎨 1. Design System & Acessibilidade
- **Paleta de Cores Institucional:**
  - **Azul Institucional IHL:** `#1E3A8A` (Deep Blue) e `#2563EB` (Royal Blue)
  - **Verde Sustentável / Circular:** `#059669` (Emerald Green)
  - **Fundo de Alto Contraste:** `#F8FAFC` (Canvas Claro) e `#0F172A` (Tipografia Primária)
- **Acessibilidade:** Alvos de toque amplos (mínimo 48dp), contraste adequado (WCAG AA), tipografia legível e semântica acessível para leitores de tela.
- **Navegação:** `BottomNavigationBar` fixo no perfil do usuário comum com 3 abas essenciais:
  1. `[ 🏠 Vitrine ]` — Vitrine Digital e busca inteligente
  2. `[ ➕ Doar ]` — Agendamento de doações presenciais
  3. `[ 👤 Meu Perfil ]` — Reservas ativas, cronômetro de 7 dias e governança LGPD

---

## ⚖️ 2. Regras de Negócio Implementadas

| Regra | Descrição | Implementação Técnica |
|---|---|---|
| **1. Reserva com Cronômetro de 7 Dias (168h)** | Ao reservar, o item fica guardado para o comprador por até 168 horas corridas. Se não for pago e retirado na sede, a reserva expira automaticamente e o item retorna à vitrine. | Ticker em tempo real via `Timer.periodic(1s)` no `AppProvider`. Verificação de expiração automática e rotina manual no painel admin. |
| **2. Teto de R$ 50,00 nos Artesanatos PcD** | Peças confeccionadas pelos assistidos possuem valor máximo de R$ 50,00 e **DEVEM** exibir o crédito nominal do autor assistido. | Validação estrita no formulário administrativo (`AddProductDialog`), no repositório (`IhlRepository`) e constraint relacional no PostgreSQL (`CHECK`). Exibição destacada com `PcdAuthorBadge`. |
| **3. Pagamento e Retirada 100% Presenciais** | O app não cobra online. Todo o pagamento (PIX, débito ou dinheiro) e baixa de estoque ocorrem no guichê presencial do IHL em Mogi das Cruzes. | Guichê presencial (`AdminCashierScreen`) com seleção do método de pagamento presencial, baixa relacional de estoque e emissão de recibo digital (`ReceiptDialog`). |
| **4. Governança LGPD** | Coleta estritamente restrita a Nome, E-mail e Celular. Checkbox obrigatório de termos no cadastro e botão nativo para "Excluir Minha Conta". | `LgpdTermsDialog`, validação de aceite no registro e função de exclusão imediata que purga os dados cadastrais e devolve itens reservados à vitrine. |

---

## 📱 3. Arquitetura das 9 Telas

### 🔑 [MÓDULO DE ACESSO]
- **Tela 0 — Login & Cadastro (`login_register_screen.dart`):**
  - Campos: E-mail, Senha.
  - Seletor de Perfil via RadioButton: `Usuário Comum` ou `Administrador`.
  - Formulário expansível de cadastro com Nome, Celular e Checkbox obrigatório dos Termos de Privacidade LGPD.
  - Atalhos de "Acesso Rápido para Avaliação" (Mariana Usuária / Carlos Admin).

### 👕 [MÓDULO DO USUÁRIO COMUM - DOADOR / COMPRADOR]
- **Tela 1.1 — Vitrine Digital / Home (`vitrine_screen.dart`):**
  - Barra de busca superior (`TextField`) e filtros por chips de categoria.
  - **Carrossel 1:** "🎨 Feito por Nossos Assistidos" (com foto, preço R$ e crédito ao autor PcD).
  - **Carrossel 2:** "👕 Garimpo Solidário (Brechó)" (roupas e calçados).
  - **Carrossel 3:** "🪵 Outros Materiais Circulares" (vidro, madeira, paletes).
  - Regra: Oculta automaticamente itens com status "Reservado" ou "Vendido".
- **Tela 1.1.A — Detalhes do Produto (`product_detail_screen.dart`):**
  - Foto expandida, descrição, categoria, valor em R$ e cálculo de impacto em terapias.
  - Cartão de crédito ao assistido autor (para artesanatos) destacando o atendimento clínico.
  - Banner explicativo da retirada presencial em até 7 dias na sede do IHL em Mogi.
  - Botão destacado: `[ 🛒 RESERVAR ESTE ITEM PARA RETIRADA ]`.
- **Tela 1.2 — Quero Doar / Ciclo de Doações (`donate_screen.dart`):**
  - Formulário com upload de imagem, título, descrição e seletor de categoria (`Brechó` ou `Outros Materiais`).
  - Seletor de data (`DatePicker`) e horário (`TimeSlots`) para entrega presencial na sede.
  - Botão: `[ 📅 AGENDAR ENTREGA PRESENCIAL ]`.
  - Histórico de doações agendadas pelo usuário com badges de status.
- **Tela 1.3 — Perfil do Usuário & Impacto Social (`profile_screen.dart`):**
  - Exibição de dados de contato (Nome, E-mail, Celular).
  - Seção **"Minhas Reservas Ativas"**: Lista os itens guardados com cronômetro regressivo em tempo real (`ex: ⏱️ 6 dias, 14 horas e 30 minutos`).
  - Seção **"Seu Impacto Social Histórico"**: Soma o investimento em R$ e calcula automaticamente as **Horas de Terapias de Reabilitação Financiadas** (R$ 50 = 1 hora de terapia clínica).
  - Seção de Governança e botão nativo LGPD: `[ 🗑️ Excluir Minha Conta ]`.

### 💼 [MÓDULO DO ADMINISTRADOR - MONITOR DO IHL]
- **Tela 2 — Painel Administrativo / Home Admin (`admin_dashboard_screen.dart`):**
  - Painel com botões de atalho:
    - `[🔔 Notificações e Agendamentos]`
    - `[💳 Gerenciar Reservas & Baixa]`
    - `[📊 Estatísticas & Faturamento]`
  - Botões diretos de cadastro de estoque por categoria (`🎨 Artesanato PcD`, `👕 Brechó`, `🪵 Outros Materiais`).
  - Botão de manutenção: `[⏰ Liberar Reservas Expiradas]`.
- **Tela 2.2 — Agendamentos de Doações (`admin_donations_screen.dart`):**
  - Lista de doações agendadas pelos doadores via app com filtros (Pendentes, Recebidos, Todos).
  - Informações de contato e data prevista.
  - Botão `[✔️ Marcar como Recebido e Dar Baixa]`.
- **Tela 2.4 — Gerenciamento de Reservas & Baixa de Pagamento (`admin_cashier_screen.dart`):**
  - Guichê de atendimento presencial em Mogi das Cruzes.
  - Lista compradores, itens reservados, cronômetro de 7 dias restante e valores.
  - Botão `[💵 Confirmar Pagamento Presencial e Dar Baixa]`: Altera o status para "Vendido", remove o item da vitrine, credita o impacto de terapias e emite recibo digital.
- **Tela 2.3 — Estatísticas & Faturamento Admin (`admin_statistics_screen.dart`):**
  - Painel com arrecadação total acumulada (R$).
  - Quantidade de peças vendidas por categoria.
  - Indicador de horas de terapia reabilitacional cobertas.
  - Botão `[📥 Exportar Relatório para a Diretoria]` com visualização completa e cópia instantânea para a diretoria.

---

## 🗄️ 4. Banco de Dados Relacional (PostgreSQL / Supabase)
O arquivo `database/schema.sql` contém a estrutura completa para PostgreSQL / Supabase:
- Tabelas: `users`, `products`, `donation_schedules`, `sales_transactions`.
- Constraints de Integridade: `check_artesanato_pcd_rules` (rejeita peças acima de R$ 50 ou sem autor).
- Trigger: `trg_calculate_reservation_expiry` (calcula `expires_at = reserved_at + INTERVAL '168 hours'`).
- Função `release_expired_reservations()` e `delete_user_account_lgpd()`.

---

## 🚀 5. Como Executar

### Pré-requisitos
- Flutter SDK (versão 3.24+)
- Navegador Chrome/Edge ou dispositivo Android/iOS conectado

### Comandos
```bash
# Obter dependências
flutter pub get

# Executar testes automatizados (todas as 4 regras de negócio)
flutter test

# Executar o aplicativo no navegador (PWA / Web)
flutter run -d chrome

# Compilar para produção Web
flutter build web
```
