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

## Estructura

```
lib/
├── main.dart
├── config/          # app_config (mock por defecto), supabase_config (para después)
├── models/
├── services/        # supabase_service + ingestion_service
├── data/mock_data.dart
├── screens/dashboard_screen.dart
├── widgets/         # KpiCard, CashflowChart, InvoiceListTile, AlertBanner
└── theme/
```

## Personalizar datos mock

Edita `lib/data/mock_data.dart` para cambiar balance, proyecciones, facturas y alertas iniciales mientras diseñas la UI.

## Conectar Supabase (cuando el equipo lo tenga listo)

Cuando lleguen credenciales y esquema al repo:

```bash
flutter run -d chrome ^
  --dart-define=USE_MOCK_DATA=false ^
  --dart-define=SUPABASE_URL=https://TU_PROYECTO.supabase.co ^
  --dart-define=SUPABASE_ANON_KEY=tu_anon_key
```

También habilita Realtime en la tabla `alerts` en Supabase Dashboard → Database → Replication.

El código de conexión ya está en `lib/services/supabase_service.dart` — no hay que reescribir el frontend.

## Endpoint de ingesta (cuando exista)

```bash
flutter run -d chrome ^
  --dart-define=USE_MOCK_DATA=false ^
  --dart-define=INGESTION_ENDPOINT=https://tu-webhook.com/ingest
```

## Checklist frontend

- [ ] `flutter pub get` sin errores
- [ ] Dashboard carga con `flutter run -d chrome` (sin flags)
- [ ] Gráfico y KPIs se ven bien
- [ ] Botón ingesta agrega alerta + factura en vivo
- [ ] (Después) Conectar Supabase cuando el equipo lo suba al git
