<?php
header('Content-Type: application/json');

$path = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$method = $_SERVER['REQUEST_METHOD'];

if ($path === '/health') {
  echo json_encode(['status' => 'ok', 'service' => 'auth']);
  exit;
}

function db() {
  static $pdo = null;
  if ($pdo) return $pdo;
  $host = getenv('DB_HOST') ?: 'db';
  $db   = getenv('DB_NAME') ?: 'app';
  $user = getenv('DB_USER') ?: 'app';
  $pass = getenv('DB_PASS') ?: 'app_pw';
  $dsn  = "mysql:host=$host;dbname=$db;charset=utf8mb4";
  $pdo = new PDO($dsn, $user, $pass, [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]);
  return $pdo;
}

function json_input() {
  $raw = file_get_contents('php://input');
  return $raw ? json_decode($raw, true) : [];
}

function make_token($userId) {
  return base64_encode(json_encode(['uid' => $userId, 'ts' => time()]));
}

function verify_token($hdr) {
  if (!$hdr) return null;
  if (!str_starts_with($hdr, 'Bearer ')) return null;
  $payload = base64_decode(substr($hdr, 7));
  $data = json_decode($payload, true);
  return $data && isset($data['uid']) ? $data : null;
}

if ($path === '/login' && $method === 'POST') {
  $in = json_input();
  $u = $in['username'] ?? '';
  $p = $in['password'] ?? '';
  $stmt = db()->prepare('SELECT id, password_hash FROM users WHERE username = ? LIMIT 1');
  $stmt->execute([$u]);
  $row = $stmt->fetch(PDO::FETCH_ASSOC);
  if ($row && password_verify($p, $row['password_hash'])) {
    echo json_encode(['token' => make_token($row['id'])]);
  } else {
    http_response_code(401);
    echo json_encode(['error' => 'invalid_credentials']);
  }
  exit;
}

if ($path === '/me' && $method === 'GET') {
  $auth = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
  $tok = verify_token($auth);
  if (!$tok) { http_response_code(401); echo json_encode(['error' => 'unauthorized']); exit; }
  $stmt = db()->prepare('SELECT id, username FROM users WHERE id = ?');
  $stmt->execute([$tok['uid']]);
  $row = $stmt->fetch(PDO::FETCH_ASSOC);
  echo json_encode($row ?: []);
  exit;
}

http_response_code(404);
echo json_encode(['error' => 'not_found', 'path' => $path]);
