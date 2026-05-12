#!/bin/sh
set -e

echo "==> [smart-bike] Preparing Laravel backend..."

if [ ! -s /var/www/html/.env ]; then
    echo "==> [smart-bike] Creating .env from .env.example"
    cp /var/www/html/.env.example /var/www/html/.env
fi

APP_KEY_VALUE=$(grep -E '^APP_KEY=' /var/www/html/.env | sed 's/^APP_KEY=//' | tr -d '"')
if ! APP_KEY_VALUE="$APP_KEY_VALUE" php -r '
    $key = getenv("APP_KEY_VALUE") ?: "";
    if (str_starts_with($key, "base64:")) {
        $decoded = base64_decode(substr($key, 7), true);
        exit($decoded !== false && strlen($decoded) === 32 ? 0 : 1);
    }
    exit(strlen($key) === 32 ? 0 : 1);
'; then
    echo "==> [smart-bike] Generating valid APP_KEY"
    php -r '
        $path = "/var/www/html/.env";
        $contents = file_exists($path) ? file_get_contents($path) : "";
        if (preg_match("/^APP_KEY=.*/m", $contents)) {
            $contents = preg_replace("/^APP_KEY=.*/m", "APP_KEY=", $contents, 1);
        } else {
            $contents .= (str_ends_with($contents, "\n") ? "" : "\n")."APP_KEY=\n";
        }
        file_put_contents($path, $contents);
    '
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
