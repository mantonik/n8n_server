<?php
// manage_modals.php - All modal dialogs for management interface
?>

<!-- Add URL Modal (Admin Only) -->
<?php if ($canModify): ?>
<div class="modal fade" id="addUrlModal" tabindex="-1">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title">Add New URL</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <form method="POST">
                <input type="hidden" name="csrf_token" value="<?php echo generateCSRFToken(); ?>">
                <input type="hidden" name="action" value="add_url">
                <div class="modal-body">
                    <div class="row">
                        <div class="col-md-6 mb-3">
                            <label class="form-label">URL</label>
                            <input type="url" class="form-control" name="url" required>
                        </div>
                        <div class="col-md-6 mb-3">
                            <label class="form-label">Name</label>
                            <input type="text" class="form-control" name="name" required>
                        </div>
                        <div class="col-12 mb-3">
                            <label class="form-label">Description</label>
                            <textarea class="form-control" name="description" rows="2"></textarea>
                        </div>
                        <div class="col-md-4 mb-3">
                            <label class="form-label">Priority</label>
                            <select class="form-select" name="priority" required>
                                <option value="critical">Critical</option>
                                <option value="high">High</option>
                                <option value="normal" selected>Normal</option>
                                <option value="low">Low</option>
                            </select>
                        </div>
                        <div class="col-md-4 mb-3">
                            <label class="form-label">Team</label>
                            <input type="text" class="form-control" name="team_name" list="teamList">
                            <datalist id="teamList">
                                <?php foreach ($teams as $team): ?>
                                    <option value="<?php echo htmlspecialchars($team['team_name']); ?>">
                                <?php endforeach; ?>
                            </datalist>
                        </div>
                        <div class="col-md-4 mb-3">
                            <label class="form-label">Tags</label>
                            <input type="text" class="form-control" name="tags" placeholder="production, api, critical">
                            <div class="form-text">Comma-separated tags for grouping</div>
                        </div>
                        <div class="col-md-6 mb-3">
                            <label class="form-label">Alert Definition</label>
                            <select class="form-select" name="alert_definition_id">
                                <option value="">None</option>
                                <?php foreach ($alertDefinitions as $def): ?>
                                    <option value="<?php echo $def['id']; ?>">
                                        <?php echo htmlspecialchars($def['alert_name']); ?>
                                    </option>
                                <?php endforeach; ?>
                            </select>
                        </div>
                        <div class="col-md-6 mb-3">
                            <label class="form-label">Check Interval (minutes)</label>
                            <input type="number" class="form-control" name="check_interval_minutes" value="5" min="1" required>
                        </div>
                        <div class="col-md-6 mb-3">
                            <label class="form-label">Timeout (seconds)</label>
                            <input type="number" class="form-control" name="timeout_seconds" value="30" min="1" required>
                        </div>
                        <div class="col-md-6 mb-3">
                            <label class="form-label">Failure Threshold</label>
                            <input type="number" class="form-control" name="failure_threshold" value="5" min="1" required>
                        </div>
                        <div class="col-12 mb-3">
                            <label class="form-label">Expected Response Text</label>
                            <input type="text" class="form-control" name="expected_response" placeholder="Optional text to look for in response">
                        </div>
                        <div class="col-md-6 mb-3">
                            <label class="form-label">Warning Response Time (ms)</label>
                            <input type="number" class="form-control" name="response_time_warning_ms" value="5000">
                        </div>
                        <div class="col-md-6 mb-3">
                            <label class="form-label">Critical Response Time (ms)</label>
                            <input type="number" class="form-control" name="response_time_critical_ms" value="10000">
                        </div>
                        <div class="col-md-6 mb-3">
                            <div class="form-check">
                                <input class="form-check-input" type="checkbox" name="check_ssl_expiry" id="check_ssl_expiry">
                                <label class="form-check-label" for="check_ssl_expiry">
                                    Monitor SSL Certificate
                                </label>
                            </div>
                        </div>
                        <div class="col-md-6 mb-3">
                            <label class="form-label">SSL Warning Days</label>
                            <input type="number" class="form-control" name="ssl_days_warning" value="30">
                        </div>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                    <button type="submit" class="btn btn-primary">Add URL</button>
                </div>
            </form>
        </div>
    </div>
</div>

<!-- Edit URL Modal -->
<div class="modal fade" id="editUrlModal" tabindex="-1">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title">Edit URL</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <form method="POST" id="editUrlForm">
                <input type="hidden" name="csrf_token" value="<?php echo generateCSRFToken(); ?>">
                <input type="hidden" name="action" value="update_url">
                <input type="hidden" name="url_id" id="edit_url_id">
                <div class="modal-body" id="editUrlBody">
                    <!-- Content populated by JavaScript -->
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                    <button type="submit" class="btn btn-primary">Update URL</button>
                </div>
            </form>
        </div>
    </div>
