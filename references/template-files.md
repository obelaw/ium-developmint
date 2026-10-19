# Obelawium Module Boilerplate Templates

Use these copy-pasteable templates when creating a new Obelawium domain module. Replace `<Module>` with PascalCase (e.g. `Crm`), `<module>` with lowercase slug (e.g. `crm`), `<Entity>` with singular PascalCase entity (e.g. `Lead`), and `<entities>` with plural snake_case/camelCase (e.g. `leads`).

---

## 1. `composer.json`

```json
{
    "name": "obelaw/ium-<module>",
    "description": "Headless business domain logic for Obelawium <Module>",
    "license": "MIT",
    "authors": [
        {
            "name": "Karim Mohamed",
            "email": "komicho1996@gmail.com"
        }
    ],
    "require": {
        "php": "^8.2",
        "obelaw/ium": "*",
        "laravel/framework": "^12.0|^13.0"
    },
    "require-dev": {
        "pestphp/pest": "^3.0|^4.0",
        "pestphp/pest-plugin-laravel": "^3.0|^4.0",
        "orchestra/testbench": "^10.0|^11.0"
    },
    "autoload": {
        "psr-4": {
            "Obelaw\\Ium\\<Module>\\": "src/"
        }
    },
    "autoload-dev": {
        "psr-4": {
            "Obelaw\\Ium\\<Module>\\Tests\\": "tests/"
        }
    },
    "extra": {
        "laravel": {
            "providers": [
                "Obelaw\\Ium\\<Module>\\Providers\\Obelaw<Module>ServiceProvider"
            ]
        }
    },
    "config": {
        "allow-plugins": {
            "pestphp/pest-plugin": true
        }
    },
    "minimum-stability": "dev",
    "prefer-stable": true
}
```

---

## 2. `config/<module>.php`

```php
<?php

declare(strict_types=1);

return [
    /*
    |--------------------------------------------------------------------------
    | Database Table Prefix
    |--------------------------------------------------------------------------
    |
    | Module-specific prefix appended after 'ium_' (resulting in 'ium_<module>_').
    |
    */
    'table_prefix' => '<module>_',

    /*
    |--------------------------------------------------------------------------
    | Domain Settings
    |--------------------------------------------------------------------------
    */
    'enabled' => true,
];
```

---

## 3. `src/Base/ModelBase.php`

