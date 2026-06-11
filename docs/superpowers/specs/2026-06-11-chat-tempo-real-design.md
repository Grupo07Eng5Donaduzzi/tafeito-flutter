# Chat em Tempo Real (feat/chat) — Design

**Data:** 2026-06-11
**Branch:** `feat/chat`
**Repositório:** tafeito-flutter (somente Flutter; API já pronta)

## Objetivo

Tela de mensagens em tempo real entre cliente e prestador, conectando ao gateway WebSocket (socket.io) já existente no tafeito-api. Envio, recebimento e atualização automática de mensagens.

## Escopo

**Incluído:**
- Tela de thread (conversa aberta) com bolhas de mensagem e campo de envio.
- Carregamento de histórico via REST ao abrir.
- Conexão WebSocket com autenticação por token, recebimento ao vivo.
- Ponto de entrada: botão "Conversar" em cada card da lista Explorar (`services_page`).

**Fora de escopo (adiado):**
- Inbox (tab "Chat" lista todas conversas) — exige endpoint novo na API (`listar conversas por participante`). Permanece como placeholder.
- Tela "Em andamento" (Oferecer/Contratar/Explorar/Em andamento) — outra feature.
- Indicador de digitação — branch separada `feat/Indicador-chat`, monta em cima desta.
- Status de leitura/entrega visual (read receipts) — API suporta, mas não exibido nesta branch.

## Contexto da API (já implementada)

**WebSocket** — namespace `/chat`, socket.io, auth via token no handshake (`handshake.query.token` ou header `Authorization: Bearer`).

Cliente emite:
- `join-service` `{ serviceId }` — entra na sala do serviço.
- `send-message` `{ serviceId, recipientId, content }` — envia mensagem.
- `leave-service` — sai da sala.

Servidor emite (para a sala `serviceId`):
- `new-message` `{ message, timestamp }` — broadcast para **todos na sala, incluindo o remetente**.
- `error` `{ message }`.

**REST** (histórico) — `GET /chat/services/:serviceId/messages?page=1&pageSize=50`
Retorna `MessageListDto`: `{ data: Message[], total, page, pageSize, hasMore }`.

**Formato Message:**
```
{ id, serviceId, conversationId?, senderId, recipientId, content, status: 'sent'|'delivered'|'read', createdAt, updatedAt }
```

Base URL da API: `https://tafeito.rietto.com` (rotas REST com prefixo `/v1`). WS local: `http://localhost:3000` namespace `/chat`.

## Arquitetura

Feature vertical em `lib/src/features/chat/`, seguindo o padrão existente (data/domain/presentation, viewmodel `ChangeNotifier`).

```
lib/src/features/chat/
  data/
    datasources/
      chat_socket_data_source.dart    # wrapper socket_io_client
      chat_remote_data_source.dart     # histórico REST via ApiClient
    models/
      chat_message_dto.dart
    repositories/
      chat_repository_impl.dart
  domain/
    entities/
      chat_message.dart
    repositories/
      chat_repository.dart
  presentation/
    viewmodels/
      chat_thread_view_model.dart
    views/
      chat_thread_page.dart
```

### Unidades e responsabilidades

**`ChatMessage` (entity)** — modelo de domínio imutável.
Campos: `id`, `serviceId`, `senderId`, `recipientId`, `content`, `status`, `createdAt`.
Método auxiliar nenhum; comparação por `id`.

**`ChatMessageDto`** — parse de JSON (REST e evento WS) → `ChatMessage`. Tolerante a `snake_case`/`camelCase` (a API serializa camelCase, mas datas vêm como ISO string).

**`ChatRemoteDataSource`** — interface + impl com `ApiClient`.
- `Future<List<ChatMessage>> getServiceMessages(String serviceId, {int page, int pageSize})`.

**`ChatSocketDataSource`** — wrapper sobre `socket_io_client`.
- `void connect(String token)` — abre socket no namespace `/chat` com `transports: ['websocket']` e `auth/query: { token }`.
- `void joinService(String serviceId)` — emit `join-service`.
- `void sendMessage({ required String serviceId, required String recipientId, required String content })` — emit `send-message`.
- `Stream<ChatMessage> get onNewMessage` — escuta evento `new-message`, mapeia `message` → `ChatMessage`.
- `Stream<String> get onError` — escuta `error`.
- `void dispose()` — fecha socket e streams.

**`ChatRepository`** (interface) + `ChatRepositoryImpl` — orquestra REST + socket.
- `Future<List<ChatMessage>> loadHistory(String serviceId)`.
- `void connect(String token)`, `void joinService(String serviceId)`.
- `void sendMessage({serviceId, recipientId, content})`.
- `Stream<ChatMessage> get messages`.
- `Stream<String> get errors`.
- `void dispose()`.