</div>

<!-- Add Alert Definition Modal -->
<div class="modal fade" id="addAlertDefinitionModal" tabindex="-1">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title">Add Alert Definition</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <form method="POST">
                <input type="hidden" name="csrf_token" value="<?php echo generateCSRFToken(); ?>">
                <input type="hidden" name="action" value="add_alert_definition">
                <div class="modal-body">
                    <div class="mb-3">
                        <label class="form-label">Alert Name</label>
                        <input type="text" class="form-control" name="alert_name" required>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Description</label>
                        <textarea class="form-control" name="description" rows="3"></textarea>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Cooldown (minutes)</label>
                        <input type="number" class="form-control" name="cooldown_minutes" value="60" min="1" required>
                    </div>
                    <div class="mb-3">
                        <div class="form-check">
                            <input class="form-check-input" type="checkbox" name="escalation_enabled" id="escalation_enabled">
                            <label class="form-check-label" for="escalation_enabled">
                                Enable Escalation
                            </label>
                        </div>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Escalation Delay (minutes)</label>
                        <input type="number" class="form-control" name="escalation_delay_minutes" value="30">
                    </div>
                    <div class="mb-3">
                        <div class="form-check">
                            <input class="form-check-input" type="checkbox" name="business_hours_only" id="business_hours_only">
                            <label class="form-check-label" for="business_hours_only">
                                Business Hours Only
                            </label>
                        </div>
                    </div>
                    <div class="row">
                        <div class="col-md-4 mb-3">
                            <label class="form-label">Timezone</label>
                            <input type="text" class="form-control" name="timezone" value="UTC">
                        </div>
                        <div class="col-md-4 mb-3">
                            <label class="form-label">Start Hour</label>
                            <input type="number" class="form-control" name="business_start_hour" value="9" min="0" max="23">
                        </div>
                        <div class="col-md-4 mb-3">
                            <label class="form-label">End Hour</label>
                            <input type="number" class="form-control" name="business_end_hour" value="17" min="0" max="23">
                        </div>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                    <button type="submit" class="btn btn-primary">Add Definition</button>
                </div>
            </form>
        </div>
    </div>
</div>

<!-- Add Contact Modal -->
<div class="modal fade" id="addContactModal" tabindex="-1">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title">Add Alert Contact</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <form method="POST">
                <input type="hidden" name="csrf_token" value="<?php echo generateCSRFToken(); ?>">
                <input type="hidden" name="action" value="add_alert_contact">
                <div class="modal-body">
                    <div class="mb-3">
                        <label class="form-label">Alert Definition</label>
                        <select class="form-select" name="alert_definition_id" required>
                            <option value="">Select Alert Definition</option>
                            <?php foreach ($alertDefinitions as $def): ?>
                                <option value="<?php echo $def['id']; ?>">
                                    <?php echo htmlspecialchars($def['alert_name']); ?>
                                </option>
                            <?php endforeach; ?>
                        </select>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Contact Name</label>
                        <input type="text" class="form-control" name="contact_name" required>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Email Address</label>
                        <input type="email" class="form-control" name="contact_email" required>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Phone Number</label>
                        <input type="tel" class="form-control" name="contact_phone">
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Notification Type</label>
                        <select class="form-select" name="notification_type" required>
                            <option value="email">Email</option>
                            <option value="sms">SMS</option>
                            <option value="webhook">Webhook</option>
                            <option value="slack">Slack</option>
                            <option value="teams">Teams</option>
                        </select>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Priority Order</label>
                        <input type="number" class="form-control" name="priority_order" value="1" min="1" required>
                        <div class="form-text">1 = Primary contact, 2 = Secondary, etc.</div>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                    <button type="submit" class="btn btn-primary">Add Contact</button>
                </div>
            </form>
        </div>
    </div>
</div>

<!-- Delete Confirmation Modal -->
<div class="modal fade" id="deleteModal" tabindex="-1">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title">Confirm Deletion</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body">
                <p>Are you sure you want to delete <strong id="deleteItemName"></strong>?</p>
                <p class="text-muted">This action cannot be undone.</p>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                <form method="POST" id="deleteForm" style="display: inline;">
                    <input type="hidden" name="csrf_token" value="<?php echo generateCSRFToken(); ?>">
                    <input type="hidden" name="action" value="delete_url">
                    <input type="hidden" name="url_id" id="deleteUrlId">
                    <button type="submit" class="btn btn-danger">Delete</button>
                </form>
            </div>
        </div>
    </div>
</div>
<?php endif; ?>

<!-- View URL Modal (Read-Only) -->
<div class="modal fade" id="viewUrlModal" tabindex="-1">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title">View URL Details</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body" id="viewUrlBody">
                <!-- Content populated by JavaScript -->
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
            </div>
        </div>
    </div>
</div>