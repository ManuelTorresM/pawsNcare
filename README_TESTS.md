# pawsNcare — Comprehensive Test Coverage Suite

This repository contains a complete test suite for the **pawsNcare** Flutter application, built by a senior Flutter testing engineer. It provides comprehensive test coverage across **Unit Tests**, **Widget Tests**, and **Integration Tests** following official Flutter testing guidelines.

---

## 📊 Test Suite Summary

| Testing Category | Target Directory | Created Files | Test Cases | Execution Status |
| :--- | :--- | :---: | :---: | :---: |
| **Unit Tests** | `test/unit/` | 16 | 58 | **PASSED (100%)** |
| **Widget Tests** | `test/widgets/` | 8 | 18 | **PASSED (100%)** |
| **Integration Tests** | `test/integration/` | 7 | 9 | **PASSED (100%)** |
| **Total Test Suite** | `test/` | **31 files** | **85 tests** | **PASSED (100%)** |

> **Result**: 85 passed, 0 failed, 0 skipped (`exit code 0`).

---

## 📂 Test Directory Structure

```text
test/
├── unit/
│   ├── models/
│   │   ├── app_user_test.dart
│   │   ├── pet_test.dart
│   │   ├── medication_test.dart
│   │   ├── diary_entry_test.dart
│   │   ├── app_notification_test.dart
│   │   ├── pet_invitation_test.dart
│   │   ├── pet_role_test.dart
│   │   ├── shared_member_test.dart
│   │   └── weight_log_test.dart
│   ├── cubits/
│   │   ├── auth_bloc_test.dart
│   │   ├── pet_bloc_test.dart
│   │   ├── diary_bloc_test.dart
│   │   └── theme_cubit_test.dart
│   ├── services/
│   │   ├── demo_repository_test.dart
│   │   └── local_media_service_test.dart
│   └── extensions/
│       └── responsive_layout_test.dart
├── widgets/
│   ├── auth_screens_widget_test.dart
│   ├── dashboard_screen_widget_test.dart
│   ├── pet_screens_widget_test.dart
│   ├── diary_screen_widget_test.dart
│   ├── calendar_screen_widget_test.dart
│   ├── nutrition_screens_widget_test.dart
│   ├── profile_settings_widget_test.dart
│   └── common_widgets_test.dart
└── integration/
    ├── auth_flow_test.dart
    ├── pet_creation_flow_test.dart
    ├── medication_flow_test.dart
    ├── calendar_flow_test.dart
    ├── diary_flow_test.dart
    ├── sharing_collaboration_flow_test.dart
    └── theme_flow_test.dart
```

---

## 🔍 Detailed Test Categories & Coverage

### 1. Unit Tests (`test/unit/`)
* **Data Models (`test/unit/models/`)**:
  * `app_user_test.dart`: Serialization (`toMap`/`fromMap`), `copyWith`, user code generation determinism (`generateUserCode`), and `Equatable` value equality.
  * `pet_test.dart`: Serialization, helper getters (`coOwners`, `caregivers`, `veterinarians`), `toPendingReplica` data sanitization, and `toConsistentImageReplica` avatar resolution.
  * `medication_test.dart`: Serialization, frequency dosage limits (`Every 8h`, `Every 12h`, `Weekly`, `Vaccine`), and `dosesToday` calculation logic.
  * `diary_entry_test.dart`: Serialization, category parsing, severity level mapping, and equality checks.
  * `app_notification_test.dart`: `NotificationCategoryExtension` display names, category icons, and `fromMap` fallback handling.
  * `pet_invitation_test.dart`: Invitation status state transitions (`Pending` → `Active` / `Declined`) and serialization.
  * `pet_role_test.dart`: `PetRole.fromString` parsing variations (`vet`, `carer`, `co-owner`), display attributes, and full permission matrix checks (`canEditProfile`, `canManageMembers`, `canDeletePet`, `canLogMedical`).
  * `shared_member_test.dart`: Role serialization, member status, and joined timestamp formatting.
  * `weight_log_test.dart`: Weight log serialization and date value equality validation.

