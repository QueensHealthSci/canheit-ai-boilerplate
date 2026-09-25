<?php
// Add to App\Providers\AppServiceProvider::boot(). Replaces the N+1 and mass-assignment prose
// in the coding standards with checks that throw in local and test, and never in production.

use Illuminate\Database\Eloquent\Model;

public function boot(): void
{
    Model::preventLazyLoading(! $this->app->isProduction());
    Model::preventSilentlyDiscardingAttributes(! $this->app->isProduction());
    Model::preventAccessingMissingAttributes(! $this->app->isProduction());
}
