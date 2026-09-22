# B46 Order App Mobile

Flutter mobile application for B46 Customer, Cashier, and Admin users.

## Locked stack

- Flutter and Dart
- Cubit through `flutter_bloc`
- Feature-first Clean Architecture
- Versioned JSON over HTTPS to the B46 Ordering backend
- Platform-backed secure storage for mobile sessions
- Android and iOS from one application

Firebase is not part of the architecture.

## Repository scope

This repository owns the production mobile application, role-aware presentation,
Cubits, use cases, frontend repository interfaces, HTTP and local-storage
adapters, mobile tests, assets, and Android/iOS build configuration.

The Go Ordering backend and inventory adapter live in
`b46-ordering-app-backend`. This application never connects directly to the
Ordering or POS databases.

## Architecture

Each feature follows the same dependency direction:

```text
presentation -> application -> domain
data -----------------------> domain
```

Screens invoke Cubits, Cubits invoke use cases, and use cases depend on domain
repository interfaces. Data adapters implement those interfaces. Domain code
must not import Flutter, HTTP, storage, or vendor packages.

Planned feature modules:

- authentication
- catalog
- cart and checkout
- customer orders
- cashier fulfillment
- admin cashier management

Shared code is reserved for behavior genuinely reused across features.

## Current status

Initial architecture scaffold only. Flutter project generation, dependencies,
application code, platform configuration, and Phase 5 implementation have not
started.
