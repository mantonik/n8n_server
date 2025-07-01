<?php
session_start();
function is_logged_in() { return isset($_SESSION['user']); }
function require_login() { if (!is_logged_in()) { header("Location: /?page=login"); exit(); } }
function login($u,$p){$h=password_hash('adminpass',PASSWORD_DEFAULT);if($u==='admin'&&password_verify($p,$h)){$_SESSION['user']=['username'=>$u];return true;}return false;}
function logout() { session_destroy(); }