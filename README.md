# 💸 Finanzas Personales

App Flutter para gestión de finanzas personales con diseño premium oscuro.

## ✨ Funcionalidades

- **Multi-cuenta** — Personal, Agencia IA, o cualquier cuenta que crees
- **Ingresos y gastos** — Registra movimientos con categorías y fecha
- **Recurrentes** — Suscripciones y gastos fijos mensuales (plan teléfono, YouTube Premium, Claude.ai, etc.)
- **Metas de ahorro** — Crea objetivos con barra de progreso y abona cuando quieras
- **Dashboard visual** — Balance del mes, gráfico de tendencia 6 meses, stats de ingresos/gastos
- **Navegación por mes** — Filtra cualquier mes pasado
- **Datos locales** — Todo se guarda en el dispositivo, sin cuenta, sin internet

## 📱 Pantallas

| Inicio | Movimientos | Recurrentes | Ahorros |
|--------|-------------|-------------|---------|
| Balance, stats, gráfico, últimos movimientos | Lista filtrable por tipo, agrupada por día | Suscripciones y fijos mensuales con toggle activo/pausado | Metas de ahorro con progreso visual |

## 🛠 Stack

- Flutter 3.x / Dart 3.x
- `provider` — State management
- `shared_preferences` — Persistencia local
- `fl_chart` — Gráficos
- `google_fonts` — Tipografía (DM Sans + Space Grotesk)
- `intl` — Formateo de fechas y moneda (CLP)

## 🚀 Cómo correr

```bash
flutter pub get
flutter run
```

## 📦 Build APK

```bash
flutter build apk --release
```

El APK quedará en `build/app/outputs/flutter-apk/app-release.apk`

## 🎨 Diseño

Tema oscuro premium con paleta:
- Fondo `#0A0A14` 
- Superficies `#141424` / `#1E1E32`
- Acento violeta `#8B5CF6`
- Income verde `#10B981`
- Expense rojo `#EF4444`
- Savings azul `#3B82F6`
