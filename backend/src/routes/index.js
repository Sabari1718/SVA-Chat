const express = require('express');
const router = express.Router();

const appInfoRoute = require('./app_info_route');
const userTokenRoute = require('./user_token_route');

// Mount routes
router.use('/', appInfoRoute);
router.use('/', userTokenRoute);

module.exports = router;
