'use strict';

function exposeUser(req, res, next) {
  res.locals.currentUser = req.session.user || null;
  res.locals.success = req.session.success || null;
  res.locals.error = req.session.error || null;
  delete req.session.success;
  delete req.session.error;
  next();
}

function requireLogin(req, res, next) {
  if (!req.session.user) {
    req.session.error = 'Inicia sesión para continuar.';
    return res.redirect('/login');
  }
  next();
}

function requireAdmin(req, res, next) {
  if (!req.session.user || req.session.user.role !== 'admin') {
    return res.status(403).render('error', { title: 'Acceso denegado', status: 403, message: 'Esta sección requiere permisos de administrador.' });
  }
  next();
}

module.exports = { exposeUser, requireLogin, requireAdmin };
