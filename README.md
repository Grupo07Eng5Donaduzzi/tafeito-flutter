# TaFeito Flutter

Aplicativo Flutter para contratacao e oferta de servicos. O app permite que um usuario comum explore servicos, solicite orcamentos, acompanhe propostas, converse pelo chat, aceite propostas e consulte pagamento Pix. O usuario tambem pode se tornar prestador informando uma chave Pix e um valor por hora, passando a cadastrar servicos e responder solicitacoes.

## Como executar

Pre-requisitos:

- Flutter SDK instalado.
- Dispositivo, emulador ou navegador Chrome configurado.
- Acesso a internet para consumir as APIs remotas.

Instale as dependencias:

```bash
flutter pub get
```

Execute no navegador:

```bash
flutter run -d chrome
```

Tambem e possivel informar as URLs das APIs por `--dart-define`:

```bash
flutter run -d chrome \
  --dart-define=TAFEITO_MAIN_API_BASE_URL=https://tafeito.rietto.com/main \
  --dart-define=TAFEITO_CHAT_API_BASE_URL=https://tafeito.rietto.com/chat \
  --dart-define=TAFEITO_PAYMENTS_API_BASE_URL=https://tafeito.rietto.com/payments
```

## Arquitetura e padrao escolhido

O projeto utiliza **MVVM**:

- **Model:** DTOs e entidades em `data/models` e `domain/entities`.
- **View:** telas e widgets em `presentation/views` e `presentation/widgets`.
- **ViewModel:** classes em `presentation/viewmodels`, responsaveis por estado, validacao e chamadas aos repositorios.

Alem do MVVM, o projeto usa o padrao **Repository** com **DataSource** para isolar a interface das chamadas HTTP. Tambem usa **Observer** por meio de `ChangeNotifier`, permitindo que as telas reajam a estados de carregamento, sucesso e erro sem concentrar regra de negocio na UI.

## API utilizada

O app consome APIs remotas reais do TaFeito:

- API principal: `https://tafeito.rietto.com/main`
- API de chat: `https://tafeito.rietto.com/chat`
- API de pagamentos: `https://tafeito.rietto.com/payments`

Principais recursos consumidos:

- Autenticacao e cadastro de usuario via API principal.
- Perfil e upload de avatar.
- Marketplace e cadastro de servicos.
- Solicitacao e envio de orcamentos.
- Propostas, aceite e consulta de pagamento Pix.
- Conversas e mensagens de chat.

As chamadas HTTP ficam centralizadas em `HttpApiClient`, e os caminhos de API ficam em `lib/src/core/network/api_paths.dart`.

## Armazenamento local

O app usa `flutter_secure_storage` para persistir dados de sessao, incluindo o JWT de acesso e dados basicos do usuario autenticado.

A persistencia local e implementada em `AuthLocalDataSource` e usada pelo `SessionManager`. Ao abrir o app, o `SessionManager` recupera a sessao salva, valida o token e decide se o usuario deve ir para a tela de login ou para a area autenticada.

Esse armazenamento e util para manter o usuario logado entre execucoes do aplicativo e proteger rotas que exigem autenticacao.
