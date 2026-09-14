/**
 * Service to retrieve basic application information metadata.
 */
const getAppInfo = async () => {
  return {
    app_name: 'VA Chat',
    app_version: '1.0.0',
    software_version: '1.0.0'
  };
};

module.exports = {
  getAppInfo
};