Extends [`Obelaw\Ium\Bases\ModelBase`](https://github.com/obelawium/ium/blob/main/src/Bases/ModelBase.php):

```php
<?php

declare(strict_types=1);

namespace Obelaw\Ium\<Module>\Base;

use Obelaw\Ium\Bases\ModelBase as StackBaseModel;

abstract class ModelBase extends StackBaseModel
{
    /**
     * Module name for table prefixing ('ium_<module>_').
     */
    protected ?string $module = '<module>_';
}
```

---

## 4. `src/Base/MigrationBase.php`

Extends [`Obelaw\Ium\Bases\MigrationBase`](https://github.com/obelawium/ium/blob/main/src/Bases/MigrationBase.php):

```php
<?php

declare(strict_types=1);

namespace Obelaw\Ium\<Module>\Base;

use Obelaw\Ium\Bases\MigrationBase as StackMigrationBase;

abstract class MigrationBase extends StackMigrationBase
{
    /**
     * Module name for table prefixing ('ium_<module>_').
     */
    protected ?string $module = '<module>_';
}
```

---

## 5. `src/<Module>Domain.php` (Domain Gateway)

Extends [`Obelaw\Ium\Abstracts\Domain`](https://github.com/obelawium/ium/blob/main/src/Abstracts/Domain.php):

```php
<?php

declare(strict_types=1);

namespace Obelaw\Ium\<Module>;

use Obelaw\Ium\Abstracts\Domain;
use Obelaw\Ium\Engine\ObelawConfigManager;
use Obelaw\Ium\<Module>\Services\<Entity>Service;

/**
 * <Module> Domain Gateway for Obelawium.
 *
 * Implements the fluent chain: ium()-><module>()-><entities>()-><method>()
 */
final class <Module>Domain extends Domain
{
    public function __construct(
        ObelawConfigManager $config,
        private readonly ?<Module>Manager $manager = null
    ) {
        parent::__construct($config);
    }

    private function getManager(): <Module>Manager
    {
        return $this->manager ?? app(<Module>Manager::class);
    }

    /**
     * Access the <Entity> domain service.
     */
    public function <entities>(): <Entity>Service
    {
        return $this->getManager()-><entities>();
    }
}
```

---

## 6. `src/<Module>Manager.php`

```php
<?php

declare(strict_types=1);

namespace Obelaw\Ium\<Module>;

use Obelaw\Ium\<Module>\Services\<Entity>Service;

/**
 * Coordinates internal services for the <Module> domain.
 */
final class <Module>Manager
{
    public function <entities>(): <Entity>Service
    {
        return app(<Entity>Service::class);
    }
}
```

---

## 7. `src/Providers/Obelaw<Module>ServiceProvider.php`

Registers the domain via [`Obelaw\Ium\Facades\Ium`](https://github.com/obelawium/ium/blob/main/src/Facades/Ium.php):

```php
<?php

declare(strict_types=1);

namespace Obelaw\Ium\<Module>\Providers;

use Illuminate\Foundation\Console\AboutCommand;
use Illuminate\Support\ServiceProvider;
use Obelaw\Ium\Engine\ObelawConfigManager;
use Obelaw\Ium\Facades\Ium;
use Obelaw\Ium\<Module>\<Module>Domain;
use Obelaw\Ium\<Module>\<Module>Manager;
use Obelaw\Ium\<Module>\Services\<Entity>Service;

final class Obelaw<Module>ServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->mergeConfigFrom(__DIR__ . '/../../config/<module>.php', 'ium.<module>');

        $this->app->singleton(<Module>Manager::class, static fn() => new <Module>Manager());
        $this->app->singleton(<Entity>Service::class);

        // Register domain with central Obelawium gateway
        Ium::registerDomain('<module>', <Module>Domain::class);
    }

    public function boot(): void
    {
        if (ObelawConfigManager::getInstance()->get('obelawium.db.migrations', true)) {
            $this->loadMigrationsFrom(__DIR__ . '/../../database/migrations');
        }

        if ($this->app->runningInConsole()) {
            $this->publishes([
                __DIR__ . '/../../database/migrations' => database_path('migrations'),
            ], 'ium-<module>-migrations');

            $this->publishes([
                __DIR__ . '/../../config/<module>.php' => config_path('ium/<module>.php'),
            ], 'ium-<module>-config');
        }

        AboutCommand::add('Obelawium', static fn() => ['Obelawium <Module>' => '0.1.0']);
    }
}
```

---

## 8. `src/Data/Create<Entity>Dto.php` (Two Supported Patterns)

### Pattern A: Explicit `final readonly class` with `from()` Factory (Recommended for Complex/Typed Payloads)

```php
<?php

declare(strict_types=1);

namespace Obelaw\Ium\<Module>\Data;

use InvalidArgumentException;

final readonly class Create<Entity>Dto
{
    /**
     * @param array<string, mixed> $metadata
     */
    public function __construct(
        public string $name,
        public string $code,
        public ?string $actorId = null,
        public array $metadata = [],
    ) {
        if (trim($this->name) === '') {
            throw new InvalidArgumentException('Name cannot be empty.');
        }
        if (trim($this->code) === '') {
            throw new InvalidArgumentException('Code cannot be empty.');
        }
    }

    /**
     * @param array<string, mixed> $data
     */
    public static function from(array $data): self
    {
        return new self(
            name: (string) ($data['name'] ?? throw new InvalidArgumentException('Name is required.')),
            code: (string) ($data['code'] ?? throw new InvalidArgumentException('Code is required.')),
            actorId: isset($data['actor_id']) ? (string) $data['actor_id'] : null,
            metadata: (array) ($data['metadata'] ?? []),
        );
    }

    /**
     * @return array<string, mixed>
     */
    public function toArray(): array
    {
        return [
            'name'     => $this->name,
            'code'     => $this->code,
            'actor_id' => $this->actorId,
            'metadata' => $this->metadata,
        ];
    }
}
```

### Pattern B: Extending `Obelaw\Ium\Bases\BaseDto` (Rule-Validated Hydration)

Extends [`Obelaw\Ium\Bases\BaseDto`](https://github.com/obelawium/ium/blob/main/src/Bases/BaseDto.php):

```php
<?php

declare(strict_types=1);

namespace Obelaw\Ium\<Module>\Data;

use Obelaw\Ium\Bases\BaseDto;

readonly class Create<Entity>Dto extends BaseDto
{
    public string $name;
    public string $code;
    public ?string $actor_id;
    public array $metadata;

    protected function rules(): array
    {
        return [
            'name'     => ['required', 'string', 'max:255'],
            'code'     => ['required', 'string', 'max:64'],
            'actor_id' => ['nullable', 'string'],
            'metadata' => ['nullable', 'array'],
        ];
    }
}
```

---

## 9. `src/Enums/<Entity>Status.php` & `src/Enums/<Module>ConfigEnum.php`

```php
<?php

declare(strict_types=1);

namespace Obelaw\Ium\<Module>\Enums;

enum <Entity>Status: string
{
    case ACTIVE = 'active';
    case ARCHIVED = 'archived';
}
```

```php
<?php

declare(strict_types=1);

namespace Obelaw\Ium\<Module>\Enums;

use Obelaw\Ium\Contracts\IumConfigEnum;

enum <Module>ConfigEnum: string implements IumConfigEnum
{
    case ENABLED = '<module>.enabled';
}
```

---

## 10. `src/Models/<Entity>.php`

```php
<?php

declare(strict_types=1);

namespace Obelaw\Ium\<Module>\Models;

use Obelaw\Ium\<Module>\Base\ModelBase;
use Obelaw\Ium\<Module>\Enums\<Entity>Status;

/**
 * Physical table resolved automatically as: 'ium_<module>_<entities>'
 */
class <Entity> extends ModelBase
{
    protected $table = '<entities>';

    protected $fillable = [
        'name',
        'code',
        'status',
        'metadata',
    ];

    protected $casts = [
        'status'   => <Entity>Status::class,
        'metadata' => 'array',
    ];
}
```

---

## 11. `src/Events/<Entity>Created.php` & `src/Exceptions/<Entity>NotFoundException.php`

```php
<?php

declare(strict_types=1);

namespace Obelaw\Ium\<Module>\Events;

use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;
use Obelaw\Ium\<Module>\Models\<Entity>;

final class <Entity>Created
{
    use Dispatchable, SerializesModels;

    public function __construct(
        public readonly <Entity> $entity,
        public readonly ?string $actorId = null,
    ) {}
}
```

```php
<?php

declare(strict_types=1);

namespace Obelaw\Ium\<Module>\Exceptions;

use RuntimeException;

final class <Entity>NotFoundException extends RuntimeException
{
    public static function withId(int|string $id): self
    {
        return new self("<Entity> with identifier [{$id}] was not found.");
    }
}
```

---

## 12. `src/Services/<Entity>Service.php`

```php
<?php

declare(strict_types=1);

namespace Obelaw\Ium\<Module>\Services;

use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Facades\DB;
use Obelaw\Ium\<Module>\Data\Create<Entity>Dto;
use Obelaw\Ium\<Module>\Enums\<Entity>Status;
use Obelaw\Ium\<Module>\Events\<Entity>Created;
use Obelaw\Ium\<Module>\Exceptions\<Entity>NotFoundException;
use Obelaw\Ium\<Module>\Models\<Entity>;

class <Entity>Service
{
    /**
     * Create a new <Entity> record atomically.
     */
    public function create(Create<Entity>Dto $dto): <Entity>
    {
        return DB::transaction(function () use ($dto): <Entity> {
            $entity = <Entity>::query()->create([
                'name'     => $dto->name,
                'code'     => $dto->code,
                'status'   => <Entity>Status::ACTIVE,
                'metadata' => $dto->metadata,
            ]);

            event(new <Entity>Created($entity, $dto->actorId));

            return $entity;
        });
    }

    /**
     * Retrieve all entities ordered by latest.
     *
     * @return Collection<int, <Entity>>
     */
    public function list(): Collection
    {
        return <Entity>::query()->latest()->get();
    }

    /**
     * Find an entity by ID or throw a domain exception.
     */
    public function findOrFail(int $id): <Entity>
    {
        $entity = <Entity>::query()->find($id);

        if (! $entity) {
            throw <Entity>NotFoundException::withId($id);
        }

        return $entity;
    }
}
```

---

## 13. `database/migrations/2026_01_01_000001_create_<module>_<entities>_table.php`

```php
<?php

declare(strict_types=1);

use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Obelaw\Ium\<Module>\Base\MigrationBase;

return new class extends MigrationBase {
    public function up(): void
    {
        Schema::create($this->prefix . '<entities>', function (Blueprint $table): void {
            $table->id();
            $table->string('code')->unique();
            $table->string('name');
            $table->string('status')->default('active')->index();
            $table->json('metadata')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists($this->prefix . '<entities>');
    }
};
```

