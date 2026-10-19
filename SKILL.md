---
name: ium-developmint
description: >-
  Comprehensive guide and workflow for developing, scaffolding, testing, and architecting new Obelawium (IUM) domain modules.
  Use this skill when asked to create, design, scaffold, or implement a new IUM module, domain service, DTO, model,
  migration, configuration enum, or integration with the ium() gateway (`obelaw/ium`).
tags: [obelaw, ium, erp, domain-driven-design, laravel, module-development, headless, dto, pest]
---

# Develop an Obelawium (IUM) Domain Module

This skill guides an AI agent through architecting, scaffolding, implementing, and testing a domain module within the **Obelawium (IUM)** ERP ecosystem ([`obelaw/ium`](https://github.com/obelawium/ium)).

---

## 1. Core Philosophy & Fluent Gateway Architecture

Obelawium (IUM) modules are **autonomous, headless domain aggregates**. They strictly segregate business logic from presentation layers (no HTTP controllers, routes, Blade views, Livewire, Inertia, or Filament resources). All external interactions flow through a unified fluent DSL powered by [`ObelawiumManager`](https://github.com/obelawium/ium/blob/main/src/ObelawiumManager.php):

```php
ium() → [domain]() → [service]() → [method]()
```

For example:
```php
// Mutate state through a typed DTO
$lead = ium()->crm()->leads()->create(CreateLeadDto::from([
    'code' => 'LEAD-001',
    'name' => 'Acme Corp',
]));

// Query domain services
$submissions = ium()->forms()->submissions()->forSchema('vendor-onboarding');

// Runtime configuration via helper or fluent invocation
ium(['crm.auto_assign' => true])->crm()->leads()->create($dto);
$prefix = ium_config('crm.lead_prefix', 'LD-');
```

For a deep dive into the core `obelaw/ium` engine classes, consult the [Architecture & Core Engine Reference](./references/architecture.md).

---

## 2. Core `obelaw/ium` Primitives Inventory

Every IUM module builds directly on the primitives provided by [`obelaw/ium`](https://github.com/obelawium/ium):

| Core Primitive | FQCN / Source | Role in Module Development |
| :--- | :--- | :--- |
| **Central Manager** | [`Obelaw\Ium\ObelawiumManager`](https://github.com/obelawium/ium/blob/main/src/ObelawiumManager.php) | Singleton registry holding domain classes and dispatching `ium()-><domain>()` calls via `__call()`. |
| **Facade** | [`Obelaw\Ium\Facades\Ium`](https://github.com/obelawium/ium/blob/main/src/Facades/Ium.php) | Static facade used in Service Providers to call `Ium::registerDomain('<slug>', <Module>Domain::class)`. |
| **Core Provider** | [`Obelaw\Ium\Providers\ObelawiumServiceProvider`](https://github.com/obelawium/ium/blob/main/src/Providers/ObelawiumServiceProvider.php) | Registers `ObelawiumManager` in the Laravel container and boots core metadata. |
| **Domain Base** | [`Obelaw\Ium\Abstracts\Domain`](https://github.com/obelawium/ium/blob/main/src/Abstracts/Domain.php) | Base class that every `<Module>Domain` gateway MUST extend (`is_subclass_of($domain, Domain::class)` is enforced). |
| **Base Model** | [`Obelaw\Ium\Bases\ModelBase`](https://github.com/obelawium/ium/blob/main/src/Bases/ModelBase.php) | Eloquent `Model` subclass that prepends `ium_` + `$this->module` to table names and applies `GlobalConfigManager::get('obelawium.db.connection')`. |
| **Base Migration** | [`Obelaw\Ium\Bases\MigrationBase`](https://github.com/obelawium/ium/blob/main/src/Bases/MigrationBase.php) | Laravel `Migration` subclass that constructs `$this->prefix = 'ium_' . $this->module` for `Schema::create()`. |
| **Base DTO** | [`Obelaw\Ium\Bases\BaseDto`](https://github.com/obelawium/ium/blob/main/src/Bases/BaseDto.php) | `readonly abstract class` with automatic `Validator::make($data, $this->rules())` validation and property hydration. |
| **Config Manager** | [`Obelaw\Ium\Engine\ObelawConfigManager`](https://github.com/obelawium/ium/blob/main/src/Engine/ObelawConfigManager.php) | Process-local singleton config store supporting string keys and `IumConfigEnum` backed enums (`get`, `set`, `defaults`, `merge`, `all`, `reset`). |
| **Global Config** | [`Obelaw\Ium\Engine\GlobalConfigManager`](https://github.com/obelawium/ium/blob/main/src/Engine/GlobalConfigManager.php) | Static config store mirrored when `$global = true` in `set()`, readable inside static/constructor contexts like `ModelBase::__construct()`. |
| **Config Enum** | [`Obelaw\Ium\Contracts\IumConfigEnum`](https://github.com/obelawium/ium/blob/main/src/Contracts/IumConfigEnum.php) | Marker interface (`extends \BackedEnum`) allowing domain enums to act as type-safe config keys in `ium_config()` and `ium_set_config()`. |
| **Global Helpers** | [`src/helpers.php`](https://github.com/obelawium/ium/blob/main/src/helpers.php) | `ium(array $configs = [])`, `ium_config(IumConfigEnum\|string $enum, mixed $default = null)`, `ium_set_config(IumConfigEnum\|string $enum, mixed $value, ?bool $global = null)`. |

---

## 3. Naming Conventions Matrix

When creating a new module `<slug>` (e.g., `crm`, `accounting`, `wms`, `forms`):

| Concern | Convention | Example (`crm`) |
| :--- | :--- | :--- |
| **Monorepo Directory** | `packages/<slug>` | `packages/crm` |
| **Composer Package** | `obelaw/ium-<slug>` | `obelaw/ium-crm` |
| **PHP Root Namespace** | `Obelaw\Ium\<Module>\` | `Obelaw\Ium\Crm\` |
| **Domain Registration Key** | `<slug>` | `'crm'` |
| **Fluent Invocation** | `ium()-><slug>()` | `ium()->crm()` |
| **Domain Gateway Class** | `<Module>Domain` (extends `Domain`) | `CrmDomain` |
| **Domain Manager Class** | `<Module>Manager` | `CrmManager` |
| **Service Provider** | `Obelaw<Module>ServiceProvider` | `ObelawCrmServiceProvider` |
| **Physical Table Prefix** | `ium_<slug>_` | `ium_crm_` (e.g., `ium_crm_leads`) |
| **Base Model / Migration** | `protected ?string $module = '<slug>_';` | `protected ?string $module = 'crm_';` |
| **Config File / Key** | `config/<slug>.php` / `ium.<slug>` | `config/crm.php` / `ium.crm` |
| **Config Enum** | `<Module>ConfigEnum implements IumConfigEnum` | `CrmConfigEnum` |

For the full cross-package comparison matrix and architectural rules, consult the [Conventions & Checklist Guide](./references/conventions.md).

---

## 4. Fast Scaffolding Helper

Scaffold a complete, compliant module skeleton (including `composer.json`, base classes, domain gateway, manager, service provider, DTO, model, service, migration, and Pest test suite) using the bundled PowerShell script:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/scaffold-module.ps1 -Slug <slug> -ModuleName <ModuleName> -Entity <Entity> -BasePath packages
```

Example for a `crm` module:
```powershell
powershell -ExecutionPolicy Bypass -File scripts/scaffold-module.ps1 -Slug crm -ModuleName Crm -Entity Lead -BasePath packages
```

---

## 5. Step-by-Step Development Workflow (10 Steps)

When building or extending an IUM module, follow these 10 steps in order:

### Step 1: Establish Bounded Context & Identity
- Determine the lowercase `<slug>` (e.g. `crm`), PascalCase `<Module>` (`Crm`), and core aggregate roots (`Lead`, `Deal`).
- Verify strict headless boundaries: no routes, controllers, or UI views, and zero physical foreign keys referencing tables outside `ium_<slug>_*`.

### Step 2: Configure `composer.json`
- Name the package `"obelaw/ium-<slug>"`.
- Require `"obelaw/ium": "*"` and `"laravel/framework": "^12.0|^13.0"` (or `illuminate/*` components).
- Map PSR-4 `"Obelaw\\Ium\\<Module>\\": "src/"` and `"Obelaw\\Ium\\<Module>\\Tests\\": "tests/"`.
- Register `Obelaw\Ium\<Module>\Providers\Obelaw<Module>ServiceProvider` under `extra.laravel.providers`.
- See [Boilerplate Templates — `composer.json`](./references/template-files.md#1-composerjson).

### Step 3: Implement Module `ModelBase` and `MigrationBase`
Create `src/Base/ModelBase.php` and `src/Base/MigrationBase.php`:
- `ModelBase` extends [`Obelaw\Ium\Bases\ModelBase`](https://github.com/obelawium/ium/blob/main/src/Bases/ModelBase.php) and sets `protected ?string $module = '<slug>_';`.
- `MigrationBase` extends [`Obelaw\Ium\Bases\MigrationBase`](https://github.com/obelawium/ium/blob/main/src/Bases/MigrationBase.php) and sets `protected ?string $module = '<slug>_';`.
- **Why**: `ModelBase` automatically prefixes every model's table with `ium_<slug>_` and binds the dynamic connection configured at `GlobalConfigManager::get('obelawium.db.connection')`. `MigrationBase` initializes `$this->prefix` to `'ium_<slug>_'`.

### Step 4: Create the Domain Gateway (`<Module>Domain.php`) & Manager (`<Module>Manager.php`)
- `<Module>Domain` **must** extend [`Obelaw\Ium\Abstracts\Domain`](https://github.com/obelawium/ium/blob/main/src/Abstracts/Domain.php) (`ObelawiumManager::registerDomain()` throws `\InvalidArgumentException` otherwise).
- Accept `ObelawConfigManager $config` in `__construct()` and pass it to `parent::__construct($config)`.
- Expose domain services as fluent methods returning strongly typed service instances:
  ```php
  final class CrmDomain extends Domain
  {
      public function __construct(
          ObelawConfigManager $config,
          private readonly ?CrmManager $manager = null
      ) {
          parent::__construct($config);
      }

      public function leads(): LeadService
      {
          return ($this->manager ?? app(CrmManager::class))->leads();
      }
  }
  ```

### Step 5: Create and Register the Service Provider
In `src/Providers/Obelaw<Module>ServiceProvider.php`:
- In `register()`:
  1. Merge default configuration: `$this->mergeConfigFrom(__DIR__ . '/../../config/<slug>.php', 'ium.<slug>');`
  2. Bind `<Module>Manager` and all domain services as singletons (`$this->app->singleton(...)`).
  3. Register the domain with the central gateway:
     ```php
     Ium::registerDomain('<slug>', <Module>Domain::class);
     ```
     *(Never use macros; always use `Ium::registerDomain()`)*.
- In `boot()`:
  1. Load migrations (respecting `ObelawConfigManager::getInstance()->get('obelawium.db.migrations', true)`).
  2. Register publish groups (`ium-<slug>-migrations`, `ium-<slug>-config`).
  3. Register package version metadata with `AboutCommand::add('Obelawium', fn() => ['Obelawium <Module>' => '0.1.0'])`.

### Step 6: Design Immutable DTOs (`src/Data/`)
- Never pass raw arrays (`$request->all()`) into domain services.
- Choose one of the two standard IUM DTO patterns:
  1. **Constructor-Validated `BaseDto`**: Extend [`Obelaw\Ium\Bases\BaseDto`](https://github.com/obelawium/ium/blob/main/src/Bases/BaseDto.php) and implement `protected function rules(): array`. `new MyDto($data)` automatically validates via Laravel's `Validator` and hydrates public readonly properties.
  2. **Explicit `final readonly class`**: Define typed constructor properties alongside `public static function from(array $data): self` and `public function toArray(): array`.
- See [Boilerplate Templates — DTOs](./references/template-files.md#8-srcdatacreateentitydtophp-two-supported-patterns).

### Step 7: Build Eloquent Models (`src/Models/`) & Migrations (`database/migrations/`)
- **Models**: Extend `Obelaw\Ium\<Module>\Base\ModelBase`.
  - If overriding `$table`, specify **only the un-prefixed table name** (e.g., `protected $table = 'leads';`). Never include `ium_<slug>_` in `$table`, or it will be double-prefixed (`ium_crm_ium_crm_leads`).
- **Migrations**: Extend `Obelaw\Ium\<Module>\Base\MigrationBase`.
  - Always use `$this->prefix . '<table_name>'` in `Schema::create()` and `Schema::dropIfExists()`.
  - For internal foreign keys within the same module, reference `$this->prefix . '<parent_table>'`.

### Step 8: Implement Domain Services, Invariants & Transactions (`src/Services/`)
- Encapsulate all multi-step database writes inside `DB::transaction(function () { ... })`.
- Validate domain invariants before persisting and throw descriptive domain exceptions (`src/Exceptions/`) when violated.
- Dispatch past-tense domain events (`src/Events/<Entity>Created.php`) after state mutations complete.

### Step 9: Enforce Cross-Domain Isolation (Polymorphic Links & ACL)
- **No Cross-Domain SQL Foreign Keys**: Never write `->constrained('ium_other_table')` across different modules. Use polymorphic columns (`$table->nullableMorphs('reference')` or `source_type` / `source_id`).
- **Anti-Corruption Layer (ACL)**: When another domain needs to trigger actions in your module (or vice versa), communicate via domain events or a dedicated ACL ingestion service (such as `ium()->accounting()->acl()->ingest($dto)`).

### Step 10: Write PestPHP & Orchestra Testbench Tests (`tests/`)
- Configure `tests/TestCase.php` extending `Orchestra\Testbench\TestCase` loading both `ObelawiumServiceProvider` and `Obelaw<Module>ServiceProvider`.
- Test gateway resolution (`ium()->hasDomain('<slug>')`, `ium()-><slug>()`), DTO validation, service transactions, domain invariants, and table prefixing.
- Consult the [Testing & Verification Guide](./references/testing-and-verification.md) for complete setup and test patterns.

---

## 6. Agent Decision Matrix

| Task / Scenario | Target Location / API | Key Rule / Pattern |
| :--- | :--- | :--- |
| **Scaffold a new module** | `scripts/scaffold-module.ps1` | Generates full PSR-4 structure, provider, gateway, base classes, and tests. |
| **Register domain on `ium()`** | `Obelaw<Module>ServiceProvider::register()` | `Ium::registerDomain('<slug>', <Module>Domain::class)` |
| **Add a new service to domain** | `<Module>Manager` & `<Module>Domain` | Bind singleton in Provider, expose method on Manager and Domain gateway. |
| **Configure module table prefix** | `src/Base/ModelBase.php` & `MigrationBase.php` | Set `protected ?string $module = '<slug>_';` (with trailing underscore). |
| **Read/Write runtime IUM config** | `ium_config()` / `ium_set_config()` | Supports string keys or backed enums implementing `IumConfigEnum`. |
| **Switch DB connection globally** | `ium_set_config('obelawium.db.connection', 'tenant', true)` | Passing `$global = true` mirrors to `GlobalConfigManager` for `ModelBase`. |
| **Validate incoming service data** | `src/Data/<Action><Entity>Dto.php` | Extend `Obelaw\Ium\Bases\BaseDto` or use `final readonly class` with `from()`. |
| **Reference external domain entity** | Migration & Model | Use `source_type` + `source_id` morphs; never cross-domain foreign keys. |

---

## 7. Reference Documentation

- [**Architecture & Core Engine Reference**](./references/architecture.md) — Complete internals of [`obelaw/ium`](https://github.com/obelawium/ium) (`ObelawiumManager`, `Domain`, `BaseDto`, `ModelBase`, `MigrationBase`, `ObelawConfigManager`, `GlobalConfigManager`, `IumConfigEnum`, and helpers).
- [**Boilerplate Templates**](./references/template-files.md) — Copy-pasteable templates for all 14 standard module files.
- [**Conventions & Verification Checklist**](./references/conventions.md) — Naming matrix across real Obelawium packages, "The Law" invariants, and pre-flight checklist.
- [**Testing & Verification Guide**](./references/testing-and-verification.md) — `phpunit.xml`, `tests/Pest.php`, `tests/TestCase.php`, and feature/unit test suites.
- [**Module Scaffolding Script**](./scripts/scaffold-module.ps1) — Automated PowerShell generator for new IUM modules.
