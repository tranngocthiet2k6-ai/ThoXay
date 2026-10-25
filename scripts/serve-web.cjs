const http = require('node:http');
const fs = require('node:fs');
const path = require('node:path');

const root = path.resolve(process.argv[2] || 'mobile_app/build/web');
const port = Number(process.argv[3] || 3000);
const contentTypes = {
  '.html': 'text/html; charset=utf-8', '.js': 'text/javascript',
  '.json': 'application/json', '.wasm': 'application/wasm',
  '.css': 'text/css', '.png': 'image/png', '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon', '.ttf': 'font/ttf', '.otf': 'font/otf',
};

const server = http.createServer((request, response) => {
  let file;
  try {
    const pathname = decodeURIComponent(new URL(request.url, 'http://localhost').pathname);
    file = path.resolve(root, '.' + pathname);
  } catch {
    response.writeHead(400); response.end('Invalid URL'); return;
  }
  if (file !== root && !file.startsWith(root + path.sep)) {
    response.writeHead(403); response.end('Forbidden'); return;
  }
  fs.stat(file, (error, info) => {
    if (error) { response.writeHead(404); response.end('Not found'); return; }
    if (info.isDirectory()) file = path.join(file, 'index.html');
    const stream = fs.createReadStream(file);
    stream.once('error', () => {
      if (!response.headersSent) response.writeHead(404);
      response.end('Not found');
    });
    stream.once('open', () => {
      response.writeHead(200, {
        'Content-Type': contentTypes[path.extname(file)] || 'application/octet-stream',
        'Cache-Control': 'no-cache',
      });
      stream.pipe(response);
    });
  });
});
server.on('error', error => { console.error(error.message); process.exit(1); });
server.listen(port, '127.0.0.1', () => console.log(`Flutter Web: http://localhost:${port}`));
