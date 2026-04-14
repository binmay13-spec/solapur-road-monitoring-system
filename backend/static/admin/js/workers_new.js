/**
 * NEW FILE | Extends: backend/static/admin/js/admin_app.js
 * Admin Workers and Attendance Management
 */

const WorkersManager = {
    init: function() {
        this.fetchWorkers();
        this.fetchAttendance();
    },

    fetchWorkers: async function() {
        const response = await fetch('/admin/workers');
        const data = await response.json();
        if (data.success) {
            this.renderWorkers(data.workers);
        }
    },

    renderWorkers: function(workers) {
        const container = document.getElementById('workers-grid');
        container.innerHTML = workers.map(w => `
            <div class="worker-card">
                <div class="worker-header">
                    <h4>${w.name}</h4>
                    <span class="status-${w.status}">${w.status}</span>
                </div>
                <p><i class="fas fa-phone"></i> ${w.phone || 'N/A'}</p>
                <div class="worker-footer">
                    <button class="btn btn-link" onclick="WorkersManager.viewAttendance('${w.worker_id}')">History</button>
                </div>
            </div>
        `).join('');
    },

    fetchAttendance: async function() {
        const response = await fetch('/admin/attendance');
        const data = await response.json();
        if (data.success) {
            this.renderAttendance(data.logs);
        }
    },

    renderAttendance: function(logs) {
        const tbody = document.getElementById('attendance-body');
        tbody.innerHTML = logs.map(l => `
            <tr>
                <td>${l.workers ? l.workers.name : l.worker_id}</td>
                <td>${new Date(l.login_time).toLocaleString()}</td>
                <td>${l.logout_time ? new Date(l.logout_time).toLocaleString() : 'Active'}</td>
                <td><a href="${l.login_photo}" target="_blank">View Photo</a></td>
            </tr>
        `).join('');
    },

    createWorker: async function(event) {
        event.preventDefault();
        const formData = new FormData(event.target);
        const data = Object.fromEntries(formData.entries());

        const response = await fetch('/admin/worker/create', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(data)
        });

        if (response.ok) {
            alert("Worker Created!");
            location.reload();
        }
    }
};

document.addEventListener('DOMContentLoaded', () => WorkersManager.init());
