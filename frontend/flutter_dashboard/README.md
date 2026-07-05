# InboxCFO - Flutter Web Dashboard

Dashboard financiero en Flutter Web. Por defecto corre en modo demo local con datos mock; no necesitas Supabase para trabajar en el frontend.

## Enfoque actual

| Ahora | Mas adelante |
| --- | --- |
| UI, layout, grafico, listas | Credenciales Supabase |
| Datos mock en `lib/data/mock_data.dart` | Esquema y seed de base de datos |
| Simulacion local de alertas Realtime | Conexion real + Realtime |
| Boton ingesta simulado localmente | Endpoint n8n / project-cashflow |

## Ejecutar solo frontend

```bash
cd frontend/flutter_dashboard
flutter create . --platforms=web
flutter pub get
flutter run -d chrome
```

No hace falta ningun flag extra: el modo demo viene activado por defecto.

## Que veras en pantalla

- 3 KPI cards: balance, ingreso y gasto proyectados en 30 dias.
- Grafico `fl_chart`: proyeccion de balance y linea de riesgo en $0.
- Lista de facturas: income/expense con iconos y estados.
- Banner de alertas: warning/critical arriba y panel lateral.
- Chip `DEMO LOCAL` en el AppBar si no estas conectado a Supabase.
- Boton `Simular ingesta de correo`: agrega una factura y alerta nuevas sin recargar.
- Login con Supabase Auth cuando corres con `USE_MOCK_DATA=false`.

## Estructura

```text
lib/
  main.dart
  config/
  models/
  services/
  data/mock_data.dart
  screens/
  widgets/
  theme/
```

## Personalizar datos mock

Edita `lib/data/mock_data.dart` para cambiar balance, proyecciones, facturas y alertas iniciales mientras disenas la UI.

## Conectar Supabase

El backend de datos vive en la raiz del repo:

1. En Supabase SQL Editor, ejecuta `database/schema/schema.sql`.
2. Luego ejecuta `database/seed/seed.sql`.
3. Desde la raiz del repo, configura `.env` con `.env.example` y corre `npm run project:cashflow` para llenar `cash_projections` y `alerts`.
4. Inicia el dashboard con tus credenciales publicas de Supabase:

```bash
flutter run -d chrome --dart-define=USE_MOCK_DATA=false --dart-define=SUPABASE_URL=https://TU_PROYECTO.supabase.co --dart-define=SUPABASE_ANON_KEY=tu_anon_key
```

Tambien habilita Realtime en la tabla `alerts` en Supabase Dashboard -> Database -> Replication.

El codigo de conexion ya esta en `lib/services/supabase_service.dart`; no hay que reescribir el frontend.

## Configurar login y verificacion por correo

En Supabase Dashboard:

1. Ve a Authentication -> Providers -> Email.
2. Activa Confirm email para que el registro pida verificacion por correo.
3. Ve a Authentication -> URL Configuration.
4. Agrega `http://localhost:8080/` en Redirect URLs para desarrollo local.
5. Si usas otro puerto, agregalo tambien, por ejemplo `http://localhost:8081/`.

Ejecuta el dashboard real con:

```bash
flutter run -d chrome --web-port=8080 --dart-define=USE_MOCK_DATA=false --dart-define=SUPABASE_URL=https://TU_PROYECTO.supabase.co --dart-define=SUPABASE_ANON_KEY=tu_anon_key --dart-define=AUTH_REDIRECT_URL=http://localhost:8080/
```

Flujo esperado:

1. Entras a la app y aparece la pantalla de login.
2. Das clic en Crear cuenta nueva.
3. Supabase envia el correo de verificacion.
4. Confirmas el correo.
5. Vuelves a la app e inicias sesion.
6. El dashboard aparece y el boton de cerrar sesion queda en el AppBar.

## Endpoint de ingesta / proyeccion

El boton de ingesta mantiene el modo demo local cuando `USE_MOCK_DATA=true`. En modo Supabase real, configura un endpoint que ejecute `backend/cloud_functions/project-cashflow.js`:

```bash
flutter run -d chrome --dart-define=USE_MOCK_DATA=false --dart-define=SUPABASE_URL=https://TU_PROYECTO.supabase.co --dart-define=SUPABASE_ANON_KEY=tu_anon_key --dart-define=INGESTION_ENDPOINT=https://tu-endpoint/project-cashflow
```

## Checklist frontend

- [ ] `flutter pub get` sin errores.
- [ ] Dashboard carga con `flutter run -d chrome` sin flags.
- [ ] Grafico y KPIs se ven bien.
- [ ] Boton ingesta agrega alerta y factura en vivo.
- [ ] Conectar Supabase con `USE_MOCK_DATA=false`.
- [ ] Supabase Auth confirma correo y permite iniciar sesion.
- [ ] Ejecutar `npm run project:cashflow` para poblar proyecciones y alertas.
