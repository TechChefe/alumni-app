/**
 * Main SPA controller. Wires the API, the map, the charts,
 * and the various modal forms together.
 */
(function () {
    let allAlumni = [];   // last-known list, used by map + chart
    let currentEditJobId = null;

    document.addEventListener('DOMContentLoaded', async () => {
        MapView.init();
        bindUI();
        refreshAuthUI();
        try {
            await loadAlumniIntoMap();
            const { count } = await API.count();
            document.getElementById('alumni-count-badge').textContent = count;
        } catch (e) {
            toast('Could not load alumni: ' + e.message, 'danger');
        }
    });

    // ------------------------------------------------------------------
    //  Data loading
    // ------------------------------------------------------------------
    async function loadAlumniIntoMap() {
        allAlumni = await API.listAll();
        MapView.plotAlumni(allAlumni);
    }

    // ------------------------------------------------------------------
    //  UI wiring
    // ------------------------------------------------------------------
    function bindUI() {
        // ---- Login form ----
        document.getElementById('loginForm').addEventListener('submit', async (e) => {
            e.preventDefault();
            const email    = document.getElementById('loginEmail').value.trim();
            const password = document.getElementById('loginPassword').value;
            try {
                const { token, user } = await API.login(email, password);
                Auth.setSession(token, user);
                bootstrap.Modal.getInstance(document.getElementById('loginModal')).hide();
                refreshAuthUI();
                toast(`Welcome back, ${user.first_name}!`, 'success');
            } catch (err) {
                toast(err.message, 'danger');
            }
        });

        // ---- Register form ----
        document.getElementById('registerForm').addEventListener('submit', async (e) => {
            e.preventDefault();
            const data = {
                first_name:      document.getElementById('regFirstName').value.trim(),
                last_name:       document.getElementById('regLastName').value.trim(),
                email:           document.getElementById('regEmail').value.trim(),
                password:        document.getElementById('regPassword').value,
                enrollment_year: +document.getElementById('regEnroll').value,
                graduation_year: +document.getElementById('regGrad').value || null,
                country:         document.getElementById('regCountry').value.trim(),
            };
            try {
                await API.register(data);
                toast('Registration successful! You can now log in.', 'success');
                bootstrap.Modal.getInstance(document.getElementById('registerModal')).hide();
                e.target.reset();
                const { count } = await API.count();
                document.getElementById('alumni-count-badge').textContent = count;
                await loadAlumniIntoMap();
            } catch (err) {
                toast(err.message, 'danger');
            }
        });

        // ---- Logout ----
        document.getElementById('logoutBtn').addEventListener('click', () => {
            Auth.clear();
            refreshAuthUI();
            toast('Signed out.', 'info');
        });

        // ---- Search form ----
        document.getElementById('searchForm').addEventListener('submit', (e) => {
            e.preventDefault();
            doSearch(1);
        });

        // ---- Stats modal: render chart on open ----
        document.getElementById('chartModal').addEventListener('shown.bs.modal', async () => {
            if (!allAlumni.length) await loadAlumniIntoMap();
            ChartView.renderCountryDistribution(allAlumni);
        });

        // ---- My Jobs ----
        document.getElementById('myJobsModal').addEventListener('shown.bs.modal', renderMyJobs);
        document.getElementById('addJobBtn').addEventListener('click', () => openJobForm(null));

        // ---- Job form: ensure picker map renders correctly ----
        document.getElementById('jobFormModal').addEventListener('shown.bs.modal', () => {
            MapView.ensurePickerMap();
            const lat = parseFloat(document.getElementById('jobLat').value);
            const lng = parseFloat(document.getElementById('jobLng').value);
            if (!isNaN(lat) && !isNaN(lng)) {
                MapView.setPickerLocation(lat, lng);
            }
        });

        // ---- Save job ----
        document.getElementById('jobForm').addEventListener('submit', async (e) => {
            e.preventDefault();
            const user = Auth.getUser();
            if (!user) return toast('Please log in first', 'warning');

            const data = {
                title:      document.getElementById('jobTitle').value.trim(),
                company:    document.getElementById('jobCompany').value.trim(),
                city:       document.getElementById('jobCity').value.trim(),
                country:    document.getElementById('jobCountry').value.trim(),
                latitude:   +document.getElementById('jobLat').value,
                longitude:  +document.getElementById('jobLng').value,
                start_date: document.getElementById('jobStart').value,
                end_date:   document.getElementById('jobEnd').value || null,
                is_current: document.getElementById('jobCurrent').checked ? 1 : 0,
            };
            try {
                if (currentEditJobId) {
                    await API.updateJob(user.id, currentEditJobId, data);
                    toast('Job updated', 'success');
                } else {
                    await API.addJob(user.id, data);
                    toast('Job added', 'success');
                }
                bootstrap.Modal.getInstance(document.getElementById('jobFormModal')).hide();
                await renderMyJobs();
                await loadAlumniIntoMap();
            } catch (err) {
                toast(err.message, 'danger');
            }
        });
    }

    // ------------------------------------------------------------------
    //  Auth-aware UI refresh
    // ------------------------------------------------------------------
    function refreshAuthUI() {
        const loggedIn = Auth.isLoggedIn();
        document.getElementById('loggedInBlock').classList.toggle('d-none', !loggedIn);
        document.getElementById('loggedOutBlock').classList.toggle('d-none', loggedIn);
        if (loggedIn) {
            const u = Auth.getUser();
            document.getElementById('userGreeting').textContent = `Hi, ${u.first_name}`;
        }
    }

    // ------------------------------------------------------------------
    //  Search (#8)
    // ------------------------------------------------------------------
    async function doSearch(page) {
        const params = {
            last_name:       document.getElementById('qLastName').value.trim(),
            enrollment_year: document.getElementById('qEnroll').value,
            graduation_year: document.getElementById('qGrad').value,
            country:         document.getElementById('qCountry').value.trim(),
            page,
        };
        const format = document.getElementById('qFormat').value;
        try {
            const resp = await API.search(params, format);
            if (resp._xml) {
                document.getElementById('searchRaw').textContent = resp.text;
                renderResultsFromXml(resp.text);
            } else {
                document.getElementById('searchRaw').textContent = JSON.stringify(resp, null, 2);
                renderResultsFromJson(resp);
            }
        } catch (err) {
            toast(err.message, 'danger');
        }
    }

    function renderResultsFromJson(resp) {
        const container = document.getElementById('searchResults');
        const pagBox    = document.getElementById('searchPagination');
        container.innerHTML = '';
        pagBox.innerHTML    = '';
        if (!resp.results.length) {
            container.innerHTML = '<div class="alert alert-warning">No results.</div>';
            return;
        }
        const grid = document.createElement('div');
        grid.className = 'row g-3';
        for (const a of resp.results) {
            const job = a.current_job;
            grid.insertAdjacentHTML('beforeend', `
                <div class="col-md-6">
                    <div class="card shadow-sm h-100">
                        <div class="card-body">
                            <h6 class="card-title mb-1">${esc(a.first_name)} ${esc(a.last_name)}</h6>
                            <div class="text-muted small">
                                Enrolled ${a.enrollment_year}${a.graduation_year ? ` &middot; Graduated ${a.graduation_year}` : ''}
                                &middot; ${esc(a.country)}
                            </div>
                            ${job ? `
                                <hr class="my-2">
                                <div><strong>${esc(job.title)}</strong> @ ${esc(job.company)}</div>
                                <div class="text-muted small">${esc(job.city)}, ${esc(job.country)}</div>
                            ` : '<div class="small text-muted mt-2">No current job recorded.</div>'}
                        </div>
                    </div>
                </div>
            `);
        }
        container.appendChild(grid);
        renderPagination(resp.pagination);
    }

    function renderResultsFromXml(xmlText) {
        const container = document.getElementById('searchResults');
        const pagBox    = document.getElementById('searchPagination');
        container.innerHTML = '';
        pagBox.innerHTML    = '';
        const doc = new DOMParser().parseFromString(xmlText, 'application/xml');
        const items = doc.querySelectorAll('results > item');

        if (!items.length) {
            container.innerHTML = '<div class="alert alert-warning">No results.</div>';
            return;
        }

        const grid = document.createElement('div');
        grid.className = 'row g-3';
        items.forEach(it => {
            const get = (tag) => it.querySelector(':scope > ' + tag)?.textContent || '';
            const jobNode = it.querySelector(':scope > current_job');
            grid.insertAdjacentHTML('beforeend', `
                <div class="col-md-6">
                    <div class="card shadow-sm h-100">
                        <div class="card-body">
                            <h6 class="card-title mb-1">${esc(get('first_name'))} ${esc(get('last_name'))}</h6>
                            <div class="text-muted small">
                                Enrolled ${esc(get('enrollment_year'))}
                                ${get('graduation_year') ? ' &middot; Graduated ' + esc(get('graduation_year')) : ''}
                                &middot; ${esc(get('country'))}
                            </div>
                            ${jobNode ? `
                                <hr class="my-2">
                                <div><strong>${esc(jobNode.querySelector('title')?.textContent || '')}</strong>
                                    @ ${esc(jobNode.querySelector('company')?.textContent || '')}</div>
                                <div class="text-muted small">
                                    ${esc(jobNode.querySelector('city')?.textContent || '')},
                                    ${esc(jobNode.querySelector('country')?.textContent || '')}
                                </div>
                            ` : ''}
                        </div>
                    </div>
                </div>
            `);
        });
        container.appendChild(grid);

        const pagNode = doc.querySelector('pagination');
        if (pagNode) {
            renderPagination({
                page:        +pagNode.querySelector('page')?.textContent,
                total_pages: +pagNode.querySelector('total_pages')?.textContent,
                total:       +pagNode.querySelector('total')?.textContent,
                per_page:    +pagNode.querySelector('per_page')?.textContent,
            });
        }
    }

    function renderPagination(pag) {
        const box = document.getElementById('searchPagination');
        box.innerHTML = '';
        for (let p = 1; p <= pag.total_pages; p++) {
            const li = document.createElement('li');
            li.className = 'page-item' + (p === pag.page ? ' active' : '');
            li.innerHTML = `<a class="page-link" href="#">${p}</a>`;
            li.addEventListener('click', (e) => { e.preventDefault(); doSearch(p); });
            box.appendChild(li);
        }
    }

    // ------------------------------------------------------------------
    //  My jobs
    // ------------------------------------------------------------------
    async function renderMyJobs() {
        const user = Auth.getUser();
        if (!user) return;
        const wrap = document.getElementById('jobsTable');
        wrap.innerHTML = '<div class="text-muted small">Loading…</div>';
        try {
            const jobs = await API.getJobs(user.id);
            if (!jobs.length) {
                wrap.innerHTML = '<div class="alert alert-info">No jobs registered yet. Add one!</div>';
                return;
            }
            const rows = jobs.map(j => `
                <tr>
                    <td>${j.is_current ? '<span class="badge bg-success">Current</span>' : ''}</td>
                    <td>${esc(j.title)}</td>
                    <td>${esc(j.company)}</td>
                    <td>${esc(j.city)}, ${esc(j.country)}</td>
                    <td class="small">${j.start_date} → ${j.end_date || '—'}</td>
                    <td>
                        <button class="btn btn-sm btn-outline-primary me-1" data-edit="${j.id}">
                            <i class="bi bi-pencil"></i>
                        </button>
                        <button class="btn btn-sm btn-outline-danger" data-del="${j.id}">
                            <i class="bi bi-trash"></i>
                        </button>
                    </td>
                </tr>
            `).join('');
            wrap.innerHTML = `
                <div class="table-responsive">
                    <table class="table align-middle">
                        <thead>
                            <tr>
                                <th></th><th>Title</th><th>Company</th><th>Location</th><th>Period</th><th></th>
                            </tr>
                        </thead>
                        <tbody>${rows}</tbody>
                    </table>
                </div>
            `;
            wrap.querySelectorAll('[data-edit]').forEach(b => b.addEventListener('click', () => {
                const job = jobs.find(j => j.id === +b.dataset.edit);
                openJobForm(job);
            }));
            wrap.querySelectorAll('[data-del]').forEach(b => b.addEventListener('click', async () => {
                if (!confirm('Delete this job?')) return;
                try {
                    await API.deleteJob(user.id, +b.dataset.del);
                    toast('Job deleted', 'success');
                    await renderMyJobs();
                    await loadAlumniIntoMap();
                } catch (err) { toast(err.message, 'danger'); }
            }));
        } catch (err) {
            wrap.innerHTML = `<div class="alert alert-danger">${esc(err.message)}</div>`;
        }
    }

    function openJobForm(job) {
        currentEditJobId = job ? job.id : null;
        document.getElementById('jobFormTitle').textContent = job ? 'Edit job' : 'Add job';
        document.getElementById('jobId').value         = job?.id        ?? '';
        document.getElementById('jobTitle').value      = job?.title     ?? '';
        document.getElementById('jobCompany').value    = job?.company   ?? '';
        document.getElementById('jobCity').value       = job?.city      ?? '';
        document.getElementById('jobCountry').value    = job?.country   ?? '';
        document.getElementById('jobLat').value        = job?.latitude  ?? '';
        document.getElementById('jobLng').value        = job?.longitude ?? '';
        document.getElementById('jobStart').value      = job?.start_date ?? '';
        document.getElementById('jobEnd').value        = job?.end_date  ?? '';
        document.getElementById('jobCurrent').checked  = job ? !!job.is_current : true;

        // close My Jobs first to avoid stacked modals issues
        const myJobsModal = bootstrap.Modal.getInstance(document.getElementById('myJobsModal'));
        if (myJobsModal) myJobsModal.hide();
        new bootstrap.Modal(document.getElementById('jobFormModal')).show();
    }

    // ------------------------------------------------------------------
    //  Toast helper
    // ------------------------------------------------------------------
    function toast(msg, type = 'info') {
        const el     = document.getElementById('appToast');
        const body   = document.getElementById('toastBody');
        const title  = document.getElementById('toastTitle');
        body.textContent  = msg;
        title.textContent = ({success:'Success',danger:'Error',warning:'Warning',info:'Info'})[type] || 'Info';
        el.classList.remove('text-bg-success','text-bg-danger','text-bg-warning','text-bg-info');
        el.classList.add('text-bg-' + type);
        bootstrap.Toast.getOrCreateInstance(el, { delay: 3500 }).show();
    }

    function esc(s) {
        return String(s ?? '').replace(/[&<>"']/g, c =>
            ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
    }
})();
