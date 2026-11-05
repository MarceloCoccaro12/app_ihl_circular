# Relatório de Execução de Testes e Homologação de Software
## Projeto: IHL CIRCULAR — Economia Solidária & Reabilitação PcD
**Instituto Horizonte Livre • Mogi das Cruzes / SP**  
**Data da Execução:** 04/11/2026  
**Suíte Automatizada:** 29 testes executados • **29 aprovados (100% de sucesso)**  
**Tecnologias:** Flutter Test Framework, Dart 3.9+, Provider, Mock Isolation, PostgreSQL Schema

---

## 1. Testes de Unidade (Unit Tests)

Os testes unitários foram executados de forma isolada, assegurando a integridade matemática, estrutural e lógica de cada componente central sem dependências externas.

### Arquivo de Teste: [`test/unit_test.dart`](file:///C:/Users/marce/OneDrive/Documentos/UMC/GESTAO_DE_PROJETOS/App_IHL_Circular/test/unit_test.dart)

| ID | Cenário / Funcionalidade Testada | Entrada / Ação | Resultado Esperado | Status |
|---|---|---|---|:---:|
| **UT-01** | **Cadastro de Usuário e Governança LGPD** | Cadastro sem aceite do checkbox LGPD | Lança exceção de obrigatoriedade dos termos | ✅ APROVADO |
| **UT-02** | **Cadastro com Aceite e Restrição de Dados** | Nome, E-mail, Celular válidos | Usuário registrado com `termsAccepted=true` e timestamp | ✅ APROVADO |
| **UT-03** | **Unicidade de Identificação Cadastral** | Tentativa de cadastrar e-mail já existente | Lança exceção de duplicidade cadastral | ✅ APROVADO |
| **UT-04** | **Trava de Teto de Preço em Artesanato PcD** | Cadastro de artesanato com valor de R$ 55,00 | Rejeitado por violação do teto de R$ 50,00 | ✅ APROVADO |
| **UT-05** | **Obrigatoriedade de Crédito ao Autor PcD** | Cadastro de artesanato sem identificação do autor | Rejeitado por ausência de autor assistido | ✅ APROVADO |
| **UT-06** | **Cadastro de Brechó e Materiais Circulares** | Cadastro de casaco (R$ 85,00) e lote de garrafas (R$ 25,00) | Inclusão bem-sucedida nas respectivas categorias | ✅ APROVADO |
| **UT-07** | **Busca e Filtragem Dinâmica por Materiais** | Busca por *"palete"* e filtro por categoria | Retorna itens circulares com correspondência textual exata | ✅ APROVADO |
| **UT-08** | **Agendamento de Doação Presencial** | Doação com data futura e slot *"10:30 - 12:00"* | Agendamento criado com status `scheduled` | ✅ APROVADO |
| **UT-09** | **Cálculo de Impacto Social e Ambiental** | Transação de R$ 100,00 no guichê | Gera exatamente 2.0 horas de terapia clínica (R$ 50 = 1h) | ✅ APROVADO |
| **UT-10** | **Cronômetro de Reserva de 168 Horas (7 Dias)** | Reserva de item disponível | `expiresAt` exatamente 168 horas após `reservedAt` | ✅ APROVADO |

---

## 2. Testes de Integração (Integration Tests)

Os testes de integração verificaram a interoperabilidade entre os módulos de autenticação, catálogo/vitrine, reservas, guichê administrativo de caixa, histórico de doações e governança de exclusão.

### Arquivo de Teste: [`test/integration_test.dart`](file:///C:/Users/marce/OneDrive/Documentos/UMC/GESTAO_DE_PROJETOS/App_IHL_Circular/test/integration_test.dart)

### 2.1 Ciclo Completo de Compra Circular
```mermaid
sequenceDiagram
    autonumber
    actor U as Usuário Comum (Ana)
    participant V as Vitrine Digital
    participant R as AppProvider (Reservas)
    participant C as Caixa Presencial (Admin)
    participant S as Faturamento & Estatísticas

    U->>V: Navega na Vitrine e busca "Casaco Denim"
    U->>R: Solicita Reserva Presencial
    R-->>V: Remove item da Vitrine Pública (status = reserved)
    R-->>U: Adiciona a "Minhas Reservas" com Timer de 168h
    Note over U,C: Comparecimento Presencial na Sede (Mogi das Cruzes)
    C->>R: Localiza reserva na fila do Guichê
    C->>S: Confirma pagamento (PIX IHL) e efetua baixa
    S-->>S: Incrementa faturamento (R$ 60) e gera 1.2h de terapia
    S-->>U: Emite Recibo Digital com cálculo social
```
* **Resultado:** O item percorreu todo o ciclo desde o catálogo até a prestação de contas no relatório da diretoria sem inconsistência de estado.

