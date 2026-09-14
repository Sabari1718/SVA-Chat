const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

const DATA_FILE = path.join(__dirname, '../../data/tokens.json');

// Ensure data folder exists
const ensureDataDir = () => {
  const dir = path.dirname(DATA_FILE);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
  if (!fs.existsSync(DATA_FILE)) {
    fs.writeFileSync(DATA_FILE, JSON.stringify({ users: {}, tokens: [] }, null, 2));
  }
};

const readData = () => {
  ensureDataDir();
  try {
    const raw = fs.readFileSync(DATA_FILE, 'utf8');
    return JSON.parse(raw);
  } catch {
    return { users: {}, tokens: [] };
  }
};

const writeData = (data) => {
  ensureDataDir();
  fs.writeFileSync(DATA_FILE, JSON.stringify(data, null, 2));
};

/**
 * Generate a new User Token upon login
 * - Increments login count for the user
 * - Expires previous active tokens
 * - Generates 64-character uppercase Hex token
 */
const generateUserToken = async ({ user_id, app_id = 'VACHAT-60443', app_name = 'VA Chat' }) => {
  if (!user_id) {
    const err = new Error('user_id is required');
    err.statusCode = 400;
    throw err;
  }

  const db = readData();

  // Track user login count
  const prevCount = db.users[user_id] ? db.users[user_id].login_count : 0;
  const newCount = prevCount + 1;
  db.users[user_id] = {
    user_id,
    login_count: newCount,
    last_login: new Date().toISOString()
  };

  // Expire any existing active token for this user
  db.tokens.forEach((t) => {
    if (t.user_id === user_id && t.status === 'Active') {
      t.status = 'Expired';
      t.expired_at = new Date().toISOString();
    }
  });

  // Generate 64-character uppercase hex token (matching Mobile Admin format)
  const user_token = crypto.randomBytes(32).toString('hex').toUpperCase();

  const tokenRecord = {
    s_no: db.tokens.length + 1,
    user_id: String(user_id),
    app_id: String(app_id),
    app_name: String(app_name),
    login_count: newCount,
    user_token,
    status: 'Active',
    created_at: new Date().toISOString()
  };

  db.tokens.push(tokenRecord);
  writeData(db);

  return tokenRecord;
};

/**
 * Expire User Token on logout
 */
const logoutUserToken = async ({ user_id, user_token }) => {
  if (!user_id) {
    const err = new Error('user_id is required');
    err.statusCode = 400;
    throw err;
  }

  const db = readData();
  let found = false;

  db.tokens.forEach((t) => {
    if (t.user_id === String(user_id) && t.status === 'Active') {
      if (!user_token || t.user_token === user_token) {
        t.status = 'Expired';
        t.expired_at = new Date().toISOString();
        found = true;
      }
    }
  });

  writeData(db);

  return {
    success: true,
    message: found ? 'Token expired successfully' : 'No active token found to expire'
  };
};

/**
 * Get all tokens (for Admin Table / Stream)
 */
const getAllTokens = async ({ app_id, user_id } = {}) => {
  const db = readData();
  let list = db.tokens;

  if (app_id) {
    list = list.filter((t) => t.app_id === app_id);
  }
  if (user_id) {
    list = list.filter((t) => t.user_id === String(user_id));
  }

  return list;
};

/**
 * Get active token for a specific user
 */
const getActiveTokenByUser = async (user_id) => {
  const db = readData();
  const active = db.tokens.slice().reverse().find((t) => t.user_id === String(user_id) && t.status === 'Active');
  const user = db.users[user_id] || { login_count: 0 };

  return {
    user_id,
    login_count: user.login_count,
    active_token: active ? active.user_token : null,
    status: active ? 'Active' : 'No Active Session'
  };
};

module.exports = {
  generateUserToken,
  logoutUserToken,
  getAllTokens,
  getActiveTokenByUser
};
