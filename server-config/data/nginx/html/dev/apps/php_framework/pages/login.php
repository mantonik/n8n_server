<?php
require_once __DIR__ . '/../includes/auth.php';
$error = '';
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (login($_POST['username'] ?? '', $_POST['password'] ?? '')) {
        header('Location: /?page=home'); exit();
    } else { $error = 'Invalid login'; }
}
?>
<h2>Login</h2>
<?php if ($error): ?><p class="error"><?= $error ?></p><?php endif; ?>
<form method="post">
<label>Username:</label><input name="username"><br>
<label>Password:</label><input name="password" type="password"><br>
<button>Login</button>
</form>