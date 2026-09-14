const appInfoService = require('../services/app_info_service');

/**
 * Controller to handle GET /api/app-info
 * Returns application information metadata.
 */
const getAppInfoHandler = async (req, res, next) => {
  try {
    const data = await appInfoService.getAppInfo();

    return res.status(200).json({
      status: true,
      data
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getAppInfoHandler
};