* **BLoCs / Cubits (`test/unit/cubits/`)**:
  * `auth_bloc_test.dart`: State transitions for `AuthCheckRequested`, `LoginSubmitted`, `RegisterSubmitted`, and `LogoutRequested` (`AuthLoading` → `Authenticated` / `Unauthenticated` / `AuthFailure`).
  * `pet_bloc_test.dart`: Operations for `LoadPets`, `AddPet`, `DeletePet`, and `SearchPets` query filtering.
  * `diary_bloc_test.dart`: State transitions for `LoadDiary`, `AddDiaryEntryEvent`, and `DeleteDiaryEntryEvent`.
  * `theme_cubit_test.dart`: `loadTheme` and `toggleTheme` persistence with `SharedPreferences`.

* **Services & Repositories (`test/unit/services/`)**:
  * `demo_repository_test.dart`: In-memory CRUD operations and authentication credential checks.
  * `local_media_service_test.dart`: Local avatar/photo path persistence and `resolveImageProvider` asset/network image resolution.

* **Extensions (`test/unit/extensions/`)**:
  * `responsive_layout_test.dart`: `isTabletDevice` and `isTabletLayout` breakpoint mathematics.

---

### 2. Widget Tests (`test/widgets/`)
* `auth_screens_widget_test.dart`: Text field inputs, validation error rendering, and button callbacks for `LoginScreen`.
* `dashboard_screen_widget_test.dart`: `DashboardScreen` bottom navigation bar rendering and `HomeTab` pet selector/quick action cards.
* `pet_screens_widget_test.dart`: Multi-step `AddPetWizard`, `CreatePetStep1` form input fields, and `PetDetailsScreen` header/tabs.
* `diary_screen_widget_test.dart`: `DiaryScreen` header, category filtering tabs, and log entries.
* `calendar_screen_widget_test.dart`: `CalendarScreen` month view, day selector grid, and event schedule cards.
* `nutrition_screens_widget_test.dart`: `NutritionScreen`, `AddMealScreen`, and `AddHydrationScreen` overview and food entry fields.
* `profile_settings_widget_test.dart`: `SettingsScreen` notification/theme toggle tiles and `ProfileDetailsScreen` user profile card.
* `common_widgets_test.dart`: `RoleBadge` color/icon rendering per role and `AccentLeftCard` container layout.

---

### 3. Integration Tests (`test/integration/`)
* `auth_flow_test.dart`: End-to-end user registration, credential login, and dashboard navigation.
* `pet_creation_flow_test.dart`: End-to-end multi-step pet creation wizard flow.
* `medication_flow_test.dart`: Medication schedule rendering and dose administration logging.
* `calendar_flow_test.dart`: Event creation, viewing, and day-by-day filter selection.
* `diary_flow_test.dart`: Adding, category filtering, and deleting pet diary entries.
* `sharing_collaboration_flow_test.dart`: Generating share codes, inviting members, updating roles, and revoking permissions.
* `theme_flow_test.dart`: Toggling dark mode in settings and verifying app-wide theme persistence.

---

## 🚀 How to Run the Tests

### Run All Tests (Unit, Widget, and Integration)
```bash
flutter test test/unit test/widgets test/integration
```

### Run Unit Tests Only
```bash
flutter test test/unit
```

### Run Widget Tests Only
```bash
flutter test test/widgets
```

### Run Integration Tests Only
```bash
flutter test test/integration
```

---

## 🛠️ Testing Dependencies & Stack

The test suite uses the following packages defined in `pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  mocktail: ^1.0.4
  bloc_test: ^10.0.0
```

---

## 💡 Key Architectural Notes

1. **Firebase Lazy Initialization in Tests**: Firebase SDK `FirebaseAuth.instance` and `FirebaseFirestore.instance` calls in repositories and UI screens are safely guarded or converted to getters, allowing unit and widget tests to run in headless test environments without requiring a live Firebase backend connection.
2. **Device Viewport Bounds**: Complex UI screens (`CalendarScreen`, `SettingsScreen`, `CreatePetStep1`) set physical viewport dimensions (`1080x2400`) during test execution to prevent canvas clipping or layout overflow.
3. **Isolated Test State**: Each test case utilizes `setUp()` and `tearDown()` with mocked initial values (`SharedPreferences.setMockInitialValues({})`) to prevent shared state leakage between tests.
