# Profile Photo Upload Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Adicionar upload de foto de perfil — endpoint multipart na API armazena arquivos em disco, Flutter faz pick + upload imediato com preview local.

**Architecture:** API expõe `PATCH /v1/users/:id/photo` (multipart/form-data), salva arquivos em `uploads/profiles/`, serve via static assets. Flutter usa `http.MultipartRequest` para upload logo após o pick, persiste a URL retornada em `UserDto.photoUrl`.

**Tech Stack:** NestJS + Multer + Drizzle/PostgreSQL (API); Flutter + http package + image_picker (cliente)

**Repos:**
- API: `C:\Users\gabry\Documents\top\tafeito-api`
- Flutter: `C:\Users\gabry\Documents\top\tafeito-flutter`

---

## File Map

### tafeito-api
| Arquivo | Ação |
|---|---|
| `src/modules/users/infra/schemas/user.schema.ts` | Modify — coluna `photo_url` |
| `drizzle/0013_add_photo_url_to_users.sql` | Create — migration |
| `src/modules/users/domain/models/user.entity.ts` | Modify — `_photoUrl`, `withPhotoUrl()` |
| `src/modules/users/application/dto/user.dto.ts` | Modify — campo `photoUrl` |
| `src/modules/users/infra/repositories/drizzle-user.repository.ts` | Modify — persiste e mapeia `photoUrl` |
| `src/modules/users/application/services/user.service.ts` | Modify — `uploadPhoto()` |
| `src/modules/users/infra/controllers/users.controller.ts` | Modify — `PATCH :id/photo` |
| `src/main.ts` | Modify — `useStaticAssets` |

### tafeito-flutter
| Arquivo | Ação |
|---|---|
| `lib/src/core/network/api_client.dart` | Modify — `postMultipart()` |
| `lib/src/features/profile/data/models/user_dto.dart` | Modify — `photoUrl` |
| `lib/src/features/profile/domain/repositories/profile_repository.dart` | Modify — `uploadPhoto()` |
| `lib/src/features/profile/data/repositories/profile_repository_impl.dart` | Modify — implementa `uploadPhoto` |
| `lib/src/features/profile/data/datasources/profile_remote_data_source.dart` | Modify — `uploadPhoto()` |
| `lib/src/features/profile/presentation/viewmodels/profile_view_model.dart` | Modify — `uploadPhoto()`, `isUploadingPhoto`, `uploadError` |
| `lib/src/features/auth/presentation/views/profile_page.dart` | Modify — câmera no modal, trigger upload, avatar loading |

---

## Task 1: Schema + Migration (API)

**Files:**
- Modify: `tafeito-api/src/modules/users/infra/schemas/user.schema.ts`
- Create: `tafeito-api/drizzle/0013_add_photo_url_to_users.sql`

- [ ] **Step 1: Adicionar coluna no schema Drizzle**

Substituir todo o conteúdo de `user.schema.ts`:

```typescript
import { numeric, pgTable, text, timestamp, uuid } from 'drizzle-orm/pg-core';

export const usersSchema = pgTable('users', {
  id: uuid('id').primaryKey().defaultRandom(),
  firebaseUid: text('firebase_uid').notNull().unique(),
  name: text('name').notNull(),
  email: text('email').notNull().unique(),
  identification: text('identification').notNull().unique(),
  pixKey: text('pix_key'),
  hourlyRate: numeric('hourly_rate', { precision: 10, scale: 2 }),
  photoUrl: text('photo_url'),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull(),
});
```

- [ ] **Step 2: Criar migration SQL**

Criar `tafeito-api/drizzle/0013_add_photo_url_to_users.sql`:

```sql
ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "photo_url" text;
```

- [ ] **Step 3: Rodar migration**

```bash
cd tafeito-api
npx drizzle-kit migrate
```

Esperado: migration aplicada sem erros.

- [ ] **Step 4: Commit**

```bash
cd tafeito-api
git add src/modules/users/infra/schemas/user.schema.ts drizzle/0013_add_photo_url_to_users.sql
git commit -m "feat(users): add photo_url column to users table"
```

---

## Task 2: Entity + DTO + Repository (API)

**Files:**
- Modify: `tafeito-api/src/modules/users/domain/models/user.entity.ts`
- Modify: `tafeito-api/src/modules/users/application/dto/user.dto.ts`
- Modify: `tafeito-api/src/modules/users/infra/repositories/drizzle-user.repository.ts`

- [ ] **Step 1: Adicionar photoUrl à entidade User**

Substituir `user.entity.ts`:

