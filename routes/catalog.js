'use strict';
const express=require('express');
const catalog=require('../services/catalogService');
const {requireLogin}=require('../middleware/auth');
const router=express.Router();
router.use(requireLogin);
router.get('/',async(req,res,next)=>{try{const q=String(req.query.q||'');res.render('catalog/index',{title:'Catálogo',books:await catalog.listBooks(q),q});}catch(e){next(e);}});
router.get('/books/:id',async(req,res,next)=>{try{const book=await catalog.getBook(req.params.id);if(!book)return res.status(404).render('error',{title:'Libro no encontrado',status:404,message:'No existe el libro solicitado.'});res.render('catalog/detail',{title:book.title,book});}catch(e){next(e);}});
module.exports=router;
