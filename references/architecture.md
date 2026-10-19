# Obelawium (`obelaw/ium`) Core Architecture Reference

This document details the internal architecture, classes, lifecycles, and design invariants of the core [`obelaw/ium`](https://github.com/obelawium/ium) package and how domain modules integrate with it.

---

## 1. Architectural Philosophy

Obelawium (IUM) is an enterprise modular ERP core framework for Laravel (`^12.0|^13.0`). It strictly decouples business domain logic from presentation layers (HTTP controllers, Blade views, Livewire, Inertia, or Filament admin panels).

Domains exist as autonomous, headless packages that communicate through a unified fluent DSL and domain events:

```text
ium() → [domain]() → [service]() → [method]()
```

For example:
```php
$lead = ium()->crm()->leads()->create($dto);
$submission = ium()->forms()->submissions()->submit($dto);
$stock = ium()->wms()->stockItems()->getAvailable($sku);
```

---

## 2. Core Engine Classes (`obelaw/ium`)

### A. `ObelawiumManager` ([`Obelaw\Ium\ObelawiumManager`](https://github.com/obelawium/ium/blob/main/src/ObelawiumManager.php))
The central singleton registry and gateway for all Obelawium domains.
- **Singleton & Container Binding**: Registered as a singleton in [`ObelawiumServiceProvider`](https://github.com/obelawium/ium/blob/main/src/Providers/ObelawiumServiceProvider.php) via `ObelawiumManager::getInstance()`.
- **Properties**:
  - `public readonly ObelawConfigManager $config`: Holds the shared `ObelawConfigManager` singleton.
  - `private array $domains = []`: Maps domain names (`string`) to domain classes (`class-string<Domain>`).
- **Key Methods**:
  - `registerDomain(string $name, string $domain): self`: Validates `is_subclass_of($domain, Domain::class)` (throws `\InvalidArgumentException` if not) and registers the domain on the singleton instance.
  - `hasDomain(string $name): bool` / `getDomain(string $name): ?string` / `getDomains(): array`: Inspects registered domains.
  - `__invoke(array $configs = []): self`: Merges an array of configuration values into `$this->config` and returns `$this` for fluent chaining (`ium(['key' => 'val'])->crm()`).
  - `__call(string $name, array $arguments): mixed`: Resolves a registered domain via `new $domain($this->config())`. Throws `\BadMethodCallException` if the domain is not registered.
  - `reset(): self`: Clears all stored configs and registered domains (useful in test tearDown/isolation).

### B. `Domain` Abstract Base ([`Obelaw\Ium\Abstracts\Domain`](https://github.com/obelawium/ium/blob/main/src/Abstracts/Domain.php))
Every domain entry gateway class **must** extend `Obelaw\Ium\Abstracts\Domain`:
```php
namespace Obelaw\Ium\Abstracts;

use Obelaw\Ium\Engine\ObelawConfigManager;

class Domain
{
    public function __construct(private ObelawConfigManager $config) {}
}
```
When `ium()-><slug>()` is called, `ObelawiumManager` instantiates the registered `Domain` subclass, passing `$this->config()` as the first constructor argument.

### C. `Ium` Facade ([`Obelaw\Ium\Facades\Ium`](https://github.com/obelawium/ium/blob/main/src/Facades/Ium.php))
Provides static access to `ObelawiumManager`:
- `Ium::registerDomain(string $name, string $domain)`
- `Ium::hasDomain(string $name)`
- `Ium::getDomain(string $name)`
- `Ium::getDomains()`
- `Ium::config()`
- `Ium::reset()`

### D. Configuration Engine
Obelawium includes a two-tier runtime configuration system:

1. **`ObelawConfigManager`** ([`Obelaw\Ium\Engine\ObelawConfigManager`](https://github.com/obelawium/ium/blob/main/src/Engine/ObelawConfigManager.php)):
   - Process-local singleton store (`ObelawConfigManager::getInstance()`).
   - Accepts plain `string` keys or backed enums implementing [`IumConfigEnum`](https://github.com/obelawium/ium/blob/main/src/Contracts/IumConfigEnum.php).
   - Methods:
     - `get(IumConfigEnum|string $config, mixed $default = null): mixed`
     - `set(IumConfigEnum|string $config, mixed $value, ?bool $global = null): self` — when `$global === true`, also mirrors the value into `GlobalConfigManager`.
     - `defaults(IumConfigEnum|string $config, mixed $value): self` — sets value only if not already set.
     - `merge(array $configs): self` — recursively merges keyed values.
     - `all(): array` and `reset(): self`.

2. **`GlobalConfigManager`** ([`Obelaw\Ium\Engine\GlobalConfigManager`](https://github.com/obelawium/ium/blob/main/src/Engine/GlobalConfigManager.php)):
   - Static store (`GlobalConfigManager::set($key, $value)` / `GlobalConfigManager::get($key, $default)`).
   - Used in static or early lifecycle contexts such as `ModelBase::__construct()`, which checks `GlobalConfigManager::get('obelawium.db.connection')` to dynamically route models to a custom or tenant database connection.

3. **`IumConfigEnum` Contract** ([`Obelaw\Ium\Contracts\IumConfigEnum`](https://github.com/obelawium/ium/blob/main/src/Contracts/IumConfigEnum.php)):
   ```php
   namespace Obelaw\Ium\Contracts;

   interface IumConfigEnum extends \BackedEnum {}
   ```
   Modules can define their own backed string enum implementing `IumConfigEnum` for type-safe configuration keys:
   ```php
   namespace Obelaw\Ium\Crm\Enums;

   use Obelaw\Ium\Contracts\IumConfigEnum;

   enum CrmConfig: string implements IumConfigEnum
   {
       case AUTO_ASSIGN = 'crm.auto_assign';
       case DEFAULT_STATUS = 'crm.default_status';
   }
   ```

### E. Global Helper Functions ([`src/helpers.php`](https://github.com/obelawium/ium/blob/main/src/helpers.php))
Autoloaded globally by `obelaw/ium`:
- `ium(array $configs = []): ObelawiumManager` — resolves `ObelawiumManager` from the container and optionally merges `$configs`.
- `ium_config(IumConfigEnum|string $enum, mixed $default = null): mixed` — shorthand for `ium()->config()->get($enum, $default)`.
- `ium_set_config(IumConfigEnum|string $enum, mixed $value, ?bool $global = null): void` — shorthand for `ium()->config()->set($enum, $value, $global)`.

---

## 3. Base Persistence & DTO Classes

### A. `ModelBase` ([`Obelaw\Ium\Bases\ModelBase`](https://github.com/obelawium/ium/blob/main/src/Bases/ModelBase.php))
```php
namespace Obelaw\Ium\Bases;

use Illuminate\Database\Eloquent\Model;
use Obelaw\Ium\Engine\GlobalConfigManager;

class ModelBase extends Model
{
    protected string $prefix = 'ium_';
    protected ?string $module = null;

    public function __construct(array $attributes = [])
    {
        parent::__construct($attributes);

        $prefix = $this->module ? $this->prefix . $this->module : $this->prefix;

        if ($connection = GlobalConfigManager::get('obelawium.db.connection')) {
            $this->setConnection($connection);
        }

        $this->setTable($prefix . $this->getTable());
    }
}
```
- Every module defines `Obelaw\Ium\<Module>\Base\ModelBase` extending `Obelaw\Ium\Bases\ModelBase` with `protected ?string $module = '<slug>_';`.
- An Eloquent model `Lead` in module `crm` automatically resolves its table as `ium_crm_leads`.

### B. `MigrationBase` ([`Obelaw\Ium\Bases\MigrationBase`](https://github.com/obelawium/ium/blob/main/src/Bases/MigrationBase.php))
```php
namespace Obelaw\Ium\Bases;

use Illuminate\Database\Migrations\Migration;

abstract class MigrationBase extends Migration
{
    protected string $prefix = 'ium_';
    protected ?string $module = null;

    public function __construct()
    {
        $this->prefix = $this->module ? $this->prefix . $this->module : $this->prefix;
    }
}
```
- Every module defines `Obelaw\Ium\<Module>\Base\MigrationBase` extending `Obelaw\Ium\Bases\MigrationBase` with `protected ?string $module = '<slug>_';`.
- Migrations use `Schema::create($this->prefix . 'leads', ...)` which creates `ium_crm_leads`.

### C. `BaseDto` ([`Obelaw\Ium\Bases\BaseDto`](https://github.com/obelawium/ium/blob/main/src/Bases/BaseDto.php))
```php
namespace Obelaw\Ium\Bases;

readonly abstract class BaseDto
{
    public function __construct(array $data)
    {
        $this->validate($data);
        $this->hydrate($data);
    }
    // ...
    abstract protected function rules(): array;
}
```
- `BaseDto` is a `readonly abstract class` that runs `Validator::make($data, $this->rules())` on construction, throws `\Exception($validator->errors()->first())` on failure, and hydrates matching public properties on `$this`.
- Provides `toArray(): array` via `get_object_vars($this)`.

---

## 4. Non-Negotiable Architectural Invariants ("The Law")

1. **Zero Presentation / Headless**:
   - No HTTP routes, controllers, Livewire components, or Blade templates inside domain packages. Presentation belongs exclusively to application shells or dedicated UI packages.
2. **Zero Cross-Domain SQL Foreign Keys**:
   - Never enforce physical SQL foreign keys across different domain packages.
   - Use polymorphic relations (`morphTo` / `morphMany`) or loosely coupled reference IDs (`source_type`, `source_id`) with morph maps (`Relation::enforceMorphMap()`).
3. **Immutability & Auditability**:
   - Critical domain states (e.g., posted ledger entries, published schemas, finalized transactions) must be immutable or versioned snapshots with append-only audit trails.
4. **Transactional Mutation Atomicity**:
   - Multi-step write mutations (persisting records, writing audit logs, dispatching domain events) must be wrapped in `DB::transaction()`.
5. **Strict DTO Contracts**:
   - Data entering domain services must pass through typed Data Transfer Objects (`src/Data/`). Never pass raw unchecked `$request->all()` arrays into domain services.
6. **Event-Driven & ACL Cross-Domain Integration**:
   - Domains publish domain events (`LeadCreated`, `JournalEntryPosted`, `FormSubmissionReceived`) and ingest cross-domain commands through Anti-Corruption Layer (ACL) services.