**`ChatThreadViewModel`** (`ChangeNotifier`) — estado da tela.
- Campos: `List<ChatMessage> messages`, `bool isLoading`, `String? errorMessage`.
- `Future<void> init(String serviceId, String token)` — carrega histórico, conecta, join, assina stream `messages` (append + dedupe por `id`), assina `errors`.
- `void send(String content)` — valida não-vazio, emit via repo. **Não** adiciona otimista; a mensagem aparece quando o servidor rebroadcasta `new-message` (servidor inclui o remetente na sala).
- `dispose()` — cancela subscriptions, `repo.dispose()`.

**`ChatThreadPage`** (`StatefulWidget`) — UI.
- Params: `serviceId`, `recipientId`, `title` (nome do serviço), `currentUserId`, `token`, e a fábrica/instância do `ChatRepository`.
- `AppBar` branca, botão voltar, título = nome do serviço.
- Corpo: `ListView` de bolhas (auto-scroll ao chegar nova). Bolha: `senderId == currentUserId` → direita, fundo azul `AppTheme.primary` (#2563EB), texto branco; senão → esquerda, fundo `#F3F4F6`, texto escuro. Hora (`HH:mm`) pequena abaixo.
- Rodapé: `TextField` "Mensagem..." + botão enviar (ícone seta, azul). Enter ou botão envia; limpa campo.
- Estados: loading inicial (spinner centralizado), erro (mensagem + retry), lista vazia ("Nenhuma mensagem ainda").

### Wiring

- `pubspec.yaml`: adicionar `socket_io_client: ^2.0.3`.
- `app.dart`: construir base do WS a partir de `String.fromEnvironment('TAFEITO_WS_BASE_URL', defaultValue: 'https://tafeito.rietto.com')`; injetar token via `sessionManager.session?.accessToken` e `currentUserId` via `sessionManager.session?.user.id`.
- `service_dto.dart`: adicionar campo `providerId` (parse `json['userId'] ?? json['user_id']`).
- `services_page.dart`: no `_ServiceTile`, adicionar botão "Conversar" → `Navigator.push` para `ChatThreadPage` com `serviceId = service.id`, `recipientId = service.providerId`, `title = service.name`.

## Fluxo de dados

1. Usuário toca "Conversar" no card → push `ChatThreadPage`.
2. `initState` → `viewModel.init(serviceId, token)`:
   a. `loadHistory` (REST) → popula `messages`, ordena por `createdAt` asc.
   b. `connect(token)` → socket abre no `/chat`.
   c. `joinService(serviceId)`.
   d. assina `messages` stream.
3. Usuário digita e envia → `viewModel.send(content)` → repo emit `send-message`.
4. Servidor persiste e emite `new-message` para a sala (inclui remetente).
5. `onNewMessage` → viewModel append (dedupe por `id`) → `notifyListeners` → UI rola para o fim.
6. Ao sair da tela → `dispose` → `leave`/fecha socket.

## Tratamento de erros

- Falha no histórico REST → estado de erro com botão "Tentar novamente".
- Evento `error` do socket → `errorMessage` exibido via `SnackBar`, não derruba a tela.
- Desconexão do socket → `socket_io_client` reconecta automaticamente (default); ao reconectar, re-emitir `join-service`. Histórico não é recarregado (mensagens perdidas durante a queda são raras no MVP; aceitável).
- Conteúdo vazio/whitespace → `send` ignora.

## Testes

Dado o padrão do projeto (sem suíte de testes de UI ampla), foco em testes de unidade nas unidades testáveis sem rede:

- `ChatMessageDto.fromJson` — parse de payload REST e de evento WS, datas ISO, campos ausentes.
- `ChatThreadViewModel` com `ChatRepository` fake (streams controláveis):
  - `init` carrega histórico e popula `messages`.
  - mensagem nova via stream faz append.
  - dedupe: mesma `id` chegando duas vezes não duplica.
  - `send` com conteúdo vazio não chama o repo; com conteúdo válido chama `sendMessage`.
- `dispose` cancela subscriptions (sem callbacks após dispose).

`ChatSocketDataSource` (integração real com socket.io) não é coberto por teste automatizado — validação manual contra o backend local.

## Validação manual

1. Rodar API local (`localhost:3000`) com DB.
2. Rodar Flutter com `--dart-define=TAFEITO_WS_BASE_URL=http://localhost:3000` e base REST local.
3. Dois usuários logados (dois navegadores/dispositivos), abrir a mesma thread de serviço.
4. Enviar mensagem de A → aparece em A e B em tempo real.
5. Histórico persiste ao reabrir a tela.

## Decisões e premissas

- **Sem mensagem otimista:** renderiza só do echo `new-message` do servidor (fonte única de verdade). Latência mínima aceitável; evita lógica de dedupe entre temp e persistida.
- **Título da AppBar = nome do serviço:** `ServiceDto` não traz nome do prestador. Quando a tela "Em andamento" expuser o nome do outro participante, pode-se passar `title` mais preciso.
- **WS prod via nginx:** requer proxy de upgrade WebSocket em `/socket.io` (configuração de ops, fora deste código). Local funciona direto.
- **`leave-service` no dispose:** opcional; fechar o socket já remove das salas. Emitido por clareza.
