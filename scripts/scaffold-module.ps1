param (
    [Parameter(Mandatory = $true)]
    [string]$Slug,

    [Parameter(Mandatory = $false)]
    [string]$ModuleName,

    [Parameter(Mandatory = $false)]
    [string]$Entity = "Record",

    [Parameter(Mandatory = $false)]
    [string]$BasePath = ".."
)

# Normalize names
$Slug = $Slug.ToLower().Trim()

if (-not $ModuleName) {
    $ModuleName = (Get-Culture).TextInfo.ToTitleCase($Slug)
}

$EntityPascal = (Get-Culture).TextInfo.ToTitleCase($Entity)
$EntityPlural = $EntityPascal.ToLower() + "s"

$TargetDir = Join-Path $BasePath $Slug
Write-Host "Scaffolding new Obelawium module [$ModuleName] in [$TargetDir]..." -ForegroundColor Cyan

# Create directories
$Dirs = @(
    "config",
    "database/migrations",
    "src/Base",
    "src/Contracts",
    "src/Data",
    "src/Enums",
    "src/Events",
    "src/Exceptions",
    "src/Models",
    "src/Providers",
    "src/Services",
    "tests/Feature",
    "tests/Unit"
)

foreach ($d in $Dirs) {
    $fullPath = Join-Path $TargetDir $d
    if (-not (Test-Path $fullPath)) {
        New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
    }
}

