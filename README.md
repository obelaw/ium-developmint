# Obelawium Module Development Skill (`ium-developmint`)

[![Skill Version](https://img.shields.io/badge/skill-v1.0.0-blue.svg)](./onsynk.json)
[![Core Package](https://img.shields.io/badge/core-obelaw%2Fium-emerald.svg)](https://github.com/obelawium/ium)
[![License](https://img.shields.io/badge/license-MIT-lightgrey.svg)](./onsynk.json)

An AI agent and developer skill for architecting, scaffolding, building, testing, and maintaining headless domain modules within the **Obelawium (IUM)** ERP ecosystem ([`obelaw/ium`](https://github.com/obelawium/ium)).

---

## Key Capabilities

- **Fluent Gateway DSL**: Unified domain entry and orchestration via `ium()->[domain]()->[service]()->[method]()`.
- **Core Engine Primitives**: Detailed coverage of [`ObelawiumManager`](https://github.com/obelawium/ium/blob/main/src/ObelawiumManager.php), [`Domain`](https://github.com/obelawium/ium/blob/main/src/Abstracts/Domain.php), [`ObelawConfigManager`](https://github.com/obelawium/ium/blob/main/src/Engine/ObelawConfigManager.php), [`GlobalConfigManager`](https://github.com/obelawium/ium/blob/main/src/Engine/GlobalConfigManager.php), [`IumConfigEnum`](https://github.com/obelawium/ium/blob/main/src/Contracts/IumConfigEnum.php), [`BaseDto`](https://github.com/obelawium/ium/blob/main/src/Bases/BaseDto.php), [`ModelBase`](https://github.com/obelawium/ium/blob/main/src/Bases/ModelBase.php), and [`MigrationBase`](https://github.com/obelawium/ium/blob/main/src/Bases/MigrationBase.php).
- **Automated Module Scaffolding**: Turnkey PowerShell scaffolding script ([`scripts/scaffold-module.ps1`](./scripts/scaffold-module.ps1)) that generates a complete, test-ready module skeleton in seconds.
- **Persistence & Multi-Tenancy Isolation**: Automatic `ium_<slug>_` table prefixing and dynamic database connection routing (`obelawium.db.connection`).
- **Strict Domain Boundaries**: Headless business engine architecture, immutable DTO contracts, `DB::transaction()` atomicity, polymorphic cross-domain references, and Anti-Corruption Layer (ACL) event ingestion.
- **Orchestra Testbench & PestPHP Setup**: Ready-to-use testing templates for isolated in-memory SQLite verification.

---

## Quick Example

```php
use Obelaw\Ium\Crm\Data\CreateLeadDto;

// 1. Check domain registration
if (ium()->hasDomain('crm')) {
    // 2. Execute domain mutation via fluent DSL
    $lead = ium()->crm()->leads()->create(CreateLeadDto::from([
        'code'     => 'LEAD-2026-001',
        'name'     => 'Acme Corporation',
        'actor_id' => 'user-01',
    ]));

    // 3. Query domain service
    $activeLeads = ium()->crm()->leads()->list();
}
```

---

## Fast Scaffolding

Generate a complete, compliant module skeleton using the bundled script:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/scaffold-module.ps1 -Slug crm -ModuleName Crm -Entity Lead -BasePath packages
```

---

## References & Documentation

| Document | Purpose |
| :--- | :--- |
| [**SKILL.md**](./SKILL.md) | Core philosophy, naming conventions, 10-step development workflow, and decision matrix. |
| [**Architecture & Core Engine**](./references/architecture.md) | Deep dive into `obelaw/ium` internals (`ObelawiumManager`, config managers, helpers, base classes, and lifecycle). |
| [**Boilerplate Templates**](./references/template-files.md) | Copy-pasteable PHP & JSON templates for every file in a compliant IUM domain module. |
| [**Conventions & Checklist**](./references/conventions.md) | Naming matrix across real modules, architectural invariants, and pre-flight verification checklist. |
| [**Testing & Verification**](./references/testing-and-verification.md) | Orchestra Testbench setup, PestPHP configuration, gateway integration tests, and DTO/Model unit test patterns. |
| [**Scaffolding Script**](./scripts/scaffold-module.ps1) | PowerShell automation script to scaffold new IUM domain packages. |

---

## License

Licensed under the [MIT License](./onsynk.json).
