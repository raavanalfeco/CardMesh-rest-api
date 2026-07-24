// Fail closed, not open: if ALLOWED_ORIGINS is ever missing or empty, this
// must NOT fall back to allowing any origin. Combined with `credentials: true`
// below, an open origin would let any website make authenticated,
// cookie-bearing requests to this API on a victim's behalf.
const allowedOrigins = (process.env.ALLOWED_ORIGINS || '')
  .split(',')
  .map((origin) => origin.trim())
  .filter(Boolean);

export const corsOptions = {
  origin(origin, callback) {
    // Allow same-origin / non-browser requests (no Origin header at all,
    // e.g. curl, server-to-server) to pass through.
    if (!origin) {
      callback(null, true);
      return;
    }

    if (allowedOrigins.includes(origin)) {
      callback(null, true);
      return;
    }

    callback(new Error('Not allowed by CORS'));
  },
  credentials: true,
};
