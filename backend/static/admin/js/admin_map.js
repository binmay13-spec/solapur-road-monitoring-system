// NEW FILE — Admin Map Module
// Leaflet.js map with issue markers, heatmap layer, and popup details

const AdminMap = (() => {
    let map = null;
    let markersLayer = null;
    let heatmapLayer = null;
    let isHeatmapVisible = true;

    // Solapur, Maharashtra center coordinates
    const DEFAULT_CENTER = [17.6599, 75.9064];
    const DEFAULT_ZOOM = 13;

    const CATEGORY_ICONS = {
        pothole: { icon: 'fa-road', color: '#F87171' },
        road_obstruction: { icon: 'fa-exclamation-triangle', color: '#FBBF24' },
        water_logging: { icon: 'fa-water', color: '#60A5FA' },
        broken_streetlight: { icon: 'fa-lightbulb', color: '#A78BFA' },
        garbage: { icon: 'fa-trash', color: '#4ADE80' },
    };

    const STATUS_COLORS = {
        pending: '#FBBF24',
        assigned: '#60A5FA',
        in_progress: '#A78BFA',
        completed: '#4ADE80',
    };

    // ============================================================
    // INITIALIZE MAP
    // ============================================================

    function initMap(containerId = 'admin-map') {
        const container = document.getElementById(containerId);
        if (!container) return;

        // Destroy existing map
        if (map) {
            map.remove();
            map = null;
        }

        map = L.map(containerId, {
            center: DEFAULT_CENTER,
            zoom: DEFAULT_ZOOM,
            zoomControl: true,
        });

        // Dark tile layer
        L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png', {
            attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OSM</a> &copy; <a href="https://carto.com/">CARTO</a>',
            subdomains: 'abcd',
            maxZoom: 19,
        }).addTo(map);

        // Initialize layers
        markersLayer = L.layerGroup().addTo(map);

        // Force map to recalculate size
        setTimeout(() => map.invalidateSize(), 200);
    }

    // ============================================================
    // CREATE CUSTOM MARKER
    // ============================================================

    function createMarker(report) {
        const cat = CATEGORY_ICONS[report.category] || { icon: 'fa-map-marker', color: '#77B6EA' };
        const statusColor = STATUS_COLORS[report.status] || '#77B6EA';

        const icon = L.divIcon({
            className: 'custom-marker',
            html: `
                <div style="
                    width: 32px; height: 32px;
                    background: ${cat.color};
                    border-radius: 50%;
                    display: flex; align-items: center; justify-content: center;
                    box-shadow: 0 2px 8px rgba(0,0,0,0.4), 0 0 0 3px ${statusColor}40;
                    border: 2px solid rgba(255,255,255,0.3);
                    transition: transform 0.2s;
                ">
                    <i class="fas ${cat.icon}" style="color: white; font-size: 12px;"></i>
                </div>
            `,
            iconSize: [32, 32],
            iconAnchor: [16, 16],
        });

        const marker = L.marker([report.lat || report.latitude, report.lng || report.longitude], { icon });

        // Popup content
        const popupHtml = `
            <div style="min-width: 180px;">
                <div class="popup-title">${(report.category || '').replace(/_/g, ' ')}</div>
                <div class="popup-status">
                    <span class="status-badge status-${report.status}">
                        <span class="status-dot"></span> ${report.status}
                    </span>
                </div>
                ${report.description ? `<p style="margin: 6px 0; font-size: 0.78rem; color: #8FA3B8;">${report.description}</p>` : ''}
                <p style="font-size: 0.72rem; color: #5A6F82;">
                    📍 ${(report.lat || report.latitude).toFixed(4)}, ${(report.lng || report.longitude).toFixed(4)}
                </p>
            </div>
        `;

        marker.bindPopup(popupHtml);
        return marker;
    }

    // ============================================================
    // UPDATE MARKERS
    // ============================================================

    function updateMarkers(reports, filters = {}) {
        if (!map || !markersLayer) return;

        markersLayer.clearLayers();

        let filtered = reports;

        if (filters.category) {
            filtered = filtered.filter(r => r.category === filters.category);
        }
        if (filters.status) {
            filtered = filtered.filter(r => r.status === filters.status);
        }

        filtered.forEach(report => {
            const lat = report.lat || report.latitude;
            const lng = report.lng || report.longitude;
            if (lat && lng) {
                const marker = createMarker(report);
                markersLayer.addLayer(marker);
            }
        });

        // Update heatmap
        updateHeatmap(filtered);
    }

    // ============================================================
    // HEATMAP
    // ============================================================

    function updateHeatmap(reports) {
        if (!map) return;

        // Remove existing
        if (heatmapLayer) {
            map.removeLayer(heatmapLayer);
            heatmapLayer = null;
        }

        if (!isHeatmapVisible) return;

        const heatData = reports
            .filter(r => {
                const lat = r.lat || r.latitude;
                const lng = r.lng || r.longitude;
                return lat && lng;
            })
            .map(r => [r.lat || r.latitude, r.lng || r.longitude, 0.6]);

        if (heatData.length > 0 && typeof L.heatLayer === 'function') {
            heatmapLayer = L.heatLayer(heatData, {
                radius: 25,
                blur: 20,
                maxZoom: 17,
                max: 1.0,
                gradient: {
                    0.0: '#77B6EA',
                    0.3: '#60A5FA',
                    0.5: '#FBBF24',
                    0.7: '#F59E0B',
                    1.0: '#F87171',
                },
            }).addTo(map);
        }
    }

    function toggleHeatmap(visible) {
        isHeatmapVisible = visible;
    }

    // ============================================================
    // REFRESH MAP SIZE
    // ============================================================

    function refreshSize() {
        if (map) {
            setTimeout(() => map.invalidateSize(), 100);
        }
    }

    // ============================================================
    // PUBLIC API
    // ============================================================

    return {
        initMap,
        updateMarkers,
        toggleHeatmap,
        refreshSize,
    };
})();