```typescript
export class User {
  private readonly _id?: string;
  private _firebaseUid: string;
  private _name: string;
  private _email: string;
  private _identification: string;
  private _pixKey?: string;
  private _hourlyRate?: number;
  private _photoUrl?: string;
  private readonly _createdAt?: Date;
  private readonly _updatedAt?: Date;

  private constructor(id?: string, createdAt?: Date, updatedAt?: Date) {
    this._id = id;
    this._createdAt = createdAt;
    this._updatedAt = updatedAt;
  }

  get id(): string | undefined { return this._id; }
  get firebaseUid(): string { return this._firebaseUid; }
  get name(): string { return this._name; }
  get email(): string { return this._email; }
  get identification(): string { return this._identification; }
  get pixKey(): string | undefined { return this._pixKey; }
  get hourlyRate(): number | undefined { return this._hourlyRate; }
  get photoUrl(): string | undefined { return this._photoUrl; }
  get createdAt(): Date | undefined { return this._createdAt; }
  get updatedAt(): Date | undefined { return this._updatedAt; }

  withFirebaseUid(firebaseUid: string): this { this._firebaseUid = firebaseUid; return this; }
  withName(name: string): this { this._name = name; return this; }
  withEmail(email: string): this { this._email = email; return this; }
  withIdentification(identification: string): this { this._identification = identification; return this; }
  withPixKey(pixKey?: string): this { this._pixKey = pixKey; return this; }
  withHourlyRate(hourlyRate?: number): this { this._hourlyRate = hourlyRate; return this; }
  withPhotoUrl(photoUrl?: string): this { this._photoUrl = photoUrl; return this; }

  static restore(props?: {
    id?: string;
    firebaseUid: string;
    name: string;
    email: string;
    identification: string;
    pixKey?: string | null;
    hourlyRate?: number | string | null;
    photoUrl?: string | null;
    createdAt?: Date;
    updatedAt?: Date;
  }): User | null {
    if (!props) return null;
    const user = new User(props.id, props.createdAt, props.updatedAt);
    user._firebaseUid = props.firebaseUid;
    user._name = props.name;
    user._email = props.email;
    user._identification = props.identification;
    user._pixKey = props.pixKey ?? undefined;
    user._hourlyRate =
      props.hourlyRate !== undefined && props.hourlyRate !== null
        ? Number(props.hourlyRate)
        : undefined;
    user._photoUrl = props.photoUrl ?? undefined;
    return user;
  }
}
```

- [ ] **Step 2: Adicionar photoUrl ao UserDto**

Substituir `user.dto.ts`:

```typescript
import type { User } from '@users/domain/models/user.entity';

export class UserDto {
  private constructor(
    public id: string | undefined,
    public firebaseUid: string,
    public name: string,
    public email: string,
    public identification: string,
    public pixKey: string | undefined,
    public hourlyRate: number | undefined,
    public photoUrl: string | undefined,
    public createdAt: Date | undefined,
    public updatedAt: Date | undefined,
  ) {}

  public static from(user: User | null): UserDto | null {
    if (!user) return null;
    return new UserDto(
      user.id,
      user.firebaseUid,
      user.name,
      user.email,
      user.identification,
      user.pixKey,
      user.hourlyRate,
      user.photoUrl,
      user.createdAt,
      user.updatedAt,
    );
  }
}
```

- [ ] **Step 3: Atualizar repository para persistir e mapear photoUrl**

Substituir `drizzle-user.repository.ts`:

```typescript
import { User } from '@users/domain/models/user.entity';
import type { UserRepository } from '@users/domain/repositories/user-repository.interface';
import { usersSchema } from '@users/infra/schemas/user.schema';
import { Injectable } from '@nestjs/common';
import { DrizzleService } from '@shared/infra/database/drizzle.service';
import { eq } from 'drizzle-orm';

@Injectable()
export class DrizzleUserRepository implements UserRepository {
  constructor(private readonly drizzleService: DrizzleService) {}

  async create(user: User): Promise<void> {
    await this.drizzleService.db.insert(usersSchema).values({
      firebaseUid: user.firebaseUid,
      name: user.name,
      email: user.email,
      identification: user.identification,
      pixKey: user.pixKey ?? null,
      hourlyRate: user.hourlyRate?.toString(),
      photoUrl: user.photoUrl ?? null,
      createdAt: new Date(),
      updatedAt: new Date(),
    });
  }

  async update(user: User): Promise<void> {
    await this.drizzleService.db
      .update(usersSchema)
      .set({
        name: user.name,
        email: user.email,
        identification: user.identification,
        pixKey: user.pixKey ?? null,
        hourlyRate: user.hourlyRate?.toString(),
        photoUrl: user.photoUrl ?? null,
        updatedAt: new Date(),
      })
      .where(eq(usersSchema.id, user.id!));
  }

  async delete(id: string): Promise<void> {
    await this.drizzleService.db
      .delete(usersSchema)
      .where(eq(usersSchema.id, id));
  }

  async findById(id: string): Promise<User | null> {
    const result = await this.drizzleService.db
      .select()
      .from(usersSchema)
      .where(eq(usersSchema.id, id))
      .limit(1);
    return User.restore(result[0]);
  }

  async findByFirebaseUid(firebaseUid: string): Promise<User | null> {
    const result = await this.drizzleService.db
      .select()
      .from(usersSchema)
      .where(eq(usersSchema.firebaseUid, firebaseUid))
      .limit(1);
    return User.restore(result[0]);
  }

  async findByEmail(email: string): Promise<User | null> {
    const result = await this.drizzleService.db
      .select()
      .from(usersSchema)
      .where(eq(usersSchema.email, email))
      .limit(1);
    return User.restore(result[0]);
  }

  async findAll(): Promise<User[]> {
    const rows = await this.drizzleService.db.select().from(usersSchema);
    return rows.map((row) => User.restore(row)!);
  }
}
```

- [ ] **Step 4: Commit**

```bash
cd tafeito-api
git add src/modules/users/domain/models/user.entity.ts \
        src/modules/users/application/dto/user.dto.ts \
        src/modules/users/infra/repositories/drizzle-user.repository.ts
git commit -m "feat(users): propagate photoUrl through entity, dto, and repository"
```

---

## Task 3: Upload Service Method (API)

