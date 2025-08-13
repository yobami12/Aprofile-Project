const $ = (sel) => document.querySelector(sel);

$('#loginForm').addEventListener('submit', async (e) => {
  e.preventDefault();
  const form = new FormData(e.target);
  const body = Object.fromEntries(form.entries());
  const res = await fetch('/api/auth/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body)
  });
  const json = await res.json();
  $('#authResult').textContent = JSON.stringify(json, null, 2);
  localStorage.setItem('token', json.token || '');
});

$('#loadProducts').addEventListener('click', async () => {
  const token = localStorage.getItem('token') || '';
  const res = await fetch('/api/catalog/products', {
    headers: { 'Authorization': `Bearer ${token}` }
  });
  const products = await res.json();
  $('#products').innerHTML = products.map(p => `<li>${p.name} — $${p.price}</li>`).join('');
});
