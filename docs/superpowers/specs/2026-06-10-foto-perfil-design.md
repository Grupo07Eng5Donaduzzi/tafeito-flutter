# Design: Upload de Foto de Perfil

**Data:** 2026-06-10
**Branch:** feat/foto-perfil
**Repos afetados:** tafeito-api, tafeito-flutter

---

## Contexto

A `ProfilePage` já tem seleção de imagem via `image_picker` e preview local (`_profileImageBytes`). Falta o upload para a API e persistência da URL no perfil do usuário.

A API não possui endpoint de foto nem campo `photoUrl` em nenhuma camada.

---

## Abordagem escolhida

**Multipart endpoint na API** — `PATCH /v1/users/:id/photo` com `multipart/form-data`. A API armazena o arquivo em disco (`uploads/profiles/`) e serve os arquivos como assets estáticos. Flutter faz upload imediatamente após o usuário selecionar a imagem.

---

## API (tafeito-api)

### Novo endpoint

```
PATCH /v1/users/:id/photo
Content-Type: multipart/form-data
Campo: photo (arquivo de imagem)
```

- Multer disk storage: `uploads/profiles/<uuid>.<ext>`
- Tipos aceitos: `image/jpeg`, `image/png`, `image/webp`
- Tamanho máximo: 5MB
- Retorna: `UserDto` atualizado com `photoUrl`
- A API serve `/uploads/*` como assets estáticos via `useStaticAssets`

### Arquivos alterados

| Arquivo | Mudança |
|---|---|
| `user.schema.ts` | + coluna `photo_url text` |
| `user.entity.ts` | + `_photoUrl`, getter, `withPhotoUrl()` |
| `user.dto.ts` | + campo `photoUrl` |
| `drizzle-user.repository.ts` | `update()` persiste `photoUrl`; `find*` mapeia `photoUrl` |
| `user.service.ts` | + `uploadPhoto(id, file)` |
| `users.controller.ts` | + `@Patch(':id/photo')` com `FileInterceptor('photo')` |
| `main.ts` | `app.useStaticAssets(join(__dirname, '..', 'uploads'), { prefix: '/uploads' })` |
| nova migration | `ALTER TABLE users ADD COLUMN photo_url text` |

### Validações no endpoint

- Arquivo ausente → 400
- Tipo inválido → 400
- Tamanho > 5MB → 413
- Usuário não encontrado → 404

---

## Flutter (tafeito-flutter)

### Fluxo de UX

1. Usuário toca no ícone de editar foto
2. Modal com opções: Galeria / Câmera
3. Imagem selecionada → preview local imediato (`MemoryImage`)
4. Upload dispara automaticamente (sem botão extra)
5. Indicador de loading no avatar durante upload
6. `CircleAvatar` atualiza com URL do servidor ao concluir

### Lógica do CircleAvatar

```
_profileImageBytes != null → MemoryImage (preview local)
me?.photoUrl != null       → NetworkImage(photoUrl)
else                       → ícone placeholder
```

### Arquivos alterados

| Arquivo | Mudança |
|---|---|
| `api_client.dart` | + `postMultipart(path, bytes, filename, mimeType)` usando `http.MultipartRequest` |
| `user_dto.dart` | + campo `photoUrl` no construtor e `fromJson` |
| `profile_repository.dart` | + `uploadPhoto({id, bytes, filename})` → `Result<UserDto>` |
| `profile_repository_impl.dart` | implementa `uploadPhoto` via datasource |
| `profile_remote_data_source.dart` | + `uploadPhoto(id, bytes, filename)` |
| `profile_view_model.dart` | + `uploadPhoto(bytes, filename)`, + `isUploadingPhoto` |
| `profile_page.dart` | modal inclui câmera; após pick chama `uploadPhoto`; avatar mostra loading e usa `photoUrl` |

### Tratamento de erros

- Falha no upload: exibe `SnackBar` com mensagem de erro; preview local é removido (avatar volta ao estado anterior)
- Upload em andamento: ícone de editar desabilitado, overlay de loading no avatar

---

## Fora do escopo

- Crop/redimensionamento da imagem no cliente
- Remoção de foto de perfil
- Migração de fotos existentes
