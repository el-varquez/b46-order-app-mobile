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

Feature modules:

- authentication
- catalog
- cart and checkout
- customer orders
- cashier fulfillment
- admin cashier management

Shared code is reserved for behavior genuinely reused across features.

The shared component library uses [Lucide](https://lucide.dev/) icons through
`lucide_icons_flutter`. App-authored icons belong in
`lib/shared/components/pop_icons.dart` and screens use its `PopIcons` names;
back navigation uses the shared `PopBackButton` chevron. Brand marks such as
Google's “G” remain brand assets rather than Lucide icons.

## Current status

The Phase 5 foundation and Admin area are implemented on Android API 26+ and
iOS 13+. One shared login routes backend-issued Customer, Cashier, and Admin
roles. Customer catalog/cart/checkout/status, Cashier queue/detail/status,
and Admin Cashier management use the backend contract. An Admin adds Cashiers
  with temporary email credentials and verifies a code sent to the Cashier's
  email before the account can sign in. The Cashier gives the code to the Admin
  and must change the temporary password before opening orders. The Admin can
  disable, restore, and reset a verified Cashier login.
The login offers Google and email. Email registration requests
a six-digit code, verifies it through the backend, then stores the same B46
access/refresh session as password or Google sign-in. The backend owns SMTP;
the app never carries Maddy credentials.

The copied registration contract is version 0.5.0 and is pinned to an
immutable backend commit, blob, and checksum in `contracts/backend/source.json`.
Gmail SMTP delivery remains an open backend acceptance gate: HTTP `202` only
confirms queue handoff, not receipt of a verification email.

## Local setup and physical devices

Restore the shared Flutter dependencies on any development machine:

```text
make dependencies
```

List connected phones and inspect the Flutter toolchain when needed:

```text
make devices
make doctor
```

### Android phone

Enable USB debugging, connect the phone, and run:

```text
make run-android DEVICE=<android-device-id>
```

The command forwards device port `8080` to the development machine, allowing
the app to reach a locally running backend. Use `BACKEND_PORT=<port>` when the
backend is not running on `8080`.

### iOS collaborator

The Mac must already have Flutter, Xcode, and the Xcode command-line tools.
After cloning, prepare all Flutter and iOS dependencies with one command:

```text
make setup-ios
```

This enables Flutter Swift Package Manager integration, downloads the iOS
engine artifacts, and restores Dart/plugin dependencies. This project does not
require a manual CocoaPods installation step.

To compile and run on a connected iPhone:

```text
make run-ios DEVICE=<iphone-device-id> API_BASE_URL=http://<mac-lan-ip>:8080
```

The iPhone and Mac must both be able to reach that backend address. When only
one supported phone is connected, `DEVICE` may be omitted. `make run` and
`make debug` are equivalent generic debug commands.

Google sign-in on iOS additionally needs a Google iOS OAuth client for
`com.b46.orderapp`. Set its public ID as `GOOGLE_CLIENT_ID`, set the backend
Web audience as `GOOGLE_SERVER_CLIENT_ID`, and register the iOS client's
reversed URL scheme in `ios/Runner/Info.plist` before the physical-device
test. These iOS values are not provisioned yet. The native Google SDK is
pinned to 9.2.0 so the iOS 13 baseline is retained.

Build an Android debug APK without launching the application:

```text
make debug-apk
```

## Quality gates

The repository enforces five independent checks:

- Build and Test restores locked dependencies, verifies formatting, runs static
  analysis and tests, and builds a debug Android APK.
- Architecture enforces the feature shape, dependency direction, feature
  isolation, and the declared dependency lock.
- Conventions requires `<type>/<kebab-name>` branches and Conventional Commits.
- Design System keeps Pop Shelf colors in canonical theme tokens.
- Contract Pin verifies that the copied backend OpenAPI artifact has not
  drifted from its recorded checksum.

Run the local non-PR gates with `make check`. Update
`architecture/dependencies.json` in the same change whenever a direct
dependency changes.

See `b46-ordering-app/docs/mobile-development.md` in the shared planning
workspace for local backend URLs, Dart defines, OAuth credential setup, and
the two-account walkthrough.