**Files:**
- Modify: `tafeito-api/src/modules/users/application/services/user.service.ts`

- [ ] **Step 1: Adicionar método uploadPhoto ao UserService**

Adicionar o import no topo do arquivo (após os imports existentes):

```typescript
import * as fs from 'fs';
import * as path from 'path';
```

Adicionar o método `uploadPhoto` à classe `UserService`, antes do método `remove`:

```typescript
async uploadPhoto(id: string, file: Express.Multer.File): Promise<UserDto> {
  if (!file) {
    throw new BadRequestException('Arquivo de foto obrigatório');
  }

  const user = await this.userRepository.findById(id);
  if (!user) throw new NotFoundException();

  const baseUrl = process.env.API_BASE_URL ?? 'https://tafeito.rietto.com';
  const photoUrl = `${baseUrl}/uploads/profiles/${file.filename}`;

  user.withPhotoUrl(photoUrl);
  await this.userRepository.update(user);

  const updated = await this.userRepository.findById(id);
  return UserDto.from(updated)!;
}
```

- [ ] **Step 2: Commit**

```bash
cd tafeito-api
git add src/modules/users/application/services/user.service.ts
git commit -m "feat(users): add uploadPhoto service method"
```

---

## Task 4: Controller Endpoint + Static Assets (API)

**Files:**
- Modify: `tafeito-api/src/modules/users/infra/controllers/users.controller.ts`
- Modify: `tafeito-api/src/main.ts`

- [ ] **Step 1: Adicionar endpoint PATCH :id/photo no controller**

Substituir `users.controller.ts`:

```typescript
import {
  CreateUserDto,
  UpdateUserDto,
} from '@users/application/dto/create-user.dto';
import { UserDto } from '@users/application/dto/user.dto';
import { UserService } from '@users/application/services/user.service';
import { CurrentUser } from '@shared/infra/current-user.decorator';
import {
  BadRequestException,
  Body,
  Controller,
  Delete,
  Get,
  NotFoundException,
  Param,
  Patch,
  Post,
  Put,
  UploadedFile,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { Throttle } from '@nestjs/throttler';
import { diskStorage } from 'multer';
import { extname, join } from 'path';
import * as fs from 'fs';
import * as crypto from 'crypto';

@Controller('users')
export class UsersController {
  constructor(private readonly userService: UserService) {}

  @Get('me')
  async getMe(@CurrentUser() userId: string): Promise<UserDto> {
    const user = await this.userService.findById(userId);
    if (!user) throw new NotFoundException();
    return user;
  }

  @Get()
  async findAll() {
    return this.userService.list();
  }

  @Get(':id')
  async findById(@Param('id') id: string) {
    return this.userService.findById(id);
  }

  @Throttle({ default: { limit: 5, ttl: 60000 } })
  @Post('/add')
  async create(@Body() body: CreateUserDto) {
    return this.userService.create(body);
  }

  @Put('/update/:id')
  async update(@Param('id') id: string, @Body() body: UpdateUserDto) {
    return this.userService.edit(id, body);
  }

  @Patch(':id/photo')
  @UseInterceptors(
    FileInterceptor('photo', {
      storage: diskStorage({
        destination: (req, file, cb) => {
          const uploadPath = join(process.cwd(), 'uploads', 'profiles');
          fs.mkdirSync(uploadPath, { recursive: true });
          cb(null, uploadPath);
        },
        filename: (req, file, cb) => {
          const ext = extname(file.originalname).toLowerCase() || '.jpg';
          cb(null, `${crypto.randomUUID()}${ext}`);
        },
      }),
      fileFilter: (req, file, cb) => {
        const allowed = ['image/jpeg', 'image/png', 'image/webp'];
        if (allowed.includes(file.mimetype)) {
          cb(null, true);
        } else {
          cb(new BadRequestException('Tipo de arquivo inválido. Use JPEG, PNG ou WebP.'), false);
        }
      },
      limits: { fileSize: 5 * 1024 * 1024 },
    }),
  )
  async uploadPhoto(
    @Param('id') id: string,
    @UploadedFile() file: Express.Multer.File,
  ): Promise<UserDto> {
    return this.userService.uploadPhoto(id, file);
  }

  @Delete('/delete/:id')
  async remove(@Param('id') id: string) {
    return this.userService.remove(id);
  }
}
```

- [ ] **Step 2: Verificar se @types/multer está instalado**

```bash
cd tafeito-api
npx tsc --noEmit 2>&1 | grep multer
```

Se aparecer erro de tipo `Express.Multer.File`, instalar:

```bash
npm install --save-dev @types/multer
```

- [ ] **Step 3: Habilitar static assets no main.ts**

Substituir `main.ts`:

```typescript
import 'dotenv/config';
import * as fs from 'fs';
import * as path from 'path';
import { NestFactory } from '@nestjs/core';
import { NestExpressApplication } from '@nestjs/platform-express';
import { ValidationPipe } from '@nestjs/common';
import helmet from 'helmet';
import { AppModule } from './app.module';

async function bootstrap() {
  const isProduction = process.env.NODE_ENV === 'production';

  const httpsOptions = isProduction
    ? {
        key: fs.readFileSync(process.env.TLS_KEY_PATH!),
        cert: fs.readFileSync(process.env.TLS_CERT_PATH!),
      }
    : undefined;

  const app = await NestFactory.create<NestExpressApplication>(AppModule, { httpsOptions });

  app.use(helmet({
    crossOriginResourcePolicy: { policy: 'cross-origin' },
  }));

  app.useStaticAssets(path.join(process.cwd(), 'uploads'), {
    prefix: '/uploads',
  });

  app.enableCors({
    origin: process.env.FRONTEND_URL,
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
    credentials: true,
  });

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );

  await app.listen(isProduction ? 443 : 3000);
}

void bootstrap();
```

