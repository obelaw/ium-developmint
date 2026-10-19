# Obelawium Conventions & Verification Checklist

## 1. Naming Conventions Matrix Across Ecosystem Packages

| Concern | Convention | Example (`accounting`) | Example (`forms`) | Example (`crm`) |
| :--- | :--- | :--- | :--- | :--- |
| **Monorepo Directory** | `packages/<slug>` | `packages/accounting` | `packages/forms` | `packages/crm` |
| **Composer Package** | `obelaw/ium-<slug>` | `obelaw/ium-accounting` | `obelaw/ium-forms` | `obelaw/ium-crm` |
| **PHP Root Namespace** | `Obelaw\Ium\<Module>\` | `Obelaw\Ium\Accounting\` | `Obelaw\Ium\Forms\` | `Obelaw\Ium\Crm\` |
| **Test Namespace** | `Obelaw\Ium\<Module>\Tests\` | `Obelaw\Ium\Accounting\Tests\` | `Obelaw\Ium\Forms\Tests\` | `Obelaw\Ium\Crm\Tests\` |
| **Domain Registration Key**| `<slug>` | `'accounting'` | `'forms'` | `'crm'` |
| **Fluent Invocation** | `ium()-><slug>()` | `ium()->accounting()` | `ium()->forms()` | `ium()->crm()` |
| **Domain Entry Class** | `<Module>Domain` | `AccountingDomain` | `FormsDomain` | `CrmDomain` |
| **Domain Manager** | `<Module>Manager` | `AccountingManager` | `FormsManager` | `CrmManager` |
| **Service Provider** | `Obelaw<Module>ServiceProvider` | `ObelawAccountingServiceProvider` | `ObelawFormsServiceProvider` | `ObelawCrmServiceProvider` |
| **Physical Table Prefix** | `ium_<slug>_` | `ium_accounting_` | `ium_forms_` | `ium_crm_` |
| **Module Prefix Property** | `'<slug>_'` | `'accounting_'` | `'forms_'` | `'crm_'` |
| **Config File** | `config/<slug>.php` | `config/accounting.php` | `config/forms.php` | `config/crm.php` |
| **Config Key** | `ium.<slug>` | `ium.accounting` | `ium.forms` | `ium.crm` |
| **DTO Class** | `<Action><Entity>Dto` | `CreateAccountDto` | `SubmitFormDto` | `CreateLeadDto` |
| **Domain Event** | `<Entity><PastTenseVerb>` | `JournalEntryPosted` | `FormSubmissionReceived` | `LeadCreated` |

---

## 2. Standard Directory Topology

Every Obelawium domain module adheres to this directory layout:

```text
packages/<slug>/
├── composer.json
├── phpunit.xml
├── README.md
├── config/
│   └── <slug>.php
├── database/
│   └── migrations/
│       └── 2026_01_01_000001_create_<slug>_<entities>_table.php
├── src/
│   ├── <Module>Domain.php
│   ├── <Module>Manager.php
│   ├── Base/
│   │   ├── MigrationBase.php
│   │   └── ModelBase.php
│   ├── Contracts/
│   ├── Data/
│   │   └── Create<Entity>Dto.php
│   ├── Enums/
│   │   ├── <Entity>Status.php
│   │   └── <Module>ConfigEnum.php
│   ├── Events/
│   │   └── <Entity>Created.php
│   ├── Exceptions/
│   │   └── <Entity>NotFoundException.php
│   ├── Models/
│   │   └── <Entity>.php
│   ├── Providers/
│   │   └── Obelaw<Module>ServiceProvider.php
│   └── Services/
│       └── <Entity>Service.php
└── tests/
    ├── Pest.php
    ├── TestCase.php
    ├── Feature/
    │   └── IumGatewayIntegrationTest.php
    └── Unit/
        └── DataTransferObjectsTest.php
