# Testing & Verification Guide for Obelawium Modules

Every Obelawium (`obelaw/ium-<slug>`) module is tested in isolation using **Orchestra Testbench**, **PestPHP**, and an **in-memory SQLite database**.

---

## 1. Test Configuration Files

### A. `phpunit.xml`

Place at the root of the module (`packages/<slug>/phpunit.xml`):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<phpunit xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:noNamespaceSchemaLocation="vendor/phpunit/phpunit/phpunit.xsd"
         bootstrap="vendor/autoload.php"
         colors="true"
         failOnRisky="true"
         failOnWarning="true">
    <testsuites>
        <testsuite name="Unit">
            <directory>tests/Unit</directory>
        </testsuite>
        <testsuite name="Feature">
            <directory>tests/Feature</directory>
        </testsuite>
    </testsuites>
    <source>
        <include>
            <directory>src</directory>
        </include>
    </source>
    <php>
        <env name="APP_ENV" value="testing"/>
        <env name="DB_CONNECTION" value="testing"/>
        <env name="DB_DATABASE" value=":memory:"/>
    </php>
</phpunit>
```

### B. `tests/Pest.php`

```php
<?php

declare(strict_types=1);

use Obelaw\Ium\<Module>\Tests\TestCase;

uses(TestCase::class)->in('Feature', 'Unit');
```

### C. `tests/TestCase.php`

Must load both [`Obelaw\Ium\Providers\ObelawiumServiceProvider`](https://github.com/obelawium/ium/blob/main/src/Providers/ObelawiumServiceProvider.php) and your module's `Obelaw<Module>ServiceProvider`:

```php
<?php

declare(strict_types=1);

namespace Obelaw\Ium\<Module>\Tests;

use Obelaw\Ium\<Module>\Providers\Obelaw<Module>ServiceProvider;
use Obelaw\Ium\Providers\ObelawiumServiceProvider;
use Orchestra\Testbench\TestCase as Orchestra;

abstract class TestCase extends Orchestra
{
    protected function getPackageProviders($app): array
    {
        return [
            ObelawiumServiceProvider::class,
            Obelaw<Module>ServiceProvider::class,
        ];
    }

    protected function defineEnvironment($app): void
    {
        $app['config']->set('database.default', 'testing');
        $app['config']->set('database.connections.testing', [
            'driver'   => 'sqlite',
            'database' => ':memory:',
            'prefix'   => '',
        ]);
        $app['config']->set('app.key', 'base64:6Cu/eaCLkLzW19Y7W1+kZ+RzF1/5tN2qE8O7r5m4r9s=');
    }

    protected function setUp(): void
    {
        parent::setUp();

        $this->artisan('migrate')->run();
    }
}
```

---

## 2. Standard Test Suites

### A. Gateway & Service Provider Integration Test (`tests/Feature/IumGatewayIntegrationTest.php`)

Verifies that the module registers with `ObelawiumManager`, resolves via `ium()-><slug>()`, prefixes tables properly, and executes service mutations:

```php
<?php

declare(strict_types=1);

use Illuminate\Support\Facades\Event;
use Illuminate\Support\Facades\Schema;
use Obelaw\Ium\<Module>\<Module>Domain;
use Obelaw\Ium\<Module>\Data\Create<Entity>Dto;
use Obelaw\Ium\<Module>\Events\<Entity>Created;
use Obelaw\Ium\<Module>\Models\<Entity>;

it('registers the <module> domain with the central ium gateway', function (): void {
    expect(ium()->hasDomain('<module>'))->toBeTrue()
        ->and(ium()->getDomain('<module>'))->toBe(<Module>Domain::class)
        ->and(ium()-><module>())->toBeInstanceOf(<Module>Domain::class);
});

it('creates prefixed database tables via MigrationBase', function (): void {
    expect(Schema::hasTable('ium_<module>_<entities>'))->toBeTrue();

    $model = new <Entity>();
    expect($model->getTable())->toBe('ium_<module>_<entities>');
});

it('creates and queries entities through the fluent ium()-><module>() DSL', function (): void {
    Event::fake([<Entity>Created::class]);

    $dto = Create<Entity>Dto::from([
        'code'     => 'REC-001',
        'name'     => 'Primary Record',
        'actor_id' => 'actor-123',
        'metadata' => ['tier' => 'enterprise'],
    ]);

    $created = ium()-><module>()-><entities>()->create($dto);

    expect($created)->toBeInstanceOf(<Entity>::class)
        ->and($created->code)->toBe('REC-001')
        ->and($created->name)->toBe('Primary Record')
        ->and(ium()-><module>()-><entities>()->list())->toHaveCount(1);

    Event::assertDispatched(<Entity>Created::class, fn (<Entity>Created $e) => $e->entity->id === $created->id);
});
```

### B. Configuration & Dynamic Connection Test (`tests/Unit/ConfigAndConnectionTest.php`)

Verifies `ObelawConfigManager`, `GlobalConfigManager`, and `ModelBase` connection routing:

```php
<?php

declare(strict_types=1);

use Obelaw\Ium\Engine\GlobalConfigManager;
use Obelaw\Ium\<Module>\Models\<Entity>;

it('supports runtime config merging and global db connection switching', function (): void {
    ium(['<module>.custom_flag' => 'enabled']);

    expect(ium_config('<module>.custom_flag'))->toBe('enabled');

    // Setting with $global = true mirrors into GlobalConfigManager for ModelBase
    ium_set_config('obelawium.db.connection', 'tenant_sqlite', true);
    expect(GlobalConfigManager::get('obelawium.db.connection'))->toBe('tenant_sqlite');

    $model = new <Entity>();
    expect($model->getConnectionName())->toBe('tenant_sqlite');

    // Reset after test
    ium_set_config('obelawium.db.connection', null, true);
});
```

---

## 3. Running Tests

Execute the test suite from the module root (`packages/<slug>`):

```powershell
# Run full Pest suite
./vendor/bin/pest

# Run specific test file or filter
./vendor/bin/pest --filter="IumGatewayIntegrationTest"
```

