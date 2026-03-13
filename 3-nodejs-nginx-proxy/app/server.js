const express = require('express');
const path = require('path');
const os = require('os');

const app = express();
const PORT = process.env.PORT || 3000;

// Serve static files
app.use(express.static(path.join(__dirname, 'public')));

// API: Health check / status
app.get('/api/status', (req, res) => {
  res.json({
    status: 'ok',
    message: 'Node.js application is running',
    timestamp: new Date().toISOString(),
    uptime: `${Math.floor(process.uptime())}s`,
  });
});

// API: Server info
app.get('/api/info', (req, res) => {
  res.json({
    server: 'Node.js + Express',
    version: process.version,
    platform: os.platform(),
    hostname: os.hostname(),
    port: PORT,
    proxy: 'Nginx (port 80)',
    environment: process.env.NODE_ENV || 'development',
  });
});

// Catch-all: serve index.html for any unmatched route
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.listen(PORT, () => {
  console.log(`Node.js server running on http://localhost:${PORT}`);
  console.log(`Proxied through Nginx on http://localhost:80`);
});