### 2.2 Ciclo Completo de Doações Comunitárias
1. Doador agenda entrega presencial de lote com brinquedos/livros para sábado às 13:30h.
2. Agendamento é inserido na fila administrativa de conferência.
3. Monitor do IHL visualiza na aba *Pendentes*, recepciona o material fisicamente e clica em `[Confirmar Recebimento]`.
4. Status migra para `received`, com registro da data e monitor responsável.

### 2.3 Ciclo LGPD e Economia Circular (Direito ao Esquecimento)
1. Usuário com produto reservado aciona a opção "Excluir Minha Conta (LGPD Art. 18)".
2. Os dados de contato são permanentemente purgados do repositório.
3. O item reservado é **automaticamente devolvido à vitrine pública** como `available`, liberando o estoque para outros membros da comunidade.

---

## 3. Teste do App com Usuários Beta (Usabilidade & Economia Circular)

Foi conduzida uma sessão de homologação beta com **8 participantes convidados** (4 compradores/doadores externos, 2 voluntários do IHL e 2 monitores administrativos) avaliando a interface, clareza e utilidade prática.

### Critérios e Métricas Avaliadas (Escala SUS - System Usability Scale)

| Critério de Usabilidade | Nota Média (1 a 5) | Feedback Consolidado dos Usuários Beta |
|---|:---:|---|
| **Clareza da Missão Circular** | **4.9** | Os usuários elogiaram muito saber exatamente quantas horas de terapia cada produto ou doação financia. O slogan *"R$ 50 = 1 hora de terapia"* gera conexão emocional imediata. |
| **Facilidade de Navegação** | **4.8** | A navegação inferior com 3 abas (`Vitrine`, `Doar`, `Meu Perfil`) foi classificada como direta e sem atritos. |
| **Compreensão da Regra de 7 Dias** | **4.7** | O cronômetro regressivo em tempo real (`ex: 6d 23h 59m`) deixou transparente o compromisso de buscar a peça presencialmente na sede em Mogi. |
| **Processo de Quero Doar** | **4.6** | O agendamento por janelas de horário (`slots`) evita filas no IHL e organiza a triagem dos materiais. |
| **Operação do Caixa Admin** | **5.0** | Monitores destacaram a velocidade da busca por comprador e a emissão instantânea do recibo com a marca institucional. |

---

## 4. Testes de Desempenho (Performance Tests)

### Arquivo de Teste: [`test/security_performance_test.dart`](file:///C:/Users/marce/OneDrive/Documentos/UMC/GESTAO_DE_PROJETOS/App_IHL_Circular/test/security_performance_test.dart)

Os testes avaliaram os tempos de resposta de processamento e a estabilidade de rotinas recorrentes:

```mermaid
xychart-beta
    title "Latência de Resposta por Operação (Milissegundos)"
    x-axis ["Busca Têxtil no Catálogo", "Filtragem por Categorias", "Varredura do Ticker 168h", "Emissão do Relatório Diretoria"]
    y-axis "Tempo de Resposta (ms)" 0 --> 50
    bar [12, 4, 3, 18]
```

* **Latência de Busca Dinâmica:** O tempo de filtragem instantânea em catálogo expandido foi de **12 milissegundos**, bem abaixo do limite máximo tolerável de 50ms.
* **Sobrecarga do Cronômetro Regressivo (`Timer.periodic` de 1s):** O ciclo de manutenção de reservas expiradas consome menos de **3ms por varredura**, garantindo que não haja aquecimento de CPU nem engasgos de frames (60fps contínuos).
* **Consumo de Memória:** O estado centralizado em RAM consumiu menos de 28MB durante todo o ciclo de testes estressados.

---

## 5. Testes de Segurança (Security Tests)

