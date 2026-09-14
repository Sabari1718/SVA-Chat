const express = require('express');
const router = express.Router();
const { getAppInfoHandler } = require('../controllers/app_info_controller');

/**
 * @route   GET /api/app-info
 * @desc    Get basic application information
 * @access  Public
 */
router.get('/app-info', getAppInfoHandler);

module.exports = router;
