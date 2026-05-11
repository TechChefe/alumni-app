/**
 * Thin wrapper over fetch() that targets our REST API.
 * Auto-injects JSON headers and the Authorization Bearer token if available.
 */
const API = (() => {
    // The Flask backend listens on port 5000. When developing on localhost
    // or the alumni.ds.uth.gr vhost (both pointed at 127.0.0.1), use the
    // same hostname but switch to port 5000.
    //
    // If you want clean URLs (`/api/v1/...` on port 80), set up the Apache
    // mod_proxy snippet shown in the README and change BASE back to '/api/v1'.
    const BASE = `${window.location.protocol}//${window.location.hostname}:5000/api/v1`;

    async function request(path, opts = {}) {
        const headers = {
            'Accept': 'application/json',
            ...(opts.body ? { 'Content-Type': 'application/json' } : {}),
            ...Auth.authHeader(),
            ...(opts.headers || {}),
        };
        const res = await fetch(BASE + path, { ...opts, headers });

        // some endpoints return XML
        const ctype = res.headers.get('content-type') || '';
        if (ctype.includes('xml')) {
            const text = await res.text();
            return { _xml: true, text, status: res.status, ok: res.ok };
        }

        const data = await res.json().catch(() => ({}));
        if (!res.ok) {
            const err = new Error(data.error || `HTTP ${res.status}`);
            err.status = res.status;
            err.payload = data;
            throw err;
        }
        return data;
    }

    return {
        // ----- Auth -----
        login:    (email, password) => request('/auth/login', { method:'POST', body: JSON.stringify({email, password}) }),

        // ----- Alumni -----
        register: (data) => request('/alumni/', { method:'POST', body: JSON.stringify(data) }),
        listAll:  () => request('/alumni/'),
        count:    () => request('/alumni/count'),

        search: (params, format = 'json') => {
            const qs = new URLSearchParams();
            Object.entries(params).forEach(([k,v]) => { if (v !== '' && v != null) qs.append(k, v); });
            qs.append('format', format);
            return request('/alumni/search?' + qs.toString());
        },

        // ----- Jobs -----
        getJobs: (alumniId)            => request(`/alumni/${alumniId}/jobs`),
        addJob:  (alumniId, data)      => request(`/alumni/${alumniId}/jobs`,        { method:'POST',   body: JSON.stringify(data) }),
        updateJob: (alumniId, jobId, data) => request(`/alumni/${alumniId}/jobs/${jobId}`, { method:'PUT', body: JSON.stringify(data) }),
        deleteJob: (alumniId, jobId)   => request(`/alumni/${alumniId}/jobs/${jobId}`, { method:'DELETE' }),

        // direct /jobs/{id} forms (fulfills both URL variants in #6 & #7)
        updateJobDirect: (jobId, data) => request(`/jobs/${jobId}`, { method:'PUT', body: JSON.stringify(data) }),
        deleteJobDirect: (jobId)       => request(`/jobs/${jobId}`, { method:'DELETE' }),
    };
})();
