// manage.js - Complete JavaScript for management interface

document.addEventListener('DOMContentLoaded', function() {
    initBulkActions();
    initModalHandlers();
    initFormValidation();
    initKeyboardShortcuts();
});

// Bulk Actions
function initBulkActions() {
    const selectAll = document.getElementById('selectAll');
    const checkboxes = document.querySelectorAll('.url-checkbox');
    
    if (selectAll) {
        selectAll.addEventListener('change', function() {
            checkboxes.forEach(cb => cb.checked = this.checked);
        });
    }
}

// Global function for bulk confirmation
function confirmBulkAction() {
    const selected = document.querySelectorAll('.url-checkbox:checked');
    const action = document.querySelector('select[name="bulk_action"]').value;
    
    if (selected.length === 0) {
        alert('Please select at least one URL');
        return false;
    }
    
    if (!action) {
        alert('Please select an action');
        return false;
    }
    
    return confirm(`Are you sure you want to ${action} ${selected.length} selected URLs?`);
}

// Modal Handlers
function initModalHandlers() {
    // Edit buttons
    document.querySelectorAll('.edit-url-btn').forEach(button => {
        button.addEventListener('click', function() {
            const url = JSON.parse(this.getAttribute('data-url'));
            showEditModal(url);
        });
    });
    
    // View buttons  
    document.querySelectorAll('.view-url-btn').forEach(button => {
        button.addEventListener('click', function() {
            const url = JSON.parse(this.getAttribute('data-url'));
            showViewModal(url);
        });
    });
    
    // Delete buttons
    document.querySelectorAll('.delete-url-btn').forEach(button => {
        button.addEventListener('click', function() {
            const id = this.getAttribute('data-id');
            const name = this.getAttribute('data-name');
            showDeleteModal(id, name);
        });
    });
}

// Show Edit Modal
function showEditModal(url) {
    document.getElementById('edit_url_id').value = url.id;
    
    const body = document.getElementById('editUrlBody');
    body.innerHTML = `
        <div class="row">
            <div class="col-md-6 mb-3">
                <label class="form-label">URL</label>
                <input type="url" class="form-control" name="url" value="${escapeHtml(url.url)}" required>
            </div>
            <div class="col-md-6 mb-3">
                <label class="form-label">Name</label>
                <input type="text" class="form-control" name="name" value="${escapeHtml(url.name)}" required>
            </div>
            <div class="col-12 mb-3">
                <label class="form-label">Description</label>
                <textarea class="form-control" name="description" rows="2">${escapeHtml(url.description || '')}</textarea>
            </div>
            <div class="col-md-4 mb-3">
                <label class="form-label">Priority</label>
                <select class="form-select" name="priority" required>
                    <option value="critical" ${url.priority === 'critical' ? 'selected' : ''}>Critical</option>
                    <option value="high" ${url.priority === 'high' ? 'selected' : ''}>High</option>
                    <option value="normal" ${url.priority === 'normal' ? 'selected' : ''}>Normal</option>
                    <option value="low" ${url.priority === 'low' ? 'selected' : ''}>Low</option>
                </select>
            </div>
            <div class="col-md-4 mb-3">
                <label class="form-label">Team</label>
                <input type="text" class="form-control" name="team_name" value="${escapeHtml(url.team_name || '')}">
            </div>
            <div class="col-md-4 mb-3">
                <label class="form-label">Tags</label>
                <input type="text" class="form-control" name="tags" value="${escapeHtml(url.tags || '')}" placeholder="production, api, critical">
            </div>
            <div class="col-md-6 mb-3">
                <label class="form-label">Check Interval (minutes)</label>
                <input type="number" class="form-control" name="check_interval_minutes" value="${url.check_interval_minutes}" min="1" required>
            </div>
            <div class="col-md-6 mb-3">
                <label class="form-label">Timeout (seconds)</label>
                <input type="number" class="form-control" name="timeout_seconds" value="${url.timeout_seconds}" min="1" required>
            </div>
            <div class="col-md-6 mb-3">
                <label class="form-label">Failure Threshold</label>
                <input type="number" class="form-control" name="failure_threshold" value="${url.failure_threshold}" min="1" required>
            </div>
            <div class="col-md-6 mb-3">
                <div class="form-check">
                    <input class="form-check-input" type="checkbox" name="is_active" id="edit_is_active" ${url.is_active ? 'checked' : ''}>
                    <label class="form-check-label" for="edit_is_active">Active</label>
                </div>
            </div>
        </div>
    `;
    
    new bootstrap.Modal(document.getElementById('editUrlModal')).show();
}

