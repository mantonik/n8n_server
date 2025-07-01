<?php
function log_error($msg) {
    if (DEBUG && defined('LOG_PATH')) {
        error_log("[" . date('Y-m-d H:i:s') . "] $msg\n", 3, LOG_PATH);
    }
}