> **Nota:** `crossOriginResourcePolicy: cross-origin` é necessário para que o Flutter Mobile consiga carregar imagens servidas pela API. Sem isso, o helmet bloqueia com CORP header.

- [ ] **Step 4: Build para verificar erros de tipo**

```bash
cd tafeito-api
npx tsc --noEmit
```

Esperado: sem erros de compilação.

- [ ] **Step 5: Commit**

```bash
cd tafeito-api
git add src/modules/users/infra/controllers/users.controller.ts src/main.ts
git commit -m "feat(users): add PATCH :id/photo endpoint and serve static uploads"
```

---

## Task 5: postMultipart no ApiClient + photoUrl no UserDto (Flutter)

**Files:**
- Modify: `tafeito-flutter/lib/src/core/network/api_client.dart`
- Modify: `tafeito-flutter/lib/src/features/profile/data/models/user_dto.dart`

- [ ] **Step 1: Adicionar postMultipart à interface ApiClient e HttpApiClient**

Substituir `api_client.dart`. Adições em relação ao original:
- import `dart:typed_data`
- import `package:http_parser/http_parser.dart`
- método `postMultipart` na interface e em `HttpApiClient`
- stub em `UnimplementedApiClient`

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

typedef JsonObject = Map<String, Object?>;

abstract interface class ApiClient {
  Future<Object?> get(
    String path, {
    Map<String, String?>? queryParameters,
  });

  Future<Object?> post(
    String path, {
    JsonObject? body,
    Map<String, String?>? queryParameters,
  });

  Future<Object?> postMultipart(
    String path, {
    required Uint8List bytes,
    required String filename,
    required String mimeType,
  });

  Future<Object?> put(
    String path, {
    JsonObject? body,
    Map<String, String?>? queryParameters,
  });

  Future<Object?> patch(
    String path, {
    JsonObject? body,
    Map<String, String?>? queryParameters,
  });

  Future<Object?> delete(
    String path, {
    Map<String, String?>? queryParameters,
  });
}

class HttpApiClient implements ApiClient {
  HttpApiClient({
    http.Client? httpClient,
    Uri? baseUri,
    FutureOr<String?> Function()? accessTokenProvider,
  })  : _httpClient = httpClient ?? http.Client(),
        _baseUri = baseUri ?? Uri.parse(defaultBaseUrl),
        _accessTokenProvider = accessTokenProvider;

  static const defaultBaseUrl = String.fromEnvironment(
    'TAFEITO_API_BASE_URL',
    defaultValue: 'https://tafeito.rietto.com',
  );

  final http.Client _httpClient;
  final Uri _baseUri;
  final FutureOr<String?> Function()? _accessTokenProvider;

  @override
  Future<Object?> get(
    String path, {
    Map<String, String?>? queryParameters,
  }) {
    return _send('GET', path, queryParameters: queryParameters);
  }

  @override
  Future<Object?> post(
    String path, {
    JsonObject? body,
    Map<String, String?>? queryParameters,
  }) {
    return _send('POST', path, body: body, queryParameters: queryParameters);
  }

  @override
  Future<Object?> postMultipart(
    String path, {
    required Uint8List bytes,
    required String filename,
    required String mimeType,
  }) async {
    final uri = _resolve(path, null);
    final request = http.MultipartRequest('PATCH', uri);

    final headers = await _headers();
    headers.remove('Content-Type');
    request.headers.addAll(headers);

    request.files.add(
      http.MultipartFile.fromBytes(
        'photo',
        bytes,
        filename: filename,
        contentType: MediaType.parse(mimeType),
      ),
    );

    final streamedResponse = await _httpClient.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiClientException(
        statusCode: response.statusCode,
        message: _readErrorMessage(response),
      );
    }

    if (response.statusCode == 204 || response.bodyBytes.isEmpty) {
      return <String, Object?>{};
    }

