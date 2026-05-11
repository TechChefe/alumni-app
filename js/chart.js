/**
 * Google Charts wrapper: renders a bar chart of alumni distribution
 * by current job country.
 */
const ChartView = (() => {
    let loaded = false;

    function ensureLoaded() {
        return new Promise(resolve => {
            if (loaded) return resolve();
            google.charts.load('current', { packages: ['corechart', 'bar'] });
            google.charts.setOnLoadCallback(() => { loaded = true; resolve(); });
        });
    }

    async function renderCountryDistribution(alumniList) {
        await ensureLoaded();
        const counts = {};
        for (const a of alumniList) {
            const c = a.current_job?.country || a.country || 'Unknown';
            counts[c] = (counts[c] || 0) + 1;
        }
        const sorted = Object.entries(counts).sort((a, b) => b[1] - a[1]);
        const data = google.visualization.arrayToDataTable(
            [['Country', 'Alumni', { role: 'style' }]].concat(
                sorted.map(([c, n], i) => [c, n, colorForIndex(i)])
            )
        );
        const opts = {
            title: 'Alumni distribution by current job country',
            chartArea: { width: '70%', height: '75%' },
            hAxis: { title: 'Country' },
            vAxis: { title: '# Alumni', minValue: 0, format: '0' },
            legend: { position: 'none' },
            backgroundColor: 'transparent',
            fontName: 'system-ui',
        };
        const chart = new google.visualization.ColumnChart(document.getElementById('countryChart'));
        chart.draw(data, opts);
    }

    function colorForIndex(i) {
        const palette = ['#0d6efd','#6610f2','#198754','#fd7e14','#dc3545','#20c997','#ffc107','#0dcaf0','#6f42c1','#d63384'];
        return palette[i % palette.length];
    }

    return { renderCountryDistribution };
})();