# 1. composer.json
$composerJson = @'
{
    "name": "obelaw/ium-{slug}",
    "description": "Headless business domain logic for Obelawium {module}",
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
            "Obelaw\\Ium\\{module}\\": "src/"
        }
    },
    "autoload-dev": {
        "psr-4": {
            "Obelaw\\Ium\\{module}\\Tests\\": "tests/"
        }
    },
    "extra": {
        "laravel": {
            "providers": [
                "Obelaw\\Ium\\{module}\\Providers\\Obelaw{module}ServiceProvider"
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
'@
$composerJson = $composerJson.Replace('{slug}', $Slug).Replace('{module}', $ModuleName)
Set-Content -Path (Join-Path $TargetDir "composer.json") -Value $composerJson -Encoding UTF8

# 2. phpunit.xml
$phpunitXml = @'
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
'@
Set-Content -Path (Join-Path $TargetDir "phpunit.xml") -Value $phpunitXml -Encoding UTF8

# 3. config/<slug>.php
$configFile = @'
<?php

declare(strict_types=1);

return [
    'table_prefix' => '{slug}_',
    'enabled' => true,
];
'@
$configFile = $configFile.Replace('{slug}', $Slug)
Set-Content -Path (Join-Path $TargetDir "config/$Slug.php") -Value $configFile -Encoding UTF8

# 4. src/Base/ModelBase.php
$modelBase = @'
<?php

declare(strict_types=1);

namespace Obelaw\Ium\{module}\Base;

use Obelaw\Ium\Bases\ModelBase as StackBaseModel;

abstract class ModelBase extends StackBaseModel
{
    /**
     * Module name for table prefixing ('ium_{slug}_').
     */
    protected ?string $module = '{slug}_';
}
'@
$modelBase = $modelBase.Replace('{slug}', $Slug).Replace('{module}', $ModuleName)
Set-Content -Path (Join-Path $TargetDir "src/Base/ModelBase.php") -Value $modelBase -Encoding UTF8

# 5. src/Base/MigrationBase.php
$migrationBase = @'
<?php

declare(strict_types=1);

namespace Obelaw\Ium\{module}\Base;

use Obelaw\Ium\Bases\MigrationBase as StackMigrationBase;

abstract class MigrationBase extends StackMigrationBase
{
    /**
     * Module name for table prefixing ('ium_{slug}_').
     */
    protected ?string $module = '{slug}_';
}
'@
$migrationBase = $migrationBase.Replace('{slug}', $Slug).Replace('{module}', $ModuleName)
Set-Content -Path (Join-Path $TargetDir "src/Base/MigrationBase.php") -Value $migrationBase -Encoding UTF8

# 6. src/<ModuleName>Domain.php
$domainFile = @'
<?php

declare(strict_types=1);

namespace Obelaw\Ium\{module};

use Obelaw\Ium\Abstracts\Domain;
use Obelaw\Ium\Engine\ObelawConfigManager;
use Obelaw\Ium\{module}\Services\{entity}Service;

/**
 * {module} Domain Gateway for Obelawium.
 *
 * Implements the fluent chain: ium()->{slug}()->{plural}()->method()
 */
final class {module}Domain extends Domain
{
    public function __construct(
        ObelawConfigManager $config,
        private readonly ?{module}Manager $manager = null
    ) {
        parent::__construct($config);
    }

    private function getManager(): {module}Manager
    {
        return $this->manager ?? app({module}Manager::class);
    }

    public function {plural}(): {entity}Service
    {
        return $this->getManager()->{plural}();
    }
}
'@
$domainFile = $domainFile.Replace('{slug}', $Slug).Replace('{module}', $ModuleName).Replace('{entity}', $EntityPascal).Replace('{plural}', $EntityPlural)
Set-Content -Path (Join-Path $TargetDir "src/${ModuleName}Domain.php") -Value $domainFile -Encoding UTF8

# 7. src/<ModuleName>Manager.php
$managerFile = @'
<?php

declare(strict_types=1);

namespace Obelaw\Ium\{module};

use Obelaw\Ium\{module}\Services\{entity}Service;

final class {module}Manager
{
    public function {plural}(): {entity}Service
    {
        return app({entity}Service::class);
    }
}
'@
$managerFile = $managerFile.Replace('{module}', $ModuleName).Replace('{entity}', $EntityPascal).Replace('{plural}', $EntityPlural)
Set-Content -Path (Join-Path $TargetDir "src/${ModuleName}Manager.php") -Value $managerFile -Encoding UTF8

# 8. src/Providers/Obelaw<ModuleName>ServiceProvider.php
$providerFile = @'
<?php

declare(strict_types=1);

namespace Obelaw\Ium\{module}\Providers;

use Illuminate\Foundation\Console\AboutCommand;
use Illuminate\Support\ServiceProvider;
use Obelaw\Ium\Engine\ObelawConfigManager;
use Obelaw\Ium\Facades\Ium;
use Obelaw\Ium\{module}\{module}Domain;
use Obelaw\Ium\{module}\{module}Manager;
use Obelaw\Ium\{module}\Services\{entity}Service;

final class Obelaw{module}ServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->mergeConfigFrom(__DIR__ . '/../../config/{slug}.php', 'ium.{slug}');

        $this->app->singleton({module}Manager::class, static fn() => new {module}Manager());
        $this->app->singleton({entity}Service::class);

        // Register domain with central Obelawium gateway
        Ium::registerDomain('{slug}', {module}Domain::class);
    }

    public function boot(): void
    {
        if (ObelawConfigManager::getInstance()->get('obelawium.db.migrations', true)) {
            $this->loadMigrationsFrom(__DIR__ . '/../../database/migrations');
        }

        if ($this->app->runningInConsole()) {
            $this->publishes([
                __DIR__ . '/../../database/migrations' => database_path('migrations'),
            ], 'ium-{slug}-migrations');

            $this->publishes([
                __DIR__ . '/../../config/{slug}.php' => config_path('ium/{slug}.php'),
            ], 'ium-{slug}-config');
        }

        AboutCommand::add('Obelawium', static fn() => ['Obelawium {module}' => '0.1.0']);
    }
}
'@
$providerFile = $providerFile.Replace('{slug}', $Slug).Replace('{module}', $ModuleName).Replace('{entity}', $EntityPascal)
Set-Content -Path (Join-Path $TargetDir "src/Providers/Obelaw${ModuleName}ServiceProvider.php") -Value $providerFile -Encoding UTF8

# 9. src/Data/Create<Entity>Dto.php
$dtoFile = @'
<?php

declare(strict_types=1);

namespace Obelaw\Ium\{module}\Data;

use InvalidArgumentException;

final readonly class Create{entity}Dto
{
    public function __construct(
        public string $name,
        public string $code,
        public ?string $actorId = null,
        public array $metadata = [],
    ) {}

    public static function from(array $data): self
    {
        return new self(
            name: (string) ($data['name'] ?? throw new InvalidArgumentException('Name is required.')),
            code: (string) ($data['code'] ?? throw new InvalidArgumentException('Code is required.')),
            actorId: isset($data['actor_id']) ? (string) $data['actor_id'] : null,
            metadata: (array) ($data['metadata'] ?? []),
        );
    }

    public function toArray(): array
    {
        return [
            'name' => $this->name,
            'code' => $this->code,
            'actor_id' => $this->actorId,
            'metadata' => $this->metadata,
        ];
    }
}
'@
$dtoFile = $dtoFile.Replace('{module}', $ModuleName).Replace('{entity}', $EntityPascal)
Set-Content -Path (Join-Path $TargetDir "src/Data/Create${EntityPascal}Dto.php") -Value $dtoFile -Encoding UTF8

# 10. src/Events/<Entity>Created.php
$eventFile = @'
<?php

declare(strict_types=1);

namespace Obelaw\Ium\{module}\Events;

use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;
use Obelaw\Ium\{module}\Models\{entity};

final class {entity}Created
{
    use Dispatchable, SerializesModels;

    public function __construct(
        public readonly {entity} $entity,
        public readonly ?string $actorId = null,
    ) {}
}
'@
$eventFile = $eventFile.Replace('{module}', $ModuleName).Replace('{entity}', $EntityPascal)
Set-Content -Path (Join-Path $TargetDir "src/Events/${EntityPascal}Created.php") -Value $eventFile -Encoding UTF8

# 11. src/Models/<Entity>.php
$modelFile = @'
<?php

declare(strict_types=1);

namespace Obelaw\Ium\{module}\Models;

use Obelaw\Ium\{module}\Base\ModelBase;

class {entity} extends ModelBase
{
    protected $table = '{plural}';

    protected $fillable = [
        'name',
        'code',
        'status',
        'metadata',
    ];

    protected $casts = [
        'metadata' => 'array',
    ];
}
'@
$modelFile = $modelFile.Replace('{module}', $ModuleName).Replace('{entity}', $EntityPascal).Replace('{plural}', $EntityPlural)
Set-Content -Path (Join-Path $TargetDir "src/Models/${EntityPascal}.php") -Value $modelFile -Encoding UTF8

# 12. src/Services/<Entity>Service.php
$serviceFile = @'
<?php

declare(strict_types=1);

namespace Obelaw\Ium\{module}\Services;

use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Facades\DB;
use Obelaw\Ium\{module}\Data\Create{entity}Dto;
use Obelaw\Ium\{module}\Events\{entity}Created;
use Obelaw\Ium\{module}\Models\{entity};

class {entity}Service
{
    public function create(Create{entity}Dto $dto): {entity}
    {
        return DB::transaction(function () use ($dto): {entity} {
            $entity = {entity}::query()->create([
                'name' => $dto->name,
                'code' => $dto->code,
                'metadata' => $dto->metadata,
            ]);

            event(new {entity}Created($entity, $dto->actorId));

            return $entity;
        });
    }

    public function list(): Collection
    {
        return {entity}::query()->latest()->get();
    }

    public function find(int $id): ?{entity}
    {
        return {entity}::query()->find($id);
    }
}
'@
$serviceFile = $serviceFile.Replace('{module}', $ModuleName).Replace('{entity}', $EntityPascal)
Set-Content -Path (Join-Path $TargetDir "src/Services/${EntityPascal}Service.php") -Value $serviceFile -Encoding UTF8

# 13. database/migrations
$timestamp = (Get-Date).ToString("yyyy_MM_dd_000001")
$migrationFile = @'
<?php

declare(strict_types=1);

use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Obelaw\Ium\{module}\Base\MigrationBase;

return new class extends MigrationBase {
    public function up(): void
    {
        Schema::create($this->prefix . '{plural}', function (Blueprint $table): void {
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
        Schema::dropIfExists($this->prefix . '{plural}');
    }
};
'@
$migrationFile = $migrationFile.Replace('{module}', $ModuleName).Replace('{plural}', $EntityPlural)
Set-Content -Path (Join-Path $TargetDir "database/migrations/${timestamp}_create_${Slug}_${EntityPlural}_table.php") -Value $migrationFile -Encoding UTF8

# 14. tests/Pest.php & tests/TestCase.php & tests/Feature/IumGatewayIntegrationTest.php
$pestFile = @'
<?php

declare(strict_types=1);

use Obelaw\Ium\{module}\Tests\TestCase;

uses(TestCase::class)->in('Feature', 'Unit');
'@
$pestFile = $pestFile.Replace('{module}', $ModuleName)
Set-Content -Path (Join-Path $TargetDir "tests/Pest.php") -Value $pestFile -Encoding UTF8

$testCaseFile = @'
<?php

declare(strict_types=1);

namespace Obelaw\Ium\{module}\Tests;

use Obelaw\Ium\{module}\Providers\Obelaw{module}ServiceProvider;
use Obelaw\Ium\Providers\ObelawiumServiceProvider;
use Orchestra\Testbench\TestCase as Orchestra;

abstract class TestCase extends Orchestra
{
    protected function getPackageProviders($app): array
    {
        return [
            ObelawiumServiceProvider::class,
            Obelaw{module}ServiceProvider::class,
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
'@
$testCaseFile = $testCaseFile.Replace('{module}', $ModuleName)
Set-Content -Path (Join-Path $TargetDir "tests/TestCase.php") -Value $testCaseFile -Encoding UTF8

$featureTestFile = @'
<?php

declare(strict_types=1);

use Obelaw\Ium\{module}\{module}Domain;
use Obelaw\Ium\{module}\Data\Create{entity}Dto;

it('registers the {slug} domain on the ium() gateway', function (): void {
    expect(ium()->hasDomain('{slug}'))->toBeTrue()
        ->and(ium()->{slug}())->toBeInstanceOf({module}Domain::class);
});

it('creates and lists {plural} through the fluent gateway', function (): void {
    $record = ium()->{slug}()->{plural}()->create(Create{entity}Dto::from([
        'name' => 'Sample {entity}',
        'code' => 'SAMPLE-001',
    ]));

    expect($record->code)->toBe('SAMPLE-001')
        ->and(ium()->{slug}()->{plural}()->list())->toHaveCount(1);
});
'@
$featureTestFile = $featureTestFile.Replace('{slug}', $Slug).Replace('{module}', $ModuleName).Replace('{entity}', $EntityPascal).Replace('{plural}', $EntityPlural)
Set-Content -Path (Join-Path $TargetDir "tests/Feature/IumGatewayIntegrationTest.php") -Value $featureTestFile -Encoding UTF8

# 15. README.md
$readmeFile = @'
# Obelawium IUM — {module} Module

Headless business domain logic for Obelawium {module}.

Part of the **Obelawium IUM** enterprise ecosystem.

## Fluent API Usage

```php
// Query
${plural} = ium()->{slug}()->{plural}()->list();

// Mutation
${singular} = ium()->{slug}()->{plural}()->create(
    \Obelaw\Ium\{module}\Data\Create{entity}Dto::from([
        'name' => 'Sample {entity}',
        'code' => 'SAMPLE-001',
    ])
);
```
'@
$readmeFile = $readmeFile.Replace('{slug}', $Slug).Replace('{module}', $ModuleName).Replace('{entity}', $EntityPascal).Replace('{plural}', $EntityPlural).Replace('{singular}', $EntityPascal.ToLower())
Set-Content -Path (Join-Path $TargetDir "README.md") -Value $readmeFile -Encoding UTF8

Write-Host "Scaffolding completed successfully for [obelaw/ium-$Slug] in [$TargetDir]!" -ForegroundColor Green

