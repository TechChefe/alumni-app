/**
 * Leaflet/OpenStreetMap module: draws the main map, the marker cluster,
 * and a tiny secondary "picker" map used in the job form.
 */
const MapView = (() => {
    let map, cluster;
    let pickerMap, pickerMarker;

    function init(elementId = 'map') {
        map = L.map(elementId, {
            zoomControl: true,
        }).setView([45, 15], 4);   // Europe-ish

        L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
            maxZoom: 19,
            attribution: '&copy; <a href="https://openstreetmap.org/copyright">OpenStreetMap</a> contributors',
        }).addTo(map);

        cluster = L.markerClusterGroup();
        map.addLayer(cluster);
    }

    function clear() {
        if (cluster) cluster.clearLayers();
    }

    function plotAlumni(alumniList) {
        clear();
        const points = [];
        for (const a of alumniList) {
            if (!a.current_job) continue;
            const { latitude, longitude, title, company, city, country } = a.current_job;
            const popup = `
                <div class="alumni-popup">
                    <h6>${escape(a.first_name)} ${escape(a.last_name)}</h6>
                    <div class="meta">
                        Enrolled ${a.enrollment_year}${a.graduation_year ? ` &middot; Graduated ${a.graduation_year}` : ''}
                    </div>
                    <div class="job-title">${escape(title)}</div>
                    <div class="meta">${escape(company)} &middot; ${escape(city)}, ${escape(country)}</div>
                </div>
            `;
            const m = L.marker([latitude, longitude]).bindPopup(popup);
            cluster.addLayer(m);
            points.push([latitude, longitude]);
        }
        if (points.length) {
            map.fitBounds(points, { padding: [40, 40] });
        }
    }

    // ------------- picker map (in the job modal) ----------------
    function ensurePickerMap() {
        if (pickerMap) {
            // when a hidden modal opens, leaflet sometimes draws blank tiles.
            setTimeout(() => pickerMap.invalidateSize(), 200);
            return pickerMap;
        }
        pickerMap = L.map('jobPickerMap').setView([45, 15], 3);
        L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
            maxZoom: 19,
            attribution: '&copy; OpenStreetMap',
        }).addTo(pickerMap);

        pickerMap.on('click', (e) => {
            const { lat, lng } = e.latlng;
            setPickerLocation(lat, lng);
            document.getElementById('jobLat').value = lat.toFixed(7);
            document.getElementById('jobLng').value = lng.toFixed(7);
        });
        return pickerMap;
    }

    function setPickerLocation(lat, lng) {
        ensurePickerMap();
        if (pickerMarker) pickerMap.removeLayer(pickerMarker);
        pickerMarker = L.marker([lat, lng]).addTo(pickerMap);
        pickerMap.setView([lat, lng], 12);
    }

    function escape(s) {
        return String(s).replace(/[&<>"']/g, c =>
            ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
    }

    return { init, plotAlumni, clear, ensurePickerMap, setPickerLocation };
})();