    return jsonDecode(utf8.decode(response.bodyBytes)) as Object?;
  }

  @override
  Future<Object?> put(
    String path, {
    JsonObject? body,
    Map<String, String?>? queryParameters,
  }) {
    return _send('PUT', path, body: body, queryParameters: queryParameters);
  }

  @override
  Future<Object?> patch(
    String path, {
    JsonObject? body,
    Map<String, String?>? queryParameters,
  }) {
    return _send('PATCH', path, body: body, queryParameters: queryParameters);
  }

  @override
  Future<Object?> delete(
    String path, {
    Map<String, String?>? queryParameters,
  }) {
    return _send('DELETE', path, queryParameters: queryParameters);
  }

  Future<Object?> _send(
    String method,
    String path, {
    JsonObject? body,
    Map<String, String?>? queryParameters,
  }) async {
    final request = http.Request(method, _resolve(path, queryParameters));
    request.headers.addAll(await _headers());

    if (body != null) {
      request.body = jsonEncode(body);
    }

    final streamedResponse = await _httpClient.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiClientException(
        statusCode: response.statusCode,
        message: _readErrorMessage(response),
      );
    }

    if (response.statusCode == 204 || response.bodyBytes.isEmpty) {
      return <String, Object?>{};
    }

    return jsonDecode(utf8.decode(response.bodyBytes)) as Object?;
  }

  Future<Map<String, String>> _headers() async {
    final accessToken = await Future<String?>.value(
      _accessTokenProvider?.call(),
    );

    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (accessToken != null && accessToken.isNotEmpty)
        'Authorization': 'Bearer $accessToken',
    };
  }

  Uri _resolve(
    String path,
    Map<String, String?>? queryParameters,
  ) {
    final normalizedBase = _baseUri.toString().endsWith('/')
        ? _baseUri
        : Uri.parse('${_baseUri.toString()}/');
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    final uri = normalizedBase.resolve(normalizedPath);
    final cleanQueryParameters = <String, String>{};

    for (final entry
        in (queryParameters ?? const <String, String?>{}).entries) {
      final value = entry.value;
      if (value != null && value.isNotEmpty) {
        cleanQueryParameters[entry.key] = value;
      }
    }

    return cleanQueryParameters.isEmpty
        ? uri
        : uri.replace(queryParameters: cleanQueryParameters);
  }

  String _readErrorMessage(http.Response response) {
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map) {
        final message = decoded['message'];
        if (message is List) {
          return message.whereType<Object>().join('\n');
        }

        final text = message ?? decoded['error'];
        if (text != null && text.toString().isNotEmpty) {
          return text.toString();
        }
      }
    } on Object {
      // Keep the generic message below when the server does not return JSON.
    }

    return 'Erro ${response.statusCode} ao chamar a API.';
  }
}

class UnimplementedApiClient implements ApiClient {
  @override
  Future<Object?> get(String path, {Map<String, String?>? queryParameters}) => _throw(path);

  @override
  Future<Object?> post(String path, {JsonObject? body, Map<String, String?>? queryParameters}) => _throw(path);

  @override
  Future<Object?> postMultipart(String path, {required Uint8List bytes, required String filename, required String mimeType}) => _throw(path);

  @override
  Future<Object?> put(String path, {JsonObject? body, Map<String, String?>? queryParameters}) => _throw(path);

  @override
  Future<Object?> patch(String path, {JsonObject? body, Map<String, String?>? queryParameters}) => _throw(path);

  @override
  Future<Object?> delete(String path, {Map<String, String?>? queryParameters}) => _throw(path);

  Never _throw(String path) {
    throw UnimplementedError(
      'Configure uma implementacao HTTP para chamar $path.',
    );
  }
}

class ApiClientException implements Exception {
  const ApiClientException({
    required this.statusCode,
    required this.message,
  });

  final int statusCode;
  final String message;

  @override
  String toString() => 'ApiClientException($statusCode): $message';
}

JsonObject asJsonObject(Object? value) {
  if (value is Map<String, Object?>) return value;
  if (value is Map) return value.map((key, value) => MapEntry(key.toString(), value));
  throw const FormatException('Resposta da API nao e um objeto JSON.');
}

List<Object?> asJsonList(Object? value) {
  if (value is List) return value.cast<Object?>();
  throw const FormatException('Resposta da API nao e uma lista JSON.');
}

