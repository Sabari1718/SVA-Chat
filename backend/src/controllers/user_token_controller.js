const userTokenService = require('../services/user_token_service');

/**
 * POST /api/user/token/generate
 * Handles user login / token generation with login_count tracking.
 */
const generateTokenHandler = async (req, res, next) => {
  try {
    const { user_id, app_id, app_name } = req.body;

    const tokenData = await userTokenService.generateUserToken({
      user_id,
      app_id,
      app_name
    });

    return res.status(200).json({
      status: true,
      message: 'User token generated successfully',
      data: tokenData
    });
  } catch (error) {
    next(error);
  }
};

/**
 * POST /api/user/token/logout
 * Handles user logout and expires the active token.
 */
const logoutTokenHandler = async (req, res, next) => {
  try {
    const { user_id, user_token } = req.body;

    const result = await userTokenService.logoutUserToken({
      user_id,
      user_token
    });

    return res.status(200).json({
      status: true,
      message: result.message
    });
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/user/tokens
 * Fetches all generated tokens (matching Mobile Admin Auto-Generated User Tokens table).
 */
const getAllTokensHandler = async (req, res, next) => {
  try {
    const { app_id, user_id } = req.query;
    const tokens = await userTokenService.getAllTokens({ app_id, user_id });

    return res.status(200).json({
      status: true,
      count: tokens.length,
      data: tokens
    });
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/user/token/:userId
 * Fetches current active token and login count for a specific user.
 */
const getUserActiveTokenHandler = async (req, res, next) => {
  try {
    const { userId } = req.params;
    const data = await userTokenService.getActiveTokenByUser(userId);

    return res.status(200).json({
      status: true,
      data
    });
  } catch (error) {
    next(error);
  }
};

/**
 * /api/receive-token
 * Handles BOTH GET and POST requests from Admin Portal Target API Endpoint
 */
const receiveTokenHandler = async (req, res, next) => {
  try {
    console.log(`[Target API ${req.method}] Received from Admin Portal:`, req.method === 'POST' ? req.body : req.query);

    return res.status(200).json({
      status: true,
      message: 'Token received successfully',
      method: req.method,
      data: req.method === 'POST' ? (req.body || {}) : {
        app_id: 'VACHAT-60443',
        app_name: 'VA Chat',
        version: '1.0.0'
      }
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  generateTokenHandler,
  logoutTokenHandler,
  getAllTokensHandler,
  getUserActiveTokenHandler,
  receiveTokenHandler
};
