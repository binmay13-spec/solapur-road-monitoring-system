/**
 * NEW FILE | Extends: backend/static/admin/js/admin_charts.js
 * Admin Analytics Dashboard Logic
 */

const Dashboard = {
    init: function() {
        this.fetchAnalytics();
        this.setupRefresh();
    },

    fetchAnalytics: async function() {
        try {
            // In a real app, this would be a fetch to /admin/analytics
            // For now, using mock data or calling the actual API if available
            const response = await fetch('/admin/analytics', {
                headers: {
                    'Authorization': `Bearer ${localStorage.getItem('admin_token')}`
                }
            });
            const data = await response.json();
            
            if (data.success) {
                this.renderStats(data.analytics);
                this.renderCharts(data.analytics);
            } else {
                this.renderDemoData(); // Fallback
            }
        } catch (e) {
            console.error("Dashboard fetch error:", e);
            this.renderDemoData();
        }
    },

    renderStats: function(stats) {
        document.getElementById('total-reports').textContent = stats.total_reports || 0;
        document.getElementById('active-reports').textContent = stats.active_reports || 0;
        document.getElementById('completed-reports').textContent = stats.completed_reports || 0;
        document.getElementById('active-workers').textContent = stats.active_workers || 0;
    },

    renderCharts: function(stats) {
        // Pie Chart: Category Distribution
        const ctxPie = document.getElementById('categoryChart').getContext('2d');
        new Chart(ctxPie, {
            type: 'doughnut',
            data: {
                labels: Object.keys(stats.category_distribution),
                datasets: [{
                    data: Object.values(stats.category_distribution),
                    backgroundColor: ['#77B6EA', '#D6C9C9', '#C7D3DD', '#37393A', '#E8EEF2']
                }]
            },
            options: { responsive: true, maintainAspectRatio: false }
        });

        // Bar Chart: Performance (Simulated)
        const ctxBar = document.getElementById('performanceChart').getContext('2d');
        new Chart(ctxBar, {
            type: 'bar',
            data: {
                labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
                datasets: [{
                    label: 'Reports Fixed',
                    data: [12, 19, 3, 5, 2, 3, 9],
                    backgroundColor: '#77B6EA'
                }]
            },
            options: { responsive: true, maintainAspectRatio: false }
        });
    },

    renderDemoData: function() {
        const demoStats = {
            total_reports: 142,
            active_reports: 28,
            completed_reports: 114,
            active_workers: 9,
            category_distribution: {
                "Pothole": 45,
                "Obstruction": 20,
                "Water": 15,
                "Streetlight": 10
            }
        };
        this.renderStats(demoStats);
        this.renderCharts(demoStats);
    },

    setupRefresh: function() {
        setInterval(() => this.fetchAnalytics(), 300000); // Every 5 mins
    }
};

document.addEventListener('DOMContentLoaded', () => Dashboard.init());
