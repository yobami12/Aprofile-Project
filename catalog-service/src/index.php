<?php
header('Content-Type: application/json');

$path = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$method = $_SERVER['REQUEST_METHOD'];

if ($path === '/health') { echo json_encode(['status' => 'ok', 'service' => 'catalog']); exit; }

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

function auth_uid() {
  $hdr = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
  if (!str_starts_with($hdr, 'Bearer ')) return null;
  $payload = base64_decode(substr($hdr, 7));
  $data = json_decode($payload, true);
  return $data['uid'] ?? null;
}

if ($path === '/products' && $method === 'GET') {
  $uid = auth_uid();
  if (!$uid) { http_response_code(401); echo json_encode(['error' => 'unauthorized']); exit; }
  $rows = db()->query('SELECT id, name, price FROM products ORDER BY id DESC')->fetchAll(PDO::FETCH_ASSOC);
  echo json_encode($rows);
  exit;
}

if ($path === '/products' && $method === 'POST') {
  $uid = auth_uid();
  if (!$uid) { http_response_code(401); echo json_encode(['error' => 'unauthorized']); exit; }
  $data = json_decode(file_get_contents('php://input'), true) ?: [];
  $name = $data['name'] ?? '';
  $price = (float)($data['price'] ?? 0);
  $stmt = db()->prepare('INSERT INTO products(name, price) VALUES(?, ?)');
  $stmt->execute([$name, $price]);
  echo json_encode(['ok' => true, 'id' => db()->la
