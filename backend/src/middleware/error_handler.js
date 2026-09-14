/**
 * Global Error Handling Middleware
 */
const errorHandler = (err, req, res, next) => {
  console.error('[Error]:', err.stack || err.message || err);

  const statusCode = err.statusCode || 500;
  res.status(statusCode).json({
    status: false,
    message: err.message || 'Internal Server Error'
  });
};

module.exports = errorHandler;