// Show View Modal
function showViewModal(url) {
    const body = document.getElementById('viewUrlBody');
    body.innerHTML = `
        <div class="row">
            <div class="col-md-6 mb-3">
                <strong>URL:</strong><br>
                <a href="${url.url}" target="_blank">${escapeHtml(url.url)} <i class="fas fa-external-link-alt"></i></a>
            </div>
            <div class="col-md-6 mb-3">
                <strong>Name:</strong><br>
                ${escapeHtml(url.name)}
            </div>
            <div class="col-12 mb-3">
                <strong>Description:</strong><br>
                ${escapeHtml(url.description || 'No description')}
            </div>
            <div class="col-md-4 mb-3">
                <strong>Priority:</strong><br>
                <span class="priority-badge bg-${getPriorityClass(url.priority)}">${url.priority.toUpperCase()}</span>
            </div>
            <div class="col-md-4 mb-3">
                <strong>Team:</strong><br>
                ${escapeHtml(url.team_name || 'No team assigned')}
            </div>
            <div class="col-md-4 mb-3">
                <strong>Tags:</strong><br>
                ${escapeHtml(url.tags || 'No tags')}
            </div>
        </div>
    `;
    
    new bootstrap.Modal(document.getElementById('viewUrlModal')).show();
}

// Show Delete Modal
function showDeleteModal(urlId, urlName) {
    document.getElementById('deleteUrlId').value = urlId;
    document.getElementById('deleteItemName').textContent = urlName;
    new bootstrap.Modal(document.getElementById('deleteModal')).show();
}

// Form Validation
function initFormValidation() {
    document.querySelectorAll('form').forEach(form => {
        form.addEventListener('submit', function(e) {
            const requiredFields = this.querySelectorAll('[required]');
            let isValid = true;
            
            requiredFields.forEach(field => {
                if (!field.value.trim()) {
                    field.classList.add('is-invalid');
                    isValid = false;
                } else {
                    field.classList.remove('is-invalid');
                }
            });
            
            if (!isValid) {
                e.preventDefault();
                alert('Please fill in all required fields.');
            }
        });
    });
}

// Keyboard Shortcuts
function initKeyboardShortcuts() {
    document.addEventListener('keydown', function(e) {
        // Ctrl/Cmd + F to focus search
        if ((e.ctrlKey || e.metaKey) && e.key === 'f') {
            e.preventDefault();
            const searchInput = document.querySelector('input[name="search"]');
            if (searchInput) {
                searchInput.focus();
                searchInput.select();
            }
        }
    });
}

// Helper Functions
function escapeHtml(text) {
    if (text == null) return '';
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

function getPriorityClass(priority) {
    const classes = { critical: 'danger', high: 'warning', normal: 'info', low: 'secondary' };
    return classes[priority] || 'secondary';
}

function getStatusClass(status) {
    const classes = { up: 'success', down: 'danger', error: 'warning', timeout: 'warning' };
    return classes[status] || 'secondary';
}

// Auto-focus first field in modals
document.querySelectorAll('.modal').forEach(modal => {
    modal.addEventListener('shown.bs.modal', function() {
        const firstInput = this.querySelector('input:not([type="hidden"]), select, textarea');
        if (firstInput) {
            firstInput.focus();
        }
    });
});

console.log('Management JavaScript loaded successfully');