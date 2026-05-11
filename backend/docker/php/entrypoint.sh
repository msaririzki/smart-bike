#!/bin/sh
set -e

echo "==> [smart-bike] Preparing Laravel backend..."

if [ ! -s /var/www/html/.env ]; then
    echo "==> [smart-bike] Creating .env from .env.example"
    cp /var/www/html/.env.example /var/www/html/.env
fi

APP_KEY_VALUE=$(grep -E '^APP_KEY=' /var/www/html/.env | cut -d '=' -f2)
if [ -z "$APP_KEY_VALUE" ]; then
    echo "==> [smart-bike] Generating APP_KEY"
    php artisan key:generate --force
fi

mkdir -p storage/logs storage/framework/cache storage/framework/sessions storage/framework/views bootstrap/cache

echo "==> [smart-bike] Syncing public assets"
cp -ru /public-init/. /var/www/html/public/

if [ -n "$DB_HOST" ]; then
    echo "==> [smart-bike] Waiting for database at $DB_HOST:${DB_PORT:-3306}"
    php -r "
        \$host = getenv('DB_HOST') ?: '127.0.0.1';
        \$port = getenv('DB_PORT') ?: '3306';
        \$db = getenv('DB_DATABASE') ?: 'smart_bike_rental';
        \$user = getenv('DB_USERNAME') ?: 'root';
        \$pass = getenv('DB_PASSWORD') ?: '';

        for (\$i = 0; \$i < 40; \$i++) {
            try {
                new PDO(\"mysql:host=\$host;port=\$port;dbname=\$db\", \$user, \$pass);
                echo \"==> [smart-bike] Database ready\\n\";
                exit(0);
            } catch (Throwable \$e) {
                sleep(2);
            }
        }

        fwrite(STDERR, \"==> [smart-bike] Database connection timeout\\n\");
        exit(1);
    "
fi

echo "==> [smart-bike] Running migrations"
php artisan migrate --force

if [ "${RUN_SEED_ON_DEPLOY:-false}" = "true" ]; then
    echo "==> [smart-bike] Running database seeder"
    php artisan db:seed --force
fi

if [ ! -e /var/www/html/public/storage ]; then
    echo "==> [smart-bike] Linking storage"
    php artisan storage:link
fi

echo "==> [smart-bike] Optimizing Laravel"
php artisan optimize

echo "==> [smart-bike] Fixing permissions"
chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache /var/www/html/public
chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

echo "==> [smart-bike] Starting: $*"
exec "$@"
