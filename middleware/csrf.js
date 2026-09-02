'use strict';
const crypto = require('crypto');

function csrfProtection(req, res, next) {
  if (!req.session.csrfToken) req.session.csrfToken = crypto.randomBytes(32).toString('hex');
  res.locals.csrfToken = req.session.csrfToken;
  if (['POST', 'PUT', 'PATCH', 'DELETE'].includes(req.method)) {
    const token = req.body?._csrf || req.query?._csrf || req.get('x-csrf-token');
    const supplied = Buffer.from(String(token || ''));
    const expected = Buffer.from(req.session.csrfToken);
    if (supplied.length !== expected.length || !crypto.timingSafeEqual(supplied, expected)) {
      return res.status(403).render('error', { title: 'Solicitud inválida', status: 403, message: 'El formulario venció o no es válido. Recarga la página e inténtalo de nuevo.' });
    }
  }
  next();
}

module.exports = csrfProtection;
