'use strict';
const express = require('express');
const bcrypt = require('bcrypt');
const db = require('../config/db');
const router = express.Router();

router.get('/register', (_req,res)=>res.render('auth/register',{title:'Crear cuenta'}));
router.post('/register', async (req,res,next)=>{
  try {
    const name=String(req.body.name||'').trim(), email=String(req.body.email||'').trim().toLowerCase(), password=String(req.body.password||'');
    if(name.length<2 || !/^\S+@\S+\.\S+$/.test(email) || password.length<8){ req.session.error='Usa un nombre válido, correo válido y contraseña de al menos 8 caracteres.'; return res.redirect('/register'); }
    const hash=await bcrypt.hash(password,12);
    await db.query("INSERT INTO users(name,email,password_hash,role) VALUES($1,$2,$3,'user')",[name,email,hash]);
    req.session.success='Cuenta creada. Ya puedes iniciar sesión.'; res.redirect('/login');
  } catch(error){ if(error.code==='23505'){req.session.error='Ese correo ya está registrado.'; return res.redirect('/register');} next(error); }
});
router.get('/login',(_req,res)=>res.render('auth/login',{title:'Iniciar sesión'}));
router.post('/login',async(req,res,next)=>{
  try{
    const {rows}=await db.query('SELECT id,name,email,password_hash,role FROM users WHERE email=$1 AND active=true',[String(req.body.email||'').trim().toLowerCase()]);
    const user=rows[0];
    if(!user || !await bcrypt.compare(String(req.body.password||''),user.password_hash)){req.session.error='Correo o contraseña incorrectos.';return res.redirect('/login');}
    req.session.regenerate(error=>{if(error)return next(error);req.session.user={id:user.id,name:user.name,email:user.email,role:user.role};req.session.success=`Bienvenido, ${user.name}.`;res.redirect(user.role==='admin'?'/admin':'/');});
  }catch(error){next(error);}
});
router.post('/logout',(req,res,next)=>req.session.destroy(error=>error?next(error):res.redirect('/')));
module.exports=router;
