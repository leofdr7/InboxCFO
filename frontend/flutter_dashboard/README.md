# InboxCFO — Flutter Web Dashboard

Dashboard financiero en Flutter Web. **Por defecto corre en modo demo local** con datos mock — no necesitas Supabase para trabajar en el frontend.

## Enfoque actual (Integrante 4 — Frontend)

| Ahora | Más adelante (equipo / git) |
|-------|----------------------------|
| UI, layout, gráfico, listas | Credenciales Supabase |
| Datos mock en `lib/data/mock_data.dart` | Esquema y seed del Integrante 3 |
| Simulación local de alertas Realtime | Conexión real + Realtime |
| Botón ingesta simulado localmente | Endpoint n8n / project-cashflow |

## Ejecutar (solo frontend)

```bash
cd frontend/flutter_dashboard
flutter create . --platforms=web   # solo la primera vez
flutter pub get
flutter run -d chrome
```

No hace falta ningún flag extra: **el modo demo viene activado por defecto**.

## Qué verás en pantalla

- **3 KPI cards**: balance, ingreso y gasto proyectados (30 días)
- **Gráfico fl_chart**: proyección de balance + línea de riesgo en $0
- **Lista de facturas**: income/expense con íconos y estados
- **Banner de alertas**: warning/critical arriba + panel lateral
- **Chip "DEMO LOCAL"** en el AppBar (indica que no estás conectado a Supabase)
- **Botón "Simular ingesta de correo"**: agrega una factura y alerta nuevas sin recargar (simula Realtime)
- **Login con Supabase Auth** cuando corres con `USE_MOCK_DATA=false`

## Estructura

```
lib/
├── main.dart
├── config/          # app_config (mock por defecto), supabase_config (para después)
├── models/
├── services/        # supabase_service + ingestion_service + auth_service
├── data/mock_data.dart
├── screens/         # auth_gate, auth_screen, dashboard_screen
├── widgets/         # KpiCard, CashflowChart, InvoiceListTile, AlertBanner
└── theme/
```

## Personalizar datos mock

Edita `lib/data/mock_data.dart` para cambiar balance, proyecciones, facturas y alertas iniciales mientras diseñas la UI.

## Conectar Supabase

El backend de datos ya vive en la raíz del repo:

1. En Supabase SQL Editor, ejecuta `database/schema/schema.sql`.
2. Luego ejecuta `database/seed/seed.sql`.
3. Desde la raíz del repo, configura `.env` con `.env.example` y corre `npm run project:cashflow` para llenar `cash_projections` y `alerts`.
4. Inicia el dashboard con tus credenciales públicas de Supabase:

```bash
flutter run -d chrome --dart-define=USE_MOCK_DATA=false --dart-define=SUPABASE_URL=https://TU_PROYECTO.supabase.co --dart-define=SUPABASE_ANON_KEY=tu_anon_key
```

También habilita Realtime en la tabla `alerts` en Supabase Dashboard → Database → Replication.

El código de conexión ya está en `lib/services/supabase_service.dart` — no hay que reescribir el frontend.

## Configurar login y verificación por correo

En Supabase Dashboard:

1. Ve a **Authentication → Providers → Email**.
2. Activa **Confirm email** para que el registro pida verificación por correo.
3. Ve a **Authentication → URL Configuration**.
4. Agrega `http://localhost:8080/` en **Redirect URLs** para desarrollo local.
5. Si usas otro puerto, agrégalo también, por ejemplo `http://localhost:8081/`.

Ejecuta el dashboard real con:

```bash
flutter run -d chrome --web-port=8080 --dart-define=USE_MOCK_DATA=false --dart-define=SUPABASE_URL=https://TU_PROYECTO.supabase.co --dart-define=SUPABASE_ANON_KEY=tu_anon_key --dart-define=AUTH_REDIRECT_URL=http://localhost:8080/
```

Flujo esperado:

1. Entras a la app y aparece la pantalla de login.
2. Das clic en **Crear cuenta nueva**.
3. Supabase envía el correo de verificación.
4. Confirmas el correo.
5. Vuelves a la app e inicias sesión.
6. El dashboard aparece y el botón de cerrar sesión queda en el AppBar.

## Endpoint de ingesta / proyección

El botón de ingesta mantiene el modo demo local cuando `USE_MOCK_DATA=true`. En modo Supabase real, configura un endpoint que ejecute `backend/cloud_functions/project-cashflow.js`:

```bash
flutter run -d chrome --dart-define=USE_MOCK_DATA=false --dart-define=SUPABASE_URL=https://TU_PROYECTO.supabase.co --dart-define=SUPABASE_ANON_KEY=tu_anon_key --dart-define=INGESTION_ENDPOINT=https://tu-endpoint/project-cashflow
```

## Checklist frontend

- [ ] `flutter pub get` sin errores
- [ ] Dashboard carga con `flutter run -d chrome` (sin flags)
- [ ] Gráfico y KPIs se ven bien
- [ ] Botón ingesta agrega alerta + factura en vivo
- [ ] Conectar Supabase con `USE_MOCK_DATA=false`
- [ ] Supabase Auth confirma correo y permite iniciar sesión
- [ ] Ejecutar `npm run project:cashflow` para poblar proyecciones y alertas