```

---

## 3. Core Architectural Rules

1. **Strict Table Prefixing**:
   - Every Eloquent model extends `Obelaw\Ium\<Module>\Base\ModelBase` (which extends [`Obelaw\Ium\Bases\ModelBase`](https://github.com/obelawium/ium/blob/main/src/Bases/ModelBase.php)).
   - Never hardcode `ium_<slug>_` in `$table = '...'`. Specify only the un-prefixed table name (e.g. `protected $table = 'leads';`).
   - Always include the trailing underscore in `protected ?string $module = '<slug>_';`.
   - In migrations, always use `$this->prefix . '<table_name>'`.

2. **Domain Registration Mechanism**:
   - Register the domain inside `Obelaw<Module>ServiceProvider::register()` using:
     ```php
     Ium::registerDomain('<slug>', <Module>Domain::class);
     ```
   - `<Module>Domain` MUST extend [`Obelaw\Ium\Abstracts\Domain`](https://github.com/obelawium/ium/blob/main/src/Abstracts/Domain.php).
   - Never use `ObelawiumManager::macro()`.

3. **No Presentation Code**:
   - Domain packages MUST NOT contain HTTP Controllers, Routes, Middleware, Livewire components, Inertia responses, or Blade views.

4. **Zero Cross-Domain Foreign Keys**:
   - Never add `$table->foreignId('order_id')->references('id')->on('ium_pos_orders')` across different domain packages.
   - Use polymorphic columns (`$table->nullableMorphs('source')`) or Anti-Corruption Layer (ACL) services.

5. **Type Safety, Immutability & Transactions**:
   - Declare `declare(strict_types=1);` at the top of every PHP file.
   - Use `final readonly class` or `Obelaw\Ium\Bases\BaseDto` for DTOs.
   - Use PHP 8.2+ backed enums (`string` or `int`) for statuses, types, and config keys (`IumConfigEnum`).
   - Wrap multi-step write mutations in `DB::transaction()`.

---

## 4. Pre-Flight Verification Checklist

Before committing or publishing a new or updated IUM module, verify every item below:

- [ ] **`composer.json`**:
  - [ ] Package name is `obelaw/ium-<slug>`.
  - [ ] Requires `"obelaw/ium": "*"`.
  - [ ] PSR-4 autoload maps `Obelaw\Ium\<Module>\` to `src/` and `Obelaw\Ium\<Module>\Tests\` to `tests/`.
  - [ ] `extra.laravel.providers` registers `Obelaw\Ium\<Module>\Providers\Obelaw<Module>ServiceProvider`.
- [ ] **`src/Base/ModelBase.php` & `src/Base/MigrationBase.php`**:
  - [ ] Extend `Obelaw\Ium\Bases\ModelBase` and `Obelaw\Ium\Bases\MigrationBase` respectively.
  - [ ] Both set `protected ?string $module = '<slug>_';` (with trailing underscore).
- [ ] **`src/<Module>Domain.php`**:
  - [ ] Extends `Obelaw\Ium\Abstracts\Domain`.
  - [ ] Constructor accepts `ObelawConfigManager $config` and calls `parent::__construct($config)`.
  - [ ] Exposes domain services with explicit return type hints.
- [ ] **`src/Providers/Obelaw<Module>ServiceProvider.php`**:
  - [ ] Calls `Ium::registerDomain('<slug>', <Module>Domain::class)` in `register()`.
  - [ ] Merges config via `$this->mergeConfigFrom(__DIR__ . '/../../config/<slug>.php', 'ium.<slug>')`.
  - [ ] Binds `<Module>Manager` and domain services as singletons.
  - [ ] Loads migrations and registers publish groups (`ium-<slug>-migrations`, `ium-<slug>-config`) in `boot()`.
- [ ] **Migrations & Models**:
  - [ ] All migrations extend `Obelaw\Ium\<Module>\Base\MigrationBase` and use `$this->prefix . '<table_name>'`.
  - [ ] All models extend `Obelaw\Ium\<Module>\Base\ModelBase` without duplicating the `ium_<slug>_` prefix.
  - [ ] Zero foreign key constraints point to tables outside `ium_<slug>_*`.
- [ ] **Tests & Runtime Verification**:
  - [ ] `composer dump-autoload` completes with zero warnings.
  - [ ] `ium()->hasDomain('<slug>')` returns `true`.
  - [ ] `ium()-><slug>()` resolves an instance of `<Module>Domain`.
  - [ ] `./vendor/bin/pest` passes all unit and feature tests.