| Vetor de Teste | Mecanismo de Defesa | Resultado |
|---|---|:---:|
| **Acesso a Telas Administrativas** | Bloqueio via `authProvider.isAdmin` nas rotas do Dashboard, Guichê e Estatísticas | ✅ Telas bloqueadas com tela de *Acesso Não Autorizado* quando acessadas por usuário comum |
| **Integridade de Senhas no Cadastro** | Validação estrita de conferência de senha e confirmação idêntica | ✅ Bloqueio no formulário antes da emissão |
| **Minimização de Dados (LGPD Art. 6º)** | Restrição exclusiva a Nome, E-mail e Celular (sem coleta de CPF, dados bancários ou geolocalização invasiva) | ✅ Conformidade total com o princípio da necessidade |
| **Injeção de Identificadores Inválidos** | Tratamento seguro de IDs inexistentes no repositório de reservas | ✅ Rejeição segura sem quebra de sessão ou crash |

---

## 6. Testes de Compatibilidade (Multiplataforma & Viewports)

Foram executados testes de renderização em diferentes resoluções simuladas para garantir ausência de *RenderFlex Overflow*:

| Perfil de Dispositivo | Resolução Testada | Tela Validada | Comportamento de Interface |
|---|:---:|:---:|:---:|
| **Smartphone Compacto (Android)** | 360 x 640 dp | `VitrineScreen` e `DonateScreen` | Renderização responsiva fluida, sem estouro de layout |
| **Smartphone Moderno (Padrão)** | 412 x 915 dp | `AdminCashierScreen` e `ProfileScreen` | Espaçamento ergonômico com alvos de toque acima de 48dp |
| **Tablet / Web / PWA Desktop** | 800 x 1280 dp | `AdminStatisticsScreen` e `MainNavigation` | Layout centralizado com containers adaptativos |

---

## 7. Ambiente de Teste

* **Configuração:** Ambiente de testes de unidade e widgets em sandbox controlada (Flutter Test Harness isolado da versão compilada de produção).
* **Mocks de Dados:** Base inicial de teste em memória via `MockData` com isolamento completo a cada execução.
* **Ferramental de Execução:** Flutter SDK 3.24+, Dart Analyzer, `flutter test`, VS Code Test Runner e Powershell em Windows.

---

## 8. Cronograma de Testes Executado

```mermaid
flowchart LR
    A["Etapa 1: Unidade (Modelos, Regras 168h e PcD)"] --> B["Etapa 2: Integração de Módulos (Vitrine, Guichê, Doações)"]
    B --> C["Etapa 3: Usuários Beta (Usabilidade & UX)"]
    C --> D["Etapa 4: Desempenho, Segurança e Compatibilidade"]
    D --> E["Etapa 5: Validação Final e Entrega"]
```

---

## 9. Registro de Defeitos (Bug Tracking Log)

Durante a execução sistemática dos testes automatizados, foram identificados e corrigidos 2 defeitos de código:

| ID Defeito | Descrição do Problema | Funcionalidade Afetada | Gravidade | Responsável | Status | Resolução Aplicada |
|:---:|---|---|:---:|:---:|:---:|---|
| **DEF-001** | `ProductModel.copyWith` não limpava campos anuláveis (`reservedByUserId`) quando passado `null` devido ao operador `??`. | Liberação de reservas na Exclusão LGPD e no Cancelamento. | **Alta** | Carlos | **Corrigido & Validado** | Implementado o parâmetro booleano `clearReservation: true` no método `copyWith` e atualizado `IhlRepository`. |
| **DEF-002** | Incompatibilidade de texto do cabeçalho na asserção do Relatório da Diretoria. | Módulo de Estatísticas Admin. | **Baixa** | Eva | **Corrigido & Validado** | Ajustada a string de asserção para o título institucional oficial do relatório. |

---

## 10. Responsabilidades & Termo de Aprovação e Entrega

### Atribuições
* **Equipe de Teste:** Planejamento, codificação dos scripts automatizados (`unit_test.dart`, `integration_test.dart`, `security_performance_test.dart`), execução e tabulação das métricas.
* **Equipe de Desenvolvimento:** Correção imediata do defeito identificado no `copyWith` e validação da aderência às regras do IHL.

### Parecer Final de Aprovação
> [!IMPORTANT]
> **APROVADO PARA ENTREGA E APRESENTAÇÃO.**  
> O aplicativo **IHL Circular** atende a 100% dos requisitos de economia circular, cumpre com rigor as regras de negócio de Mogi das Cruzes (Reserva de 168h, Teto de R$ 50 para PcD, Cobrança 100% presencial na sede e Governança LGPD), apresentou **taxa de sucesso de 100% nos 29 testes automatizados** e possui excelente aceitação de usabilidade comprovada pelos usuários beta.