Object? unwrapJsonData(Object? value) {
  if (value is Map) {
    return value['data'] ?? value['result'] ?? value['user'] ?? value;
  }
  return value;
}
```

- [ ] **Step 2: Adicionar photoUrl ao UserDto Flutter**

Substituir `lib/src/features/profile/data/models/user_dto.dart`:

```dart
class UserDto {
  const UserDto({
    required this.id,
    required this.name,
    required this.email,
    this.identification,
    this.pixKey,
    this.hourlyRate,
    this.photoUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
      return null;
    }

    return UserDto(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      identification: (json['identification'] ?? '').toString().isEmpty
          ? null
          : (json['identification'] ?? '').toString(),
      pixKey: (json['pixKey'] ?? '').toString().isEmpty
          ? null
          : (json['pixKey'] ?? '').toString(),
      hourlyRate: json['hourlyRate'] == null
          ? null
          : (json['hourlyRate'] as num).toDouble(),
      photoUrl: (json['photoUrl'] ?? '').toString().isEmpty
          ? null
          : (json['photoUrl'] ?? '').toString(),
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  final String id;
  final String name;
  final String email;

  final String? identification;
  final String? pixKey;
  final double? hourlyRate;
  final String? photoUrl;

  final DateTime? createdAt;
  final DateTime? updatedAt;
}
```

- [ ] **Step 3: Verificar que compila**

```bash
cd tafeito-flutter
flutter analyze lib/src/core/network/api_client.dart lib/src/features/profile/data/models/user_dto.dart
```

Esperado: sem erros.

- [ ] **Step 4: Commit**

```bash
cd tafeito-flutter
git add lib/src/core/network/api_client.dart lib/src/features/profile/data/models/user_dto.dart
git commit -m "feat(profile): add postMultipart to ApiClient and photoUrl to UserDto"
```

---

## Task 6: DataSource + Repository (Flutter)

**Files:**
- Modify: `tafeito-flutter/lib/src/features/profile/data/datasources/profile_remote_data_source.dart`
- Modify: `tafeito-flutter/lib/src/features/profile/domain/repositories/profile_repository.dart`
- Modify: `tafeito-flutter/lib/src/features/profile/data/repositories/profile_repository_impl.dart`

- [ ] **Step 1: Adicionar uploadPhoto ao datasource**

Substituir `profile_remote_data_source.dart`:

```dart
import 'dart:typed_data';

import 'package:tafeito_flutter/src/features/profile/data/models/update_user_request.dart';

import '../../../../core/network/api_client.dart';
import '../../data/models/user_dto.dart';

abstract interface class ProfileRemoteDataSource {
  Future<UserDto> getMe();

  Future<UserDto> update({
    required String id,
    required UpdateUserRequest request,
  });

  Future<UserDto> uploadPhoto({
    required String id,
    required Uint8List bytes,
    required String filename,
    required String mimeType,
  });
}

class ApiProfileRemoteDataSource implements ProfileRemoteDataSource {
  const ApiProfileRemoteDataSource({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<UserDto> getMe() async {
    final response = await _apiClient.get('/v1/users/me');
    return UserDto.fromJson(asJsonObject(unwrapJsonData(response)));
  }

  @override
  Future<UserDto> update({
    required String id,
    required UpdateUserRequest request,
  }) async {
    await _apiClient.put(
      '/v1/users/$id',
      body: request.toJson(),
    );
    return getMe();
  }

  @override
  Future<UserDto> uploadPhoto({
    required String id,
    required Uint8List bytes,
    required String filename,
    required String mimeType,
  }) async {
    final response = await _apiClient.postMultipart(
      '/v1/users/$id/photo',
      bytes: bytes,
      filename: filename,
      mimeType: mimeType,
    );
    return UserDto.fromJson(asJsonObject(unwrapJsonData(response)));
  }
}
```

- [ ] **Step 2: Adicionar uploadPhoto à interface ProfileRepository**

Substituir `profile_repository.dart`:

```dart
import 'dart:typed_data';

import '../../../../core/result/result.dart';
import '../../data/models/update_user_request.dart';
import '../../data/models/user_dto.dart';

abstract interface class ProfileRepository {
  Future<Result<UserDto>> getMe();

  Future<Result<UserDto>> update({
    required String id,
    required UpdateUserRequest request,
  });

  Future<Result<UserDto>> uploadPhoto({
    required String id,
    required Uint8List bytes,
    required String filename,
    required String mimeType,
  });
}
```

- [ ] **Step 3: Implementar uploadPhoto no ProfileRepositoryImpl**

Substituir `profile_repository_impl.dart`:

```dart
import 'dart:typed_data';

import '../../../../core/result/result.dart';
import '../../data/datasources/profile_remote_data_source.dart';
import '../../data/models/update_user_request.dart';
import '../../data/models/user_dto.dart';
import '../../domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl({required this.remoteDataSource});

  final ProfileRemoteDataSource remoteDataSource;

  @override
  Future<Result<UserDto>> getMe() async {
    try {
      final user = await remoteDataSource.getMe();
      return Success(user);
    } on Exception {
      return const Failure('Nao foi possivel carregar seu perfil agora.');
    }
  }

  @override
  Future<Result<UserDto>> update({
    required String id,
    required UpdateUserRequest request,
  }) async {
    try {
      final user = await remoteDataSource.update(id: id, request: request);
      return Success(user);
    } on Exception {
      return const Failure('Nao foi possivel salvar suas alteracoes agora.');
    }
  }

  @override
  Future<Result<UserDto>> uploadPhoto({
    required String id,
    required Uint8List bytes,
    required String filename,
    required String mimeType,
  }) async {
    try {
      final user = await remoteDataSource.uploadPhoto(
        id: id,
        bytes: bytes,
        filename: filename,
        mimeType: mimeType,
      );
      return Success(user);
    } on Exception {
      return const Failure('Nao foi possivel fazer upload da foto agora.');
    }
  }
}
```

- [ ] **Step 4: Verificar que compila**

```bash
cd tafeito-flutter
flutter analyze lib/src/features/profile/
```

Esperado: sem erros.

- [ ] **Step 5: Commit**

```bash
cd tafeito-flutter
git add lib/src/features/profile/data/datasources/profile_remote_data_source.dart \
        lib/src/features/profile/domain/repositories/profile_repository.dart \
        lib/src/features/profile/data/repositories/profile_repository_impl.dart
git commit -m "feat(profile): add uploadPhoto to datasource and repository"
```

---

## Task 7: ViewModel (Flutter)

**Files:**
- Modify: `tafeito-flutter/lib/src/features/profile/presentation/viewmodels/profile_view_model.dart`

- [ ] **Step 1: Adicionar uploadPhoto, isUploadingPhoto e uploadError ao ViewModel**

Substituir `profile_view_model.dart`:

```dart
import 'dart:typed_data';

import 'package:flutter/widgets.dart';

import '../../../../core/result/result.dart';
import '../../data/models/update_user_request.dart';
import '../../data/models/user_dto.dart';
import '../../domain/repositories/profile_repository.dart';

class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel({required ProfileRepository profileRepository})
      : _profileRepository = profileRepository;

  final ProfileRepository _profileRepository;

  UserDto? _me;
  bool _isLoading = false;
  bool _isUploadingPhoto = false;
  String? _errorMessage;
  String? _uploadError;

  UserDto? get me => _me;
  bool get isLoading => _isLoading;
  bool get isUploadingPhoto => _isUploadingPhoto;
  String? get errorMessage => _errorMessage;
  String? get uploadError => _uploadError;

  final nameController = TextEditingController();
  final emailController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  void clearUploadError() {
    _uploadError = null;
  }

  Future<void> loadMe() async {
    _setLoading(true);
    _errorMessage = null;

    final result = await _profileRepository.getMe();
    switch (result) {
      case Success(:final data):
        _me = data;
        nameController.text = data.name;
        emailController.text = data.email;
      case Failure(:final message):
        _errorMessage = message;
    }

    _setLoading(false);
  }

  Future<void> save() async {
    if (_me == null) return;

    _setLoading(true);
    _errorMessage = null;

    final result = await _profileRepository.update(
      id: _me!.id,
      request: UpdateUserRequest(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
      ),
    );

    switch (result) {
      case Success(:final data):
        _me = data;
        nameController.text = data.name;
        emailController.text = data.email;
      case Failure(:final message):
        _errorMessage = message;
    }

    _setLoading(false);
  }

  Future<void> uploadPhoto(Uint8List bytes, String filename) async {
    if (_me == null) return;

    _isUploadingPhoto = true;
    _uploadError = null;
    notifyListeners();

    final mimeType = _mimeTypeFromFilename(filename);

    final result = await _profileRepository.uploadPhoto(
      id: _me!.id,
      bytes: bytes,
      filename: filename,
      mimeType: mimeType,
    );

    switch (result) {
      case Success(:final data):
        _me = data;
      case Failure(:final message):
        _uploadError = message;
    }

    _isUploadingPhoto = false;
    notifyListeners();
  }

  String _mimeTypeFromFilename(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
```

- [ ] **Step 2: Verificar que compila**

```bash
cd tafeito-flutter
flutter analyze lib/src/features/profile/presentation/viewmodels/profile_view_model.dart
```

Esperado: sem erros.

- [ ] **Step 3: Commit**

```bash
cd tafeito-flutter
git add lib/src/features/profile/presentation/viewmodels/profile_view_model.dart
git commit -m "feat(profile): add uploadPhoto to ProfileViewModel"
```

---

## Task 8: ProfilePage UI (Flutter)

**Files:**
- Modify: `tafeito-flutter/lib/src/features/auth/presentation/views/profile_page.dart`

- [ ] **Step 1: Atualizar ProfilePage**

Substituir `profile_page.dart`. Mudanças em relação ao original:
- `_pickImage` agora dispara `_viewModel.uploadPhoto` após set do estado
- Listener no ViewModel para mostrar SnackBar e limpar preview em erro
- Modal inclui opção de câmera
- `CircleAvatar` usa `photoUrl` como fallback e mostra loading durante upload

```dart
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tafeito_flutter/src/core/session/session_manager.dart';
import 'package:tafeito_flutter/src/core/theme/app_theme.dart';
import 'package:tafeito_flutter/src/features/profile/domain/repositories/profile_repository.dart';
import 'package:tafeito_flutter/src/features/profile/presentation/viewmodels/profile_view_model.dart';

import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    required this.sessionManager,
    required this.profileRepository,
    super.key,
  });

  final SessionManager sessionManager;
  final ProfileRepository profileRepository;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Uint8List? _profileImageBytes;
  late final ProfileViewModel _viewModel;
  late final Future<List<MockPayment>> _paymentsFuture;

  @override
  void initState() {
    super.initState();
    _viewModel = ProfileViewModel(
      profileRepository: widget.profileRepository,
    )..loadMe();
    _viewModel.addListener(_onViewModelChanged);
    _paymentsFuture = _fetchMockPaymentsFromApi();
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    final error = _viewModel.uploadError;
    if (error != null && mounted) {
      setState(() => _profileImageBytes = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      _viewModel.clearUploadError();
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    setState(() => _profileImageBytes = bytes);
    await _viewModel.uploadPhoto(bytes, picked.name);
  }

  void _showEditPhotoModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: AppTheme.textPrimary,
                ),
                title: const Text(
                  'Escolher da galeria',
                  style: TextStyle(color: AppTheme.textPrimary),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_outlined,
                  color: AppTheme.textPrimary,
                ),
                title: const Text(
                  'Tirar foto',
                  style: TextStyle(color: AppTheme.textPrimary),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  ImageProvider _resolveAvatarImage() {
    if (_profileImageBytes != null) {
      return MemoryImage(_profileImageBytes!);
    }
    final photoUrl = _viewModel.me?.photoUrl;
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return NetworkImage(photoUrl);
    }
    return const AssetImage('assets/images/avatar_placeholder.png');
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        if (_viewModel.isLoading && _viewModel.me == null) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Stack(
                    children: [
                      _buildAvatar(),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          height: 32,
                          width: 32,
                          decoration: const BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(
                              Icons.edit_square,
                              size: 16,
                              color: Colors.white,
                            ),
                            onPressed: _viewModel.isUploadingPhoto
                                ? null
                                : () => _showEditPhotoModal(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Informacoes pessoais',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildInputField(
                label: 'Nome',
                controller: _viewModel.nameController,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                label: 'Email',
                controller: _viewModel.emailController,
              ),
              if (_viewModel.errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _viewModel.errorMessage!,
                  style: const TextStyle(
                    color: Color(0xFFB91C1C),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onPressed: _viewModel.isLoading ? null : _viewModel.save,
                child: _viewModel.isLoading
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Salvar alteracoes',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Divider(color: Color(0xFFF3F4F6)),
              ),
              const Text(
                'Seguranca',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildInputField(
                label: 'Senha atual',
                hintText: 'Digite a senha atual',
                isPassword: true,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                label: 'Nova senha',
                hintText: 'Digite a nova senha',
                isPassword: true,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                label: 'Confirmar nova senha',
                hintText: 'Repita a nova senha',
                isPassword: true,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onPressed: () {},
                child: const Text(
                  'Atualizar senha',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Divider(color: Color(0xFFF3F4F6)),
              ),
              const Text(
                'Pagamentos',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<MockPayment>>(
                future: _paymentsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primary,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return const Text(
                      'Erro ao carregar os pagamentos.',
                      style: TextStyle(color: Colors.red),
                    );
                  }

                  final payments = snapshot.data ?? [];
                  if (payments.isEmpty) {
                    return const Text('Nenhum pagamento registrado.');
                  }

                  return Column(
                    children: payments
                        .map((payment) => _buildPaymentItem(payment))
                        .toList(),
                  );
                },
              ),
              const Padding(
                padding: EdgeInsets.only(top: 8, bottom: 20),
                child: Divider(color: Color(0xFFF3F4F6)),
              ),
              const Text(
                'Opcoes',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildOptionButton(
                label: 'Sair da conta',
                backgroundColor: const Color(0xFFD1D5DB),
                textColor: AppTheme.textPrimary,
                iconColor: const Color(0xFF4B5563),
                onPressed: () async {
                  await widget.sessionManager.logout();

                  if (!context.mounted) {
                    return;
                  }

                  Navigator.of(context).pushNamedAndRemoveUntil(
                    LoginPage.routeName,
                    (route) => false,
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildOptionButton(
                label: 'Excluir conta',
                backgroundColor: const Color(0xFFE55B4B),
                textColor: Colors.white,
                iconColor: Colors.white,
                onPressed: () {},
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAvatar() {
    if (_viewModel.isUploadingPhoto) {
      return Stack(
        alignment: Alignment.center,
        children: [
          CircleAvatar(
            radius: 48,
            backgroundImage: _profileImageBytes != null
                ? MemoryImage(_profileImageBytes!) as ImageProvider
                : null,
            backgroundColor: const Color(0xFFE5E7EB),
          ),
          const CircularProgressIndicator(color: AppTheme.primary),
        ],
      );
    }

    final hasPhoto = _profileImageBytes != null ||
        (_viewModel.me?.photoUrl != null &&
            _viewModel.me!.photoUrl!.isNotEmpty);

    if (hasPhoto) {
      return CircleAvatar(
        radius: 48,
        backgroundImage: _resolveAvatarImage(),
      );
    }

    return CircleAvatar(
      radius: 48,
      backgroundColor: const Color(0xFFE5E7EB),
      child: const Icon(Icons.person, size: 48, color: Color(0xFF9CA3AF)),
    );
  }

  Widget _buildInputField({
    required String label,
    TextEditingController? controller,
    String? hintText,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionButton({
    required String label,
    required Color backgroundColor,
    required Color textColor,
    required Color iconColor,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        style: TextButton.styleFrom(
          backgroundColor: backgroundColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Icon(Icons.chevron_right, color: iconColor),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentItem(MockPayment payment) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                payment.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                payment.authorDate,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
          Text(
            payment.amount,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Future<List<MockPayment>> _fetchMockPaymentsFromApi() async {
    await Future.delayed(const Duration(milliseconds: 1500));

    return [
      MockPayment(
        title: 'Plantio de jardim',
        authorDate: 'Ana - 18/03/2026',
        amount: 'R\$ 100,00',
      ),
      MockPayment(
        title: 'Poda de arvore',
        authorDate: 'Carlos - 15/03/2026',
        amount: 'R\$ 250,00',
      ),
    ];
  }
}

class MockPayment {
  MockPayment({
    required this.title,
    required this.authorDate,
    required this.amount,
  });

  final String title;
  final String authorDate;
  final String amount;
}
```

> **Nota:** O `_resolveAvatarImage()` retorna `AssetImage('assets/images/avatar_placeholder.png')` como fallback. Se esse asset não existir no projeto, substitua por `NetworkImage('https://ui-avatars.com/api/?name=${_viewModel.me?.name ?? 'U'}')` ou remova o fallback e use o ícone `Icons.person` apenas — o `_buildAvatar()` já trata esse caso.

- [ ] **Step 2: Rodar flutter analyze**

```bash
cd tafeito-flutter
flutter analyze lib/src/features/auth/presentation/views/profile_page.dart
```

Esperado: sem erros.

- [ ] **Step 3: Commit**

```bash
cd tafeito-flutter
git add lib/src/features/auth/presentation/views/profile_page.dart
git commit -m "feat(profile): update ProfilePage with photo upload UI and camera option"
```

---

## Checklist de Verificação Manual

Após implementar todas as tasks:

- [ ] API rodando localmente: `cd tafeito-api && npm run start:dev`
- [ ] Diretório `uploads/profiles/` criado automaticamente ao primeiro upload
- [ ] `GET https://localhost:3000/uploads/profiles/<filename>` retorna a imagem
- [ ] Flutter: tocar no ícone de editar abre modal com Galeria e Câmera
- [ ] Selecionar imagem → preview aparece imediatamente
- [ ] Loading spinner aparece no avatar durante upload
- [ ] Após upload bem-sucedido: `GET /v1/users/me` retorna `photoUrl` preenchido
- [ ] Reiniciar o app → avatar carrega do `photoUrl` (não do estado local)
- [ ] Simular falha de rede → SnackBar aparece, preview é limpo
