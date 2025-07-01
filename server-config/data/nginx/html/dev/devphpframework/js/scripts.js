// ========================================
// js/scripts.js - Global JavaScript
// ========================================


// CSRF token management
function getCSRFToken() {
    return document.querySelector('meta[name="csrf-token"]').getAttribute('content');
}

// Enhanced form submission with CSRF
function submitFormWithCSRF(form) {
    const formData = new FormData(form);
    formData.append('csrf_token', getCSRFToken());
    
    fetch(form.action, {
        method: 'POST',
        body: formData
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            // Handle success
        } else {
            // Handle error
        }
    })
    .catch(error => {
        console.error('Form submission error:', error);
    });
}

// Client-side password encryption
async function encryptPassword(password) {
    const clientSalt = 'client_salt_key_2025';
    const saltedPassword = clientSalt + password;
    
    const encoder = new TextEncoder();
    const data = encoder.encode(saltedPassword);
    const hashBuffer = await crypto.subtle.digest('SHA-256', data);
    const hashArray = Array.from(new Uint8Array(hashBuffer));
    const hashHex = hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
    
    return hashHex;
}

// Navigation highlighting
document.addEventListener('DOMContentLoaded', function() {
    const currentPage = new URLSearchParams(window.location.search).get('page') || 'home';
    const navLinks = document.querySelectorAll('.main-navigation a');
    
    navLinks.forEach(link => {
        const href = link.getAttribute('href');
        if (href === '?' && currentPage === 'home') {
            link.classList.add('active');
        } else if (href.includes(`page=${currentPage}`)) {
            link.classList.add('active');
        }
    });
});
