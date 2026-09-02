'use strict';
const path = require('path');
const crypto = require('crypto');
const multer = require('multer');

const uploadDir = path.resolve(process.env.UPLOAD_DIR || 'uploads');
const allowed = new Map([['image/jpeg', '.jpg'], ['image/png', '.png'], ['image/webp', '.webp']]);
const storage = multer.diskStorage({
  destination: (_req, _file, cb) => cb(null, uploadDir),
  filename: (_req, file, cb) => cb(null, `${Date.now()}-${crypto.randomUUID()}${allowed.get(file.mimetype) || ''}`)
});

module.exports = multer({
  storage,
  limits: { fileSize: Number(process.env.MAX_UPLOAD_MB || 5) * 1024 * 1024 },
  fileFilter: (_req, file, cb) => allowed.has(file.mimetype) ? cb(null, true) : cb(new Error('Sólo se permiten imágenes JPG, PNG o WebP.'))
});
