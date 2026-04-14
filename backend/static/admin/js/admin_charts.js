// NEW FILE — Admin Dashboard Charts
// Chart.js line chart (reports/time) and pie chart (category distribution)

const AdminCharts = (() => {
    let lineChart = null;
    let pieChart = null;

    const CHART_COLORS = {
        primary: '#77B6EA',
        primaryLight: 'rgba(119, 182, 234, 0.15)',
        pothole: '#F87171',
        road_obstruction: '#FBBF24',
        water_logging: '#60A5FA',
        broken_streetlight: '#A78BFA',
        garbage: '#4ADE80',
    };

    const CATEGORY_LABELS = {
        pothole: 'Pothole',
        road_obstruction: 'Road Obstruction',
        water_logging: 'Water Logging',
        broken_streetlight: 'Broken Streetlight',
        garbage: 'Garbage',
    };

    // ============================================================
    // REPORTS LINE CHART
    // ============================================================

    function initLineChart(hourlyData = {}) {
        const ctx = document.getElementById('reports-line-chart');
        if (!ctx) return;

        if (lineChart) lineChart.destroy();

        // Generate labels (last 24 hours)
        const labels = [];
        const data = [];
        const now = new Date();

        for (let i = 23; i >= 0; i--) {
            const d = new Date(now.getTime() - i * 3600000);
            const key = d.toISOString().slice(0, 13);
            const label = d.getHours().toString().padStart(2, '0') + ':00';
            labels.push(label);
            data.push(hourlyData[key] || 0);
        }

        lineChart = new Chart(ctx, {
            type: 'line',
            data: {
                labels,
                datasets: [{
                    label: 'Reports',
                    data,
                    borderColor: CHART_COLORS.primary,
                    backgroundColor: CHART_COLORS.primaryLight,
                    borderWidth: 2.5,
                    fill: true,
                    tension: 0.4,
                    pointRadius: 0,
                    pointHoverRadius: 6,
                    pointHoverBackgroundColor: CHART_COLORS.primary,
                    pointHoverBorderColor: '#fff',
                    pointHoverBorderWidth: 2,
                }],
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                interaction: {
                    mode: 'index',
                    intersect: false,
                },
                plugins: {
                    legend: { display: false },
                    tooltip: {
                        backgroundColor: 'rgba(15, 25, 35, 0.9)',
                        titleColor: '#E8EEF2',
                        bodyColor: '#8FA3B8',
                        borderColor: 'rgba(119, 182, 234, 0.2)',
                        borderWidth: 1,
                        padding: 12,
                        cornerRadius: 8,
                        displayColors: false,
                    },
                },
                scales: {
                    x: {
                        grid: { color: 'rgba(255, 255, 255, 0.03)' },
                        ticks: {
                            color: '#5A6F82',
                            font: { size: 11, family: 'Inter' },
                            maxTicksLimit: 12,
                        },
                    },
                    y: {
                        beginAtZero: true,
                        grid: { color: 'rgba(255, 255, 255, 0.03)' },
                        ticks: {
                            color: '#5A6F82',
                            font: { size: 11, family: 'Inter' },
                            stepSize: 1,
                        },
                    },
                },
            },
        });
    }

    // ============================================================
    // CATEGORY PIE CHART
    // ============================================================

    function initPieChart(categoryData = {}) {
        const ctx = document.getElementById('category-pie-chart');
        if (!ctx) return;

        if (pieChart) pieChart.destroy();

        const categories = Object.keys(categoryData);
        const values = Object.values(categoryData);

        if (categories.length === 0) {
            // Show placeholder
            categories.push('No Data');
            values.push(1);
        }

        const colors = categories.map(cat => CHART_COLORS[cat] || '#5A6F82');
        const labels = categories.map(cat => CATEGORY_LABELS[cat] || cat);

        pieChart = new Chart(ctx, {
            type: 'doughnut',
            data: {
                labels,
                datasets: [{
                    data: values,
                    backgroundColor: colors,
                    borderColor: 'rgba(15, 25, 35, 0.8)',
                    borderWidth: 3,
                    hoverBorderColor: '#fff',
                    hoverBorderWidth: 2,
                    hoverOffset: 8,
                }],
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                cutout: '65%',
                plugins: {
                    legend: {
                        position: 'bottom',
                        labels: {
                            color: '#8FA3B8',
                            font: { size: 11, family: 'Inter', weight: '500' },
                            padding: 16,
                            usePointStyle: true,
                            pointStyleWidth: 10,
                        },
                    },
                    tooltip: {
                        backgroundColor: 'rgba(15, 25, 35, 0.9)',
                        titleColor: '#E8EEF2',
                        bodyColor: '#8FA3B8',
                        borderColor: 'rgba(119, 182, 234, 0.2)',
                        borderWidth: 1,
                        padding: 12,
                        cornerRadius: 8,
                        callbacks: {
                            label: function(context) {
                                const total = context.dataset.data.reduce((a, b) => a + b, 0);
                                const pct = ((context.parsed / total) * 100).toFixed(1);
                                return ` ${context.label}: ${context.parsed} (${pct}%)`;
                            },
                        },
                    },
                },
            },
        });
    }

    // ============================================================
    // UPDATE CHARTS
    // ============================================================

    function updateCharts(stats) {
        if (stats.hourly) initLineChart(stats.hourly);
        if (stats.categories) initPieChart(stats.categories);
    }

    // ============================================================
    // PUBLIC API
    // ============================================================

    return {
        initLineChart,
        initPieChart,
        updateCharts,
    };
})();
