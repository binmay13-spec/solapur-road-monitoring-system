// NEW FILE — Admin Dashboard Main Application
// SPA section switching, data loading, event handlers

(() => {
    'use strict';

    // ============================================================
    // STATE
    // ============================================================

    let currentSection = 'overview';
    let allReports = [];
    let allWorkers = [];
    let allTickets = [];
    let dashboardStats = {};
    let mapReportsData = [];

    // ============================================================
    // SECTION SWITCHING
    // ============================================================

    window.switchSection = function (sectionName) {
        // Update menu
        document.querySelectorAll('.menu-item').forEach(item => {
            item.classList.toggle('active', item.dataset.section === sectionName);
        });

        // Update sections
        document.querySelectorAll('.content-section').forEach(section => {
            section.classList.toggle('active', section.id === `section-${sectionName}`);
        });

        // Update top bar
        const titles = {
            overview: ['Overview', 'Dashboard analytics and monitoring'],
            reports: ['Reports', 'Manage all reported road issues'],
            workers: ['Workers', 'Worker management and attendance'],
            map: ['Live Map', 'Real-time issue monitoring on map'],
            support: ['Support', 'Citizen support tickets'],
        };

        const [title, subtitle] = titles[sectionName] || ['', ''];
        document.getElementById('page-title').textContent = title;
        document.getElementById('page-subtitle').textContent = subtitle;

        currentSection = sectionName;

        // Load section data
        loadSectionData(sectionName);

        // Close mobile sidebar
        document.getElementById('sidebar').classList.remove('open');
    };

    function loadSectionData(section) {
        switch (section) {
            case 'overview': loadOverview(); break;
            case 'reports': loadReports(); break;
            case 'workers': loadWorkers(); break;
            case 'map': loadMap(); break;
            case 'support': loadSupport(); break;
        }
    }

    // ============================================================
    // OVERVIEW
    // ============================================================

    async function loadOverview() {
        try {
            const data = await AdminAPI.getDashboard();
            if (!data || !data.success) {
                // Use demo data for offline/unauthenticated mode
                useDemoData();
                return;
            }

            dashboardStats = data.stats;
            updateStatsCards(data.stats);
            AdminCharts.updateCharts(data.stats);
            loadRecentReports();
        } catch (e) {
            console.warn('Using demo data:', e.message);
            useDemoData();
        }
    }

    function useDemoData() {
        const demoStats = {
            total: 147,
            active: 38,
            completed: 109,
            active_workers: 12,
            categories: {
                pothole: 52,
                water_logging: 28,
                road_obstruction: 31,
                broken_streetlight: 18,
                garbage: 18,
            },
            hourly: {},
        };

        // Generate demo hourly data
        const now = new Date();
        for (let i = 0; i < 24; i++) {
            const d = new Date(now.getTime() - i * 3600000);
            const key = d.toISOString().slice(0, 13);
            demoStats.hourly[key] = Math.floor(Math.random() * 8) + 1;
        }

        updateStatsCards(demoStats);
        AdminCharts.updateCharts(demoStats);

        // Demo recent reports
        const demoReports = generateDemoReports(5);
        renderRecentReports(demoReports);
    }

    function generateDemoReports(count) {
        const categories = ['pothole', 'water_logging', 'road_obstruction', 'broken_streetlight', 'garbage'];
        const statuses = ['pending', 'assigned', 'in_progress', 'completed'];
        const reports = [];

        for (let i = 0; i < count; i++) {
            reports.push({
                id: `demo-${i + 1}`,
                category: categories[i % categories.length],
                status: statuses[i % statuses.length],
                latitude: 17.6599 + (Math.random() - 0.5) * 0.05,
                longitude: 75.9064 + (Math.random() - 0.5) * 0.05,
                description: `Sample report ${i + 1}`,
                created_at: new Date(Date.now() - i * 3600000).toISOString(),
            });
        }
        return reports;
    }

    function updateStatsCards(stats) {
        animateValue('stat-total', stats.total || 0);
        animateValue('stat-active', stats.active || 0);
        animateValue('stat-completed', stats.completed || 0);
        animateValue('stat-workers', stats.active_workers || 0);
    }

    function animateValue(elementId, target) {
        const el = document.getElementById(elementId);
        if (!el) return;

        const duration = 800;
        const start = parseInt(el.textContent) || 0;
        const diff = target - start;
        const startTime = performance.now();

        function update(now) {
            const elapsed = now - startTime;
            const progress = Math.min(elapsed / duration, 1);
            const eased = 1 - Math.pow(1 - progress, 3); // ease-out cubic
            el.textContent = Math.round(start + diff * eased);
            if (progress < 1) requestAnimationFrame(update);
        }

        requestAnimationFrame(update);
    }

    async function loadRecentReports() {
        try {
            const data = await AdminAPI.getReports({ limit: 5 });
            if (data && data.success) {
                renderRecentReports(data.reports);
            }
        } catch (e) {
            console.warn('Failed to load recent reports:', e.message);
        }
    }

    function renderRecentReports(reports) {
        const tbody = document.getElementById('recent-reports-body');
        if (!tbody) return;

        if (!reports || reports.length === 0) {
            tbody.innerHTML = '<tr><td colspan="6" style="text-align:center; color: var(--text-muted); padding: 30px;">No reports yet</td></tr>';
            return;
        }

        tbody.innerHTML = reports.map(r => `
            <tr>
                <td><code style="font-size: 0.75rem; color: var(--text-muted);">${(r.id || '').slice(0, 8)}...</code></td>
                <td>${getCategoryBadge(r.category)}</td>
                <td><span class="status-badge status-${r.status}"><span class="status-dot"></span> ${r.status}</span></td>
                <td style="font-size: 0.78rem;">📍 ${(r.latitude || 0).toFixed(3)}, ${(r.longitude || 0).toFixed(3)}</td>
                <td style="font-size: 0.78rem;">${formatDate(r.created_at)}</td>
                <td><button class="btn btn-sm btn-outline" onclick="viewReport('${r.id}')">View</button></td>
            </tr>
        `).join('');
    }

    // ============================================================
    // REPORTS
    // ============================================================

    async function loadReports() {
        const status = document.getElementById('filter-status')?.value || '';
        const category = document.getElementById('filter-category')?.value || '';

        try {
            const data = await AdminAPI.getReports({ status, category, limit: 100 });
            if (data && data.success) {
                allReports = data.reports;
                renderAllReports(data.reports);
            } else {
                const demo = generateDemoReports(15);
                allReports = demo;
                renderAllReports(demo);
            }
        } catch (e) {
            const demo = generateDemoReports(15);
            allReports = demo;
            renderAllReports(demo);
        }
    }

    function renderAllReports(reports) {
        const tbody = document.getElementById('all-reports-body');
        if (!tbody) return;

        if (!reports || reports.length === 0) {
            tbody.innerHTML = '<tr><td colspan="7" style="text-align:center; color: var(--text-muted); padding: 30px;">No reports found</td></tr>';
            return;
        }

        tbody.innerHTML = reports.map(r => `
            <tr>
                <td>
                    ${r.image_url
                        ? `<img src="${r.image_url}" class="report-thumb" alt="Report">`
                        : `<div class="report-thumb-placeholder"><i class="fas fa-image"></i></div>`
                    }
                </td>
                <td>${getCategoryBadge(r.category)}</td>
                <td style="max-width: 200px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;">
                    ${r.description || '—'}
                </td>
                <td><span class="status-badge status-${r.status}"><span class="status-dot"></span> ${r.status}</span></td>
                <td style="font-size: 0.78rem;">${r.assigned_worker_id ? r.assigned_worker_id.slice(0, 8) + '...' : '—'}</td>
                <td style="font-size: 0.78rem;">${formatDate(r.created_at)}</td>
                <td>
                    <div style="display: flex; gap: 6px;">
                        ${r.status === 'pending' ? `<button class="btn btn-sm btn-primary" onclick="openAssignModal('${r.id}')">Assign</button>` : ''}
                        <button class="btn btn-sm btn-outline" onclick="viewReport('${r.id}')">View</button>
                    </div>
                </td>
            </tr>
        `).join('');

        // Update badge
        const pending = reports.filter(r => r.status === 'pending').length;
        const badge = document.getElementById('reports-badge');
        if (badge) badge.textContent = pending;
    }

    // ============================================================
    // ASSIGN WORKER
    // ============================================================

    window.openAssignModal = async function (reportId) {
        document.getElementById('assign-report-id').textContent = reportId.slice(0, 12) + '...';
        document.getElementById('assign-modal').dataset.reportId = reportId;

        // Load workers into select
        const select = document.getElementById('worker-select');
        select.innerHTML = '<option value="">-- Select Worker --</option>';

        try {
            const data = await AdminAPI.getWorkers();
            if (data && data.success) {
                data.workers.forEach(w => {
                    const status = w.status || 'available';
                    select.innerHTML += `<option value="${w.worker_id}" ${status === 'offline' ? 'disabled' : ''}>${w.name} (${status})</option>`;
                });
            }
        } catch (e) {
            select.innerHTML += '<option value="demo-worker">Demo Worker (available)</option>';
        }

        openModal('assign-modal');
    };

    // ============================================================
    // WORKERS
    // ============================================================

    async function loadWorkers() {
        try {
            const data = await AdminAPI.getWorkers();
            if (data && data.success) {
                allWorkers = data.workers;
                renderWorkers(data.workers);
            } else {
                renderWorkers(generateDemoWorkers());
            }
        } catch (e) {
            renderWorkers(generateDemoWorkers());
        }
    }

    function generateDemoWorkers() {
        return [
            { worker_id: 'w1', name: 'Rajesh Kumar', phone: '+91 98765 43210', status: 'available', total_tasks_completed: 24, current_task_count: 2 },
            { worker_id: 'w2', name: 'Sunil Patil', phone: '+91 98765 43211', status: 'busy', total_tasks_completed: 18, current_task_count: 3 },
            { worker_id: 'w3', name: 'Amit Jadhav', phone: '+91 98765 43212', status: 'offline', total_tasks_completed: 31, current_task_count: 0 },
        ];
    }

    function renderWorkers(workers) {
        const grid = document.getElementById('workers-grid');
        if (!grid) return;

        if (!workers || workers.length === 0) {
            grid.innerHTML = '<p style="color: var(--text-muted); text-align: center; padding: 40px;">No workers found</p>';
            return;
        }

        grid.innerHTML = workers.map(w => `
            <div class="worker-card">
                <div class="worker-card-header">
                    <div class="worker-avatar">${(w.name || 'W').charAt(0).toUpperCase()}</div>
                    <div class="worker-info">
                        <h4>${w.name || 'Unknown'}</h4>
                        <span>${w.phone || 'No phone'}</span>
                    </div>
                    <span class="status-badge status-${w.status || 'offline'}">
                        <span class="status-dot"></span> ${w.status || 'offline'}
                    </span>
                </div>
                <div class="worker-stats">
                    <div class="worker-stat">
                        <span class="worker-stat-value">${w.total_tasks_completed || 0}</span>
                        <span class="worker-stat-label">Completed</span>
                    </div>
                    <div class="worker-stat">
                        <span class="worker-stat-value">${w.current_task_count || 0}</span>
                        <span class="worker-stat-label">Active</span>
                    </div>
                </div>
                <div class="worker-card-actions">
                    <button class="btn btn-sm btn-outline" onclick="viewWorkerAttendance('${w.worker_id}', '${w.name}')">
                        <i class="fas fa-calendar-check"></i> Attendance
                    </button>
                </div>
            </div>
        `).join('');
    }

    window.viewWorkerAttendance = async function (workerId, workerName) {
        document.getElementById('attendance-worker-name').textContent = workerName;

        const tbody = document.getElementById('attendance-body');
        tbody.innerHTML = '<tr><td colspan="4"><div class="loading-spinner"><i class="fas fa-spinner fa-spin"></i> Loading...</div></td></tr>';

        openModal('attendance-modal');

        try {
            const data = await AdminAPI.getWorkerAttendance(workerId);
            if (data && data.success && data.attendance.length > 0) {
                tbody.innerHTML = data.attendance.map(a => `
                    <tr>
                        <td>${a.date || '—'}</td>
                        <td>${a.login_time ? new Date(a.login_time).toLocaleTimeString() : '—'}</td>
                        <td>${a.logout_time ? new Date(a.logout_time).toLocaleTimeString() : '—'}</td>
                        <td style="font-size: 0.78rem;">${a.latitude ? `${a.latitude.toFixed(4)}, ${a.longitude.toFixed(4)}` : '—'}</td>
                    </tr>
                `).join('');
            } else {
                tbody.innerHTML = '<tr><td colspan="4" style="text-align:center; color: var(--text-muted);">No attendance records</td></tr>';
            }
        } catch (e) {
            tbody.innerHTML = '<tr><td colspan="4" style="text-align:center; color: var(--text-muted);">Failed to load attendance</td></tr>';
        }
    };

    // ============================================================
    // MAP
    // ============================================================

    async function loadMap() {
        AdminMap.initMap('admin-map');

        try {
            const data = await AdminAPI.getAnalytics();
            if (data && data.success && data.heatmap) {
                mapReportsData = data.heatmap;
                AdminMap.updateMarkers(data.heatmap);
            } else {
                // Demo data
                const demoMapData = generateDemoReports(30);
                mapReportsData = demoMapData;
                AdminMap.updateMarkers(demoMapData);
            }
        } catch (e) {
            const demoMapData = generateDemoReports(30);
            mapReportsData = demoMapData;
            AdminMap.updateMarkers(demoMapData);
        }
    }

    // ============================================================
    // SUPPORT
    // ============================================================

    async function loadSupport() {
        const statusFilter = document.getElementById('support-filter-status')?.value || '';

        try {
            const data = await AdminAPI.getTickets(statusFilter);
            if (data && data.success) {
                allTickets = data.tickets;
                renderTickets(data.tickets);
            } else {
                renderTickets(generateDemoTickets());
            }
        } catch (e) {
            renderTickets(generateDemoTickets());
        }
    }

    function generateDemoTickets() {
        return [
            { id: 't1', user_id: 'u1', message: 'My report has been pending for 3 days', status: 'open', created_at: new Date().toISOString(), users: { name: 'Priya Sharma', email: 'priya@email.com' } },
            { id: 't2', user_id: 'u2', message: 'Cannot upload photos in the app', status: 'open', created_at: new Date().toISOString(), users: { name: 'Rahul Deshmukh', email: 'rahul@email.com' } },
        ];
    }

    function renderTickets(tickets) {
        const tbody = document.getElementById('support-tickets-body');
        if (!tbody) return;

        // Update badge
        const openCount = tickets.filter(t => t.status === 'open').length;
        const badge = document.getElementById('support-badge');
        if (badge) badge.textContent = openCount;

        if (!tickets || tickets.length === 0) {
            tbody.innerHTML = '<tr><td colspan="5" style="text-align:center; color: var(--text-muted); padding: 30px;">No tickets</td></tr>';
            return;
        }

        tbody.innerHTML = tickets.map(t => {
            const user = t.users || {};
            return `
                <tr>
                    <td>
                        <div style="font-weight: 600; font-size: 0.85rem;">${user.name || 'Unknown'}</div>
                        <div style="font-size: 0.75rem; color: var(--text-muted);">${user.email || ''}</div>
                    </td>
                    <td style="max-width: 250px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;">
                        ${t.message}
                    </td>
                    <td><span class="status-badge status-${t.status}"><span class="status-dot"></span> ${t.status}</span></td>
                    <td style="font-size: 0.78rem;">${formatDate(t.created_at)}</td>
                    <td>
                        ${t.status === 'open'
                            ? `<button class="btn btn-sm btn-primary" onclick="openReplyModal('${t.id}', \`${t.message.replace(/`/g, "'")}\`)">Reply</button>`
                            : `<span style="font-size: 0.78rem; color: var(--success);">✓ Responded</span>`
                        }
                    </td>
                </tr>
            `;
        }).join('');
    }

    window.openReplyModal = function (ticketId, message) {
        document.getElementById('ticket-original-message').textContent = message;
        document.getElementById('reply-modal').dataset.ticketId = ticketId;
        document.getElementById('ticket-response').value = '';
        openModal('reply-modal');
    };

    // ============================================================
    // HELPERS
    // ============================================================

    function getCategoryBadge(category) {
        const icons = {
            pothole: 'fa-road',
            road_obstruction: 'fa-exclamation-triangle',
            water_logging: 'fa-water',
            broken_streetlight: 'fa-lightbulb',
            garbage: 'fa-trash',
        };
        const icon = icons[category] || 'fa-question';
        const label = (category || '').replace(/_/g, ' ');
        return `<span class="category-badge cat-${category}"><i class="fas ${icon}"></i> ${label}</span>`;
    }

    function formatDate(dateStr) {
        if (!dateStr) return '—';
        const d = new Date(dateStr);
        const now = new Date();
        const diffMs = now - d;
        const diffMin = Math.floor(diffMs / 60000);
        const diffHrs = Math.floor(diffMs / 3600000);

        if (diffMin < 1) return 'Just now';
        if (diffMin < 60) return `${diffMin}m ago`;
        if (diffHrs < 24) return `${diffHrs}h ago`;
        return d.toLocaleDateString('en-IN', { day: 'numeric', month: 'short' });
    }

    window.viewReport = function (reportId) {
        AdminAPI.showToast(`Report: ${reportId}`, 'info');
    };

    // ============================================================
    // MODAL HELPERS
    // ============================================================

    window.openModal = function (modalId) {
        document.getElementById(modalId)?.classList.add('active');
    };

    window.closeModal = function (modalId) {
        document.getElementById(modalId)?.classList.remove('active');
    };

    // Close modal on overlay click
    document.querySelectorAll('.modal-overlay').forEach(overlay => {
        overlay.addEventListener('click', e => {
            if (e.target === overlay) overlay.classList.remove('active');
        });
    });

    // ============================================================
    // EVENT LISTENERS
    // ============================================================

    document.addEventListener('DOMContentLoaded', () => {
        // Sidebar navigation
        document.querySelectorAll('.menu-item[data-section]').forEach(item => {
            item.addEventListener('click', e => {
                e.preventDefault();
                switchSection(item.dataset.section);
            });
        });

        // Mobile menu toggle
        document.getElementById('menu-toggle')?.addEventListener('click', () => {
            document.getElementById('sidebar').classList.toggle('open');
        });

        // Refresh button
        document.getElementById('refresh-btn')?.addEventListener('click', () => {
            loadSectionData(currentSection);
            AdminAPI.showToast('Data refreshed', 'success');
        });

        // Report filters
        document.getElementById('apply-filters')?.addEventListener('click', loadReports);

        // Map filters
        document.getElementById('map-filter-category')?.addEventListener('change', () => {
            const category = document.getElementById('map-filter-category').value;
            const status = document.getElementById('map-filter-status').value;
            AdminMap.updateMarkers(mapReportsData, { category, status });
        });

        document.getElementById('map-filter-status')?.addEventListener('change', () => {
            const category = document.getElementById('map-filter-category').value;
            const status = document.getElementById('map-filter-status').value;
            AdminMap.updateMarkers(mapReportsData, { category, status });
        });

        document.getElementById('toggle-heatmap')?.addEventListener('change', e => {
            AdminMap.toggleHeatmap(e.target.checked);
            const category = document.getElementById('map-filter-category')?.value || '';
            const status = document.getElementById('map-filter-status')?.value || '';
            AdminMap.updateMarkers(mapReportsData, { category, status });
        });

        // Support filter
        document.getElementById('support-filter-status')?.addEventListener('change', loadSupport);

        // Confirm assign worker
        document.getElementById('confirm-assign')?.addEventListener('click', async () => {
            const modal = document.getElementById('assign-modal');
            const reportId = modal.dataset.reportId;
            const workerId = document.getElementById('worker-select').value;

            if (!workerId) {
                AdminAPI.showToast('Please select a worker', 'error');
                return;
            }

            try {
                const data = await AdminAPI.assignWorker(reportId, workerId);
                if (data && data.success) {
                    AdminAPI.showToast('Worker assigned successfully!', 'success');
                    closeModal('assign-modal');
                    loadReports();
                } else {
                    AdminAPI.showToast('Assignment failed', 'error');
                }
            } catch (e) {
                AdminAPI.showToast('Assignment failed: ' + e.message, 'error');
            }
        });

        // Confirm add worker
        document.getElementById('add-worker-btn')?.addEventListener('click', () => {
            openModal('add-worker-modal');
        });

        document.getElementById('confirm-add-worker')?.addEventListener('click', async () => {
            const name = document.getElementById('new-worker-name').value.trim();
            const phone = document.getElementById('new-worker-phone').value.trim();
            const email = document.getElementById('new-worker-email').value.trim();

            if (!name) {
                AdminAPI.showToast('Worker name is required', 'error');
                return;
            }

            try {
                const data = await AdminAPI.createWorker({ name, phone, email });
                if (data && data.success) {
                    AdminAPI.showToast('Worker created!', 'success');
                    closeModal('add-worker-modal');
                    loadWorkers();
                } else {
                    AdminAPI.showToast('Failed to create worker', 'error');
                }
            } catch (e) {
                AdminAPI.showToast('Error: ' + e.message, 'error');
            }
        });

        // Confirm reply ticket
        document.getElementById('confirm-reply')?.addEventListener('click', async () => {
            const modal = document.getElementById('reply-modal');
            const ticketId = modal.dataset.ticketId;
            const response = document.getElementById('ticket-response').value.trim();

            if (!response) {
                AdminAPI.showToast('Response cannot be empty', 'error');
                return;
            }

            try {
                const data = await AdminAPI.respondToTicket(ticketId, response);
                if (data && data.success) {
                    AdminAPI.showToast('Response sent!', 'success');
                    closeModal('reply-modal');
                    loadSupport();
                } else {
                    AdminAPI.showToast('Failed to send response', 'error');
                }
            } catch (e) {
                AdminAPI.showToast('Error: ' + e.message, 'error');
            }
        });

        // Initial load
        loadOverview();
    });
})();
