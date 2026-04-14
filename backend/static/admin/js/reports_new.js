/**
 * NEW FILE | Extends: backend/static/admin/js/admin_app.js
 * Admin Reports Management Logic
 */

const ReportsTable = {
    limit: 10,
    offset: 0,
    allReports: [],

    init: function() {
        this.fetchReports();
        this.setupFilters();
    },

    fetchReports: async function() {
        try {
            const response = await fetch('/admin/reports', {
                headers: {
                    'Authorization': `Bearer ${localStorage.getItem('admin_token')}`
                }
            });
            const data = await response.json();
            if (data.success) {
                this.allReports = data.reports;
                this.renderTable(data.reports);
            }
        } catch (e) {
            console.error("Reports fetch error:", e);
        }
    },

    renderTable: function(reports) {
        const tbody = document.getElementById('reports-body');
        tbody.innerHTML = reports.map(r => `
            <tr>
                <td>#${r.id.toString().slice(-4)}</td>
                <td><span class="badge badge-${this.getStatusClass(r.status)}">${r.status}</span></td>
                <td>${r.category}</td>
                <td>${r.users ? r.users.name : 'Citizen'}</td>
                <td>${new Date(r.created_at).toLocaleDateString()}</td>
                <td>
                    <button class="btn btn-sm btn-primary" onclick="ReportsTable.openAssignModal(${r.id})">Assign</button>
                    <button class="btn btn-sm btn-secondary" onclick="ReportsTable.viewDetails(${r.id})">View</button>
                </td>
            </tr>
        `).join('');
    },

    getStatusClass: function(status) {
        switch(status) {
            case 'completed': return 'success';
            case 'assigned': return 'info';
            case 'pending': return 'warning';
            default: return 'secondary';
        }
    },

    openAssignModal: async function(reportId) {
        // Fetch workers list
        const response = await fetch('/admin/workers');
        const data = await response.json();
        
        if (data.success) {
            const workerSelect = document.getElementById('worker-select');
            workerSelect.innerHTML = data.workers
                .filter(w => w.status === 'available')
                .map(w => `<option value="${w.worker_id}">${w.name} (${w.phone})</option>`).join('');
            
            document.getElementById('assign-report-id').value = reportId;
            // Show modal logic here (if using a library or simple hidden div)
            document.getElementById('assign-modal').style.display = 'block';
        }
    },

    assignWorker: async function() {
        const reportId = document.getElementById('assign-report-id').value;
        const workerId = document.getElementById('worker-select').value;

        const response = await fetch('/admin/assign', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ report_id: reportId, worker_id: workerId })
        });

        if (response.ok) {
            alert("Worker Assigned!");
            location.reload();
        }
    },

    setupFilters: function() {
        document.getElementById('filter-status').addEventListener('change', (e) => {
            const val = e.target.value;
            const filtered = val === 'all' ? this.allReports : this.allReports.filter(r => r.status === val);
            this.renderTable(filtered);
        });
    }
};

document.addEventListener('DOMContentLoaded', () => ReportsTable.init());
