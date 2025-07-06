const express = require('express');
const serverless = require('serverless-http');
const path = require('path');

const app = express();

// Serve static files from public/admin
app.use(express.static(path.join(__dirname, '../public/admin')));

// Serve admin panel
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, '../public/admin/index.html'));
});

module.exports.handler = serverless(app); 