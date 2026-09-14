const express = require('express');
const cors = require('cors');
require('dotenv').config();

const apiRoutes = require('./src/routes');
const errorHandler = require('./src/middleware/error_handler');

const app = express();
const PORT = process.env.PORT || 5000;

// Core Middlewares
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Mount API routes at /api
app.use('/api', apiRoutes);

// 404 Handler for undefined routes
app.use((req, res, next) => {
  res.status(404).json({
    status: false,
    message: `Cannot ${req.method} ${req.originalUrl}`
  });
});

// Global Error Handler
app.use(errorHandler);

// Start server
app.listen(PORT, () => {
  console.log(`========================================`);
  console.log(`🚀 VA Chat Backend Server is running!`);
  console.log(`📡 URL: http://localhost:${PORT}`);
  console.log(`🔗 App Info API: http://localhost:${PORT}/api/app-info`);
  console.log(`========================================`);
});

module.exports = app;
