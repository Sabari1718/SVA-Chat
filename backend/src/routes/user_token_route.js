const express = require('express');
const router = express.Router();
const {
  generateTokenHandler,
  logoutTokenHandler,
  getAllTokensHandler,
  getUserActiveTokenHandler,
  receiveTokenHandler
} = require('../controllers/user_token_controller');

/**
 * @route   GET & POST /api/receive-token
 * @desc    Target API Endpoint for Admin Portal (supports both GET and POST)
 * @access  Public
 */
router.route('/receive-token')
  .get(receiveTokenHandler)
  .post(receiveTokenHandler);

/**
 * @route   POST /api/user/token/generate
 * @desc    Generate User Token on login (increments login_count, returns active token)
 * @access  Public
 */
router.post('/user/token/generate', generateTokenHandler);

/**
 * @route   POST /api/user/token/logout
 * @desc    Expire user token on logout
 * @access  Public
 */
router.post('/user/token/logout', logoutTokenHandler);

/**
 * @route   GET /api/user/tokens
 * @desc    Get all user tokens (Auto-Generated User Tokens table)
 * @access  Public
 */
router.get('/user/tokens', getAllTokensHandler);

/**
 * @route   GET /api/user/token/:userId
 * @desc    Get active token and login count for a user
 * @access  Public
 */
router.get('/user/token/:userId', getUserActiveTokenHandler);

module.exports = router;
