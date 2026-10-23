<?php
// PHP2Shell Lab — vulnerable configuration for CVE-2026-109618 testing
// Display errors to leak memory addresses (critical for exploit)
ini_set('display_errors', '1');
ini_set('memory_limit', '8M');        // Small limit aids heap spray
ini_set('max_input_vars', '1000');    // Controls array spray size

// Session settings that enable upload progress
ini_set('session.use_cookies', '1');
ini_set('session.use_strict_mode', '0');
ini_set('session.upload_progress.enabled', '1');
ini_set('session.upload_progress.cleanup', '0');  // Keep session data longer

session_start();

echo "<html><body>";
echo "<h2>PHP2Shell Lab — CVE-2026-109618</h2>";
echo "<p>PHP Version: " . phpversion() . "</p>";
echo "<p>Server: " . $_SERVER['SERVER_SOFTWARE'] . "</p>";
echo "<p>Memory Limit: " . ini_get('memory_limit') . "</p>";
echo "<p>display_errors: " . ini_get('display_errors') . "</p>";

// Show PHP info for address leak
phpinfo();

echo "<form method='POST' enctype='multipart/form-data'>";
echo "Upload progress test:<br>";
echo "<input type='hidden' name='PHP_SESSION_UPLOAD_PROGRESS' value='a'/>";
echo "<input type='file' name='file'/>";
echo "<input type='submit' value='Upload'/>";
echo "</form></body></html>";
