// NEW FILE — Admin API Client
// Handles all HTTP requests to the backend with auth, retry, and error handling

const AdminAPI = (() => {
    const BASE_URL = window.location.origin;
    let authToken = localStorage.getItem('admin_token') || '';

    // ============================================================
    // CONFIG
    // ============================================================

    function setToken(token) {
        authToken = token;
        localStorage.setItem('admin_token', token);
    }

    function getToken() {
        return authToken;
    }

    function clearToken() {
        authToken = '';
        localStorage.removeItem('admin_token');
    }

    // ============================================================
    // HTTP METHODS
    // ============================================================

    async function request(endpoint, options = {}, retries = 3) {
        const url = `${BASE_URL}${endpoint}`;
        const config = {
            headers: {
                'Content-Type': 'application/json',
                ...(authToken ? { 'Authorization': `Bearer ${authToken}` } : {}),
                ...options.headers,
            },
            ...options,
        };

        for (let attempt = 0; attempt <= retries; attempt++) {
            try {
                const response = await fetch(url, config);

                if (response.status === 401) {
                    clearToken();
                    showToast('Session expired. Please log in again.', 'error');
                    return null;
                }

                const data = await response.json();

                if (!response.ok) {
                    throw new Error(data.error || `HTTP ${response.status}`);
                }

                return data;
            } catch (error) {
                if (attempt < retries) {
                    const delay = Math.min(500 * Math.pow(2, attempt), 5000);
                    console.warn(`Retry ${attempt + 1}/${retries} for ${endpoint}: ${error.message}`);
                    await new Promise(r => setTimeout(r, delay));
                } else {
                    console.error(`Request failed: ${endpoint}`, error);
                    throw error;
                }
            }
        }
    }

    async function get(endpoint) {
        return request(endpoint, { method: 'GET' });
    }

    async function post(endpoint, body) {
        return request(endpoint, {
            method: 'POST',
            body: JSON.stringify(body),
        });
    }

    async function put(endpoint, body) {
        return request(endpoint, {
            method: 'PUT',
            body: JSON.stringify(body),
        });
    }

    // ============================================================
    // API METHODS
    // ============================================================

    // Auth
    async function login(idToken) {
        const data = await post('/auth/login', {
            id_token: idToken,
            role: 'admin'
        });
        if (data && data.success) {
            setToken(idToken);
        }
        return data;
    }

    // Dashboard
    async function getDashboard() {
        return get('/admin_api/dashboard');
    }

    async function getAnalytics() {
        return get('/admin_api/analytics');
    }

    async function getOverview() {
        return get('/admin_api/overview');
    }

    // Reports
    async function getReports(filters = {}) {
        const params = new URLSearchParams();
        if (filters.status) params.append('status', filters.status);
        if (filters.category) params.append('category', filters.category);
        if (filters.limit) params.append('limit', filters.limit);
        if (filters.offset) params.append('offset', filters.offset);
        const query = params.toString();
        return get(`/admin_api/reports${query ? '?' + query : ''}`);
    }

    async function getReport(reportId) {
        return get(`/reports/${reportId}`);
    }

    async function assignWorker(reportId, workerId) {
        return post('/assign', { report_id: reportId, worker_id: workerId });
    }

    // Workers
    async function getWorkers() {
        return get('/admin_api/workers');
    }

    async function createWorker(workerData) {
        return post('/admin_api/workers', workerData);
    }

    async function getWorkerAttendance(workerId) {
        return get(`/admin_api/workers/${workerId}/attendance`);
    }

    // Support
    async function getTickets(status = '') {
        const query = status ? `?status=${status}` : '';
        return get(`/support/tickets${query}`);
    }

    async function respondToTicket(ticketId, response) {
        return put(`/support/tickets/${ticketId}/respond`, { response });
    }

    // ============================================================
    // TOAST NOTIFICATION
    // ============================================================

    function showToast(message, type = 'info') {
        const existing = document.querySelector('.toast');
        if (existing) existing.remove();

        const toast = document.createElement('div');
        toast.className = `toast toast-${type}`;
        toast.innerHTML = `
            <i class="fas fa-${type === 'success' ? 'check-circle' : type === 'error' ? 'exclamation-circle' : 'info-circle'}"></i>
            <span>${message}</span>
        `;

        // Add toast styles if not present
        if (!document.querySelector('#toast-styles')) {
            const style = document.createElement('style');
            style.id = 'toast-styles';
            style.textContent = `
                .toast {
                    position: fixed;
                    bottom: 24px;
                    right: 24px;
                    display: flex;
                    align-items: center;
                    gap: 10px;
                    padding: 14px 22px;
                    border-radius: 10px;
                    font-size: 0.85rem;
                    font-weight: 500;
                    z-index: 999;
                    animation: toastIn 0.4s ease, toastOut 0.4s ease 2.6s forwards;
                    backdrop-filter: blur(10px);
                    border: 1px solid rgba(255,255,255,0.1);
                    box-shadow: 0 8px 30px rgba(0,0,0,0.3);
                }

                .toast-success { background: rgba(74, 222, 128, 0.15); color: #4ADE80; }
                .toast-error { background: rgba(248, 113, 113, 0.15); color: #F87171; }
                .toast-info { background: rgba(96, 165, 250, 0.15); color: #60A5FA; }

                @keyframes toastIn { from { transform: translateY(20px); opacity: 0; } to { transform: translateY(0); opacity: 1; } }
                @keyframes toastOut { from { opacity: 1; } to { opacity: 0; transform: translateY(-10px); } }
            `;
            document.head.appendChild(style);
        }

        document.body.appendChild(toast);
        setTimeout(() => toast.remove(), 3000);
    }

    // ============================================================
    // PUBLIC API
    // ============================================================

    return {
        setToken,
        getToken,
        clearToken,
        login,
        getDashboard,
        getAnalytics,
        getOverview,
        getReports,
        getReport,
        assignWorker,
        getWorkers,
        createWorker,
        getWorkerAttendance,
        getTickets,
        respondToTicket,
        showToast,
    };
})();
