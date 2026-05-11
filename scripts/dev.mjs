import { spawn } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import readline from 'node:readline';
import { fileURLToPath } from 'node:url';

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptDir, '..');
const apiBaseUrl = process.env.API_BASE_URL ?? 'http://127.0.0.1:8000/api';

const processes = [];
const watchers = [];

function run({ name, cwd, command, args, color }) {
  const child = spawn(command, args, {
    cwd: path.join(root, cwd),
    shell: true,
    stdio: ['pipe', 'pipe', 'pipe'],
    env: { ...process.env, FORCE_COLOR: '1' },
  });

  processes.push(child);
  prefix(child.stdout, name, color);
  prefix(child.stderr, name, color);

  child.on('exit', (code, signal) => {
    if (signal) {
      log(name, `stopped by ${signal}`, color);
      return;
    }
    log(name, `exited with code ${code}`, color);
  });

  return child;
}

function prefix(stream, name, color) {
  const lines = readline.createInterface({ input: stream });
  lines.on('line', (line) => log(name, line, color));
}

function log(name, message, color = '\x1b[37m') {
  const reset = '\x1b[0m';
  process.stdout.write(`${color}[${name}]${reset} ${message}\n`);
}

function watchFlutter(name, child, relativeDir) {
  const watched = path.join(root, relativeDir, 'lib');
  if (!fs.existsSync(watched)) {
    log(name, `watch skipped, missing ${watched}`, '\x1b[33m');
    return;
  }

  let timer;
  const watcher = fs.watch(watched, { recursive: true }, (_event, file) => {
    if (!file || !file.endsWith('.dart')) {
      return;
    }

    clearTimeout(timer);
    timer = setTimeout(() => {
      if (!child.killed && child.stdin.writable) {
        log(name, `hot reload: ${file}`, '\x1b[36m');
        child.stdin.write('r\n');
      }
    }, 350);
  });

  watchers.push(watcher);
}

function shutdown() {
  for (const watcher of watchers) {
    watcher.close();
  }

  for (const child of processes) {
    if (!child.killed) {
      child.kill('SIGINT');
    }
  }
}

process.on('SIGINT', () => {
  process.stdout.write('\nStopping dev processes...\n');
  shutdown();
  setTimeout(() => process.exit(0), 500);
});

process.on('SIGTERM', () => {
  shutdown();
  process.exit(0);
});

log('dev', `API_BASE_URL=${apiBaseUrl}`, '\x1b[35m');

run({
  name: 'backend',
  cwd: 'backend',
  command: 'php',
  args: ['artisan', 'serve', '--host=0.0.0.0', '--port=8000'],
  color: '\x1b[32m',
});

const userApp = run({
  name: 'user',
  cwd: 'mobile_user',
  command: 'flutter',
  args: [
    'run',
    '-d',
    'chrome',
    '--web-port=58770',
    `--dart-define=API_BASE_URL=${apiBaseUrl}`,
  ],
  color: '\x1b[34m',
});

const bikeApp = run({
  name: 'bike',
  cwd: 'mobile_bike',
  command: 'flutter',
  args: [
    'run',
    '-d',
    'chrome',
    '--web-port=58771',
    `--dart-define=API_BASE_URL=${apiBaseUrl}`,
  ],
  color: '\x1b[33m',
});

watchFlutter('user', userApp, 'mobile_user');
watchFlutter('bike', bikeApp, 'mobile_bike');

log('dev', 'User app: http://localhost:58770', '\x1b[35m');
log('dev', 'Bike app: http://localhost:58771', '\x1b[35m');
