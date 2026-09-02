'use strict';
require('dotenv').config();
const path = require('path');
const express = require('express');
const session = require('express-session');
const pgSession = require('connect-pg-simple')(session);
const helmet = require('helmet');
const methodOverride = require('method-override');
const { pool } = require('./config/db');
const { exposeUser } = require('./middleware/auth');
const csrfProtection = require('./middleware/csrf');

if (!process.env.DATABASE_URL || !process.env.SESSION_SECRET) {
  console.error('Faltan DATABASE_URL o SESSION_SECRET. Copia .env.example como .env y edítalo.');
  process.exit(1);
}

const app = express();
const basePath = '/' + String(process.env.BASE_PATH || 'library').replace(/^\/+|\/+$/g, '');
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));
if(process.env.NODE_ENV==='production') app.set('trust proxy',1);
app.disable('x-powered-by');
app.use(helmet({ contentSecurityPolicy: { directives: { 'img-src': ["'self'", 'data:'] } } }));
app.use(express.urlencoded({ extended: false, limit: '100kb' }));
app.use(methodOverride('_method'));
app.use(basePath, express.static(path.join(__dirname, 'public'), { maxAge: process.env.NODE_ENV === 'production' ? '1d' : 0 }));
app.use(`${basePath}/uploads`, express.static(path.resolve(process.env.UPLOAD_DIR || 'uploads'), { index: false, maxAge: '1d' }));
app.use(session({
  store: new pgSession({ pool, tableName: 'user_sessions', createTableIfMissing: false }),
  secret: process.env.SESSION_SECRET,
  resave: false,
  saveUninitialized: false,
  cookie: { httpOnly: true, sameSite: 'lax', secure: process.env.COOKIE_SECURE === 'true', path: basePath, maxAge: 8 * 60 * 60 * 1000 }
}));
app.use((req,res,next)=>{
  res.locals.basePath=basePath;
  const redirect=res.redirect.bind(res);
  res.redirect=(statusOrPath,maybePath)=>{
    const status=typeof statusOrPath==='number'?statusOrPath:null;
    let target=status?maybePath:statusOrPath;
    if(typeof target==='string' && target.startsWith('/') && !target.startsWith(basePath)) target=basePath+target;
    return status?redirect(status,target):redirect(target);
  };
  next();
});
app.use(basePath, exposeUser, csrfProtection);
app.use(basePath, require('./routes/auth'));
app.use(basePath, require('./routes/catalog'));
app.use(`${basePath}/admin`, require('./routes/admin'));
app.get('/',(_req,res)=>res.redirect(basePath));

app.use((_req, res) => res.status(404).render('error', { title: 'Página no encontrada', status: 404, message: 'La dirección solicitada no existe.' }));
app.use((error, req, res, _next) => {
  console.error(error);
  if (error.code === 'LIMIT_FILE_SIZE') error.message = `La imagen supera ${process.env.MAX_UPLOAD_MB || 5} MB.`;
  const status = error.status || 500;
  res.status(status).render('error', { title: 'No se pudo completar la operación', status, message: status === 500 ? 'Ocurrió un error interno. Inténtalo nuevamente.' : error.message });
});

const port = Number(process.env.PORT || 3000), host=process.env.HOST || '127.0.0.1';
if (require.main === module) app.listen(port,host,() => console.log(`Librería disponible en http://${host}:${port}${basePath}`));
module.exports = app;
