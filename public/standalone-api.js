// Standalone data layer for "Virtual Stops with route engine standalone".
// Local mode (default, for the prototype): everything in this browser's localStorage.
// Server mode: set window.CONVOY_CONFIG.api = '/api/v1' (the Node server does this) and the same calls go to the server.
(function () {
  const CFG = window.CONVOY_CONFIG || {}, API = CFG.api || null;
  const DBK = 'sa-db-v1', SK = 'sa-session-v1', GK = 'sa-geo-v1';
  const uid = p => p + Math.random().toString(36).slice(2, 8) + Date.now().toString(36).slice(-4);
  const today = () => new Date().toISOString().slice(0, 10);
  const clone = o => JSON.parse(JSON.stringify(o));
  const SEED = window.VS_DATA ? clone(window.VS_DATA) : null;
  window.SSS_SEED = SEED;
  window.VS_DATA = undefined; // the page boots once SA has built its data

  async function sha(s) { const b = await crypto.subtle.digest('SHA-256', new TextEncoder().encode('convoy|' + s)); return [...new Uint8Array(b)].map(x => x.toString(16).padStart(2, '0')).join(''); }
  const PERMS = [{ id: 'users', label: 'Users' }, { id: 'schools', label: 'Schools & Riders' }, { id: 'plans', label: 'Stops & Route Plans' }, { id: 'library', label: 'Stop Library' }, { id: 'vehicles', label: 'Vehicles & Attendants' }];
  const ALL = PERMS.map(p => p.id);
  const LBL = { AM: { prefix: 'AM ', suffix: '', start: 1, digits: 0 }, PM: { prefix: 'PM ', suffix: '', start: 1, digits: 0 }, ASA: { prefix: 'CCA ', suffix: '', start: 1, digits: 0 } };

  // ---------------- local store ----------------
  let db = null;
  const save = () => { try { localStorage.setItem(DBK, JSON.stringify(db)); } catch (e) { console.warn('SA save failed (storage full?)', e); } };
  async function seed() {
    const now = new Date().toISOString();
    db = { v: 2, users: [], companies: [], schools: [], datasets: [], manual: [], vehicles: [], attendants: [], trips: [], labels: {}, settings: {}, stops: {}, drafts: {}, plans: {} };
    db.users.push({ id: 'u_super', name: 'Convoy Admin', email: 'admin@convoy.sg', pw: await sha('Convoy123!'), role: 'super', companyId: null, createdAt: now });
    db.companies.push({ id: 'c_simpledrive', name: 'SimpleDrive', createdAt: now });
    db.users.push({ id: 'u_sd', name: 'SimpleDrive Ops', email: 'ops@simpledrive.sg', pw: await sha('Simple123!'), role: 'admin', companyId: 'c_simpledrive', createdAt: now });
    db.settings.c_simpledrive = { labels: clone(LBL) };
    if (SEED) {
      const sc = SEED.school;
      db.schools.push({ id: 's_sss', companyId: 'c_simpledrive', name: sc.name, short: sc.short, address: sc.address, postal: (sc.address.match(/\d{6}/) || [''])[0], lat: sc.lat, lng: sc.lng, createdAt: now });
      const rows = SEED.riders.map(r => ({ rid: r.rid, name: r.name, gender: '', grade: r.level, address: r.address || '', postal: r.postal, lat: r.lat, lng: r.lng, am: true, pm: true, cca: '', start: '', end: '', parentName: '', parentContact: '', remarks: '', addrStatus: r.addrStatus }));
      db.datasets.push({ id: 'd_seed', schoolId: 's_sss', effectiveFrom: '2026-01-02', fileName: 'St Stephens 2026 riders.csv', uploadedAt: now, uploadedBy: 'Seed data', rows });
      db.stops.c_simpledrive = { lib: SEED.stops.map(st => { const o = clone(st); o.bySchool = { s_sss: { postalCodes: st.postalCodes || [], areas: st.areas || [], off: st.off || [] } }; delete o.postalCodes; delete o.areas; delete o.off; return o; }), counters: SEED.counters || {} };
    }
    save();
  }
  async function loadDb() { if (db) return db; try { db = JSON.parse(localStorage.getItem(DBK) || 'null'); } catch (e) { db = null; } if (!db || !db.users) await seed();
    ['attendants', 'trips'].forEach(k => { db[k] = db[k] || []; }); db.labels = db.labels || {}; db.users.forEach(u => { if (!u.perms) u.perms = u.role === 'user' ? ['schools', 'plans'] : ALL.slice(); }); return db; }
  const sess = () => { try { return JSON.parse(localStorage.getItem(SK) || 'null'); } catch (e) { return null; } };
  const setSess = s => { if (s) localStorage.setItem(SK, JSON.stringify(s)); else localStorage.removeItem(SK); };
  const me = () => { const s = sess(); if (!s || !db) return null; const u = db.users.find(x => x.id === s.userId); if (!u) return null; return { id: u.id, name: u.name, email: u.email, role: u.role, perms: u.role === 'super' || u.role === 'admin' ? ALL.slice() : (u.perms || []), companyId: u.role === 'super' ? s.companyId || null : u.companyId }; };
  const need = () => { const m = me(); if (!m) throw new Error('Please sign in'); return m; };
  const cid = () => { const m = need(); if (!m.companyId) throw new Error('Pick a transport company first'); return m.companyId; };
  const pubUser = u => ({ id: u.id, name: u.name, email: u.email, role: u.role, perms: u.role === 'admin' ? ALL.slice() : (u.perms || []), companyId: u.companyId, createdAt: u.createdAt });
  const can = p => { const m = need(); return m.perms.includes(p); };

  function riderEvents(dsets, manual) {
    const out = [], seen = new Set(), svc = r => [r.am !== false && 'AM', r.pm !== false && 'PM', r.cca && 'CCA'].filter(Boolean).join(' + ') || 'No service';
    const add = (date, kind, r, note) => { if (!date) return; const k = date + kind + (r ? r.rid : note); if (seen.has(k)) return; seen.add(k); out.push({ date, kind, rid: r ? r.rid : null, name: r ? r.name : note, svc: r ? svc(r) : '' }); };
    const ds = dsets.slice().sort((a, b) => a.effectiveFrom.localeCompare(b.effectiveFrom));
    ds.forEach((d, i) => { add(d.effectiveFrom, 'list', null, d.fileName); const prev = i ? new Map(ds[i - 1].rows.map(r => [r.rid, r])) : null, cur = new Set(d.rows.map(r => r.rid));
      d.rows.forEach(r => { const late = r.start && r.start > d.effectiveFrom;
        if ((prev && !prev.has(r.rid)) || late) add(late ? r.start : d.effectiveFrom, 'join', r);
        else if (prev && svc(prev.get(r.rid)) !== svc(r)) add(d.effectiveFrom, 'change', r);
        if (r.end) add(r.end, 'leave', r); });
      if (prev) prev.forEach((r, rid) => { if (!cur.has(rid)) add(d.effectiveFrom, 'leave', r); }); });
    manual.forEach(r => { if (r.start) add(r.start, 'join', r); if (r.end) add(r.end, 'leave', r); });
    return out.sort((a, b) => a.date.localeCompare(b.date));
  }
  const local = {
    async session() { await loadDb(); const m = me(); if (!m) return null; const s = sess(); return { user: m, schoolId: s.schoolId || null, date: s.date || today(), company: m.companyId ? db.companies.find(c => c.id === m.companyId) || null : null }; },
    async login(email, password) { await loadDb(); const u = db.users.find(x => x.email.toLowerCase() === String(email).trim().toLowerCase()); if (!u || u.pw !== await sha(password)) throw new Error('Email or password is incorrect'); setSess({ userId: u.id, companyId: u.role === 'super' ? null : u.companyId, schoolId: null, date: today() }); return this.session(); },
    async logout() { setSess(null); },
    async loginAs(kind) { return this.login(kind === 'super' ? 'admin@convoy.sg' : 'ops@simpledrive.sg', kind === 'super' ? 'Convoy123!' : 'Simple123!'); },
    async setContext(o) { const s = sess(); if (!s) return; Object.assign(s, o); setSess(s); },
    async listCompanies() { const m = need(); const list = m.role === 'super' ? db.companies : db.companies.filter(c => c.id === m.companyId); return list.map(c => ({ ...c, users: db.users.filter(u => u.companyId === c.id).length, schools: db.schools.filter(s => s.companyId === c.id).length, adminEmail: (db.users.find(u => u.companyId === c.id && u.role === 'admin') || {}).email || '' })); },
    async createCompany(o) { const m = need(); if (m.role !== 'super') throw new Error('Only Convoy admins can add transport companies'); if (!o.name || !o.email || !o.password || !o.adminName) throw new Error('Fill in every field');
      if (db.users.some(u => u.email.toLowerCase() === o.email.toLowerCase())) throw new Error('That email already has an account');
      const c = { id: uid('c_'), name: o.name.trim(), createdAt: new Date().toISOString() }; db.companies.push(c);
      db.users.push({ id: uid('u_'), name: o.adminName.trim(), email: o.email.trim(), pw: await sha(o.password), role: 'admin', companyId: c.id, createdAt: c.createdAt });
      db.settings[c.id] = { labels: clone(LBL) }; db.stops[c.id] = { lib: [], counters: {} }; save(); return c; },
    async setCompanyLogo(logo) { const m = need(), c = cid(); if (m.role === 'super') throw new Error('Convoy Admin has view-only access to company data'); if (!m.perms.includes('users')) throw new Error('Only company admins can change the logo'); if (logo && (typeof logo !== 'string' || !/^data:image\/(png|jpeg|webp);base64,/.test(logo) || logo.length > 400000)) throw new Error('Logo must be a PNG, JPG or WebP under 300 KB'); const co = db.companies.find(x => x.id === c); co.logo = logo || null; save(); return { logo: co.logo }; },
    async switchCompany(id) { const m = need(); if (m.role !== 'super' && m.companyId !== id) throw new Error('Not allowed'); const s = sess(); s.companyId = id; s.schoolId = null; setSess(s); },
    async listUsers() { const c = cid(); return db.users.filter(u => u.companyId === c).map(pubUser); },
    async createUser(o) { const m = need(), c = cid(); if (m.role === 'user') throw new Error('Only admins can add users'); if (!o.name || !o.email || !o.password) throw new Error('Fill in name, email and password'); if (o.password.length < 8) throw new Error('Password needs at least 8 characters');
      if (db.users.some(u => u.email.toLowerCase() === o.email.toLowerCase())) throw new Error('That email already has an account');
      const perms = (o.perms || []).filter(p => ALL.includes(p)); const u = { id: uid('u_'), name: o.name.trim(), email: o.email.trim(), pw: await sha(o.password), role: perms.length === ALL.length ? 'admin' : 'user', perms, companyId: c, createdAt: new Date().toISOString() }; db.users.push(u); save(); return pubUser(u); },
    async updateUser(id, o) { const m = need(), c = cid(); if (!m.perms.includes('users')) throw new Error('You need the Users permission'); const u = db.users.find(x => x.id === id && x.companyId === c); if (!u) throw new Error('User not found'); const perms = (o.perms || []).filter(p => ALL.includes(p)); if (u.id === m.id && !perms.includes('users')) throw new Error('You cannot remove your own Users permission'); u.perms = perms; u.role = perms.length === ALL.length ? 'admin' : 'user'; save(); return pubUser(u); },
    async listAttendants() { const c = cid(); return db.attendants.filter(a => a.companyId === c); },
    async saveAttendant(o) { const c = cid(); if (!o.name) throw new Error('Name is required'); let a = o.id && db.attendants.find(x => x.id === o.id && x.companyId === c); if (!a) { a = { id: uid('a_'), companyId: c }; db.attendants.push(a); } Object.assign(a, { name: o.name.trim(), contact: o.contact || '', notes: o.notes || '' }); save(); return a; },
    async deleteAttendant(id) { const c = cid(); db.attendants = db.attendants.filter(a => !(a.id === id && a.companyId === c)); save(); },
    async getLabels(schoolId) { return db.labels[schoolId] || clone(LBL); },
    async saveLabels(schoolId, labels) { const c = cid(); if (!db.schools.some(s => s.id === schoolId && s.companyId === c)) throw new Error('School not found'); db.labels[schoolId] = labels; save(); return labels; },
    async listLibRequests() { const c = cid(), st = db.stops[c] || { lib: [] }; return (st.lib || []).filter(x => x.libStatus === 'pending').map(x => ({ uid: x.uid, id: x.id, name: x.name, school: (db.schools.find(s => s.id === x.ownerSchool) || {}).name || '', by: x.requestedBy || '', at: x.requestedAt || '' })); },
    async setStopStatus(uidS, status) { const c = cid(); if (!can('library')) throw new Error('You need the Stop Library permission'); const st = db.stops[c]; const x = st && st.lib.find(y => y.uid === uidS); if (!x) throw new Error('Stop not found'); x.libStatus = status; save(); },
    async listSchools() { const c = cid(); return db.schools.filter(s => s.companyId === c); },
    async saveSchool(o) { const c = cid(); if (!o.name) throw new Error('School name is required'); let s = o.id && db.schools.find(x => x.id === o.id && x.companyId === c);
      if (!s) { s = { id: uid('s_'), companyId: c, createdAt: new Date().toISOString() }; db.schools.push(s); }
      Object.assign(s, { name: o.name.trim(), short: o.short || '', address: o.address || '', postal: o.postal || '', lat: o.lat, lng: o.lng }); save(); return s; },
    async listDatasets(schoolId) { const c = cid(); if (!db.schools.some(s => s.id === schoolId && s.companyId === c)) return []; return db.datasets.filter(d => d.schoolId === schoolId).map(d => ({ id: d.id, schoolId, effectiveFrom: d.effectiveFrom, fileName: d.fileName, uploadedAt: d.uploadedAt, uploadedBy: d.uploadedBy, count: d.rows.length })).sort((a, b) => b.effectiveFrom.localeCompare(a.effectiveFrom)); },
    async uploadDataset(schoolId, o) { const m = need(), c = cid(); if (!db.schools.some(s => s.id === schoolId && s.companyId === c)) throw new Error('School not found');
      const d = { id: uid('d_'), schoolId, effectiveFrom: o.effectiveFrom, fileName: o.fileName || 'upload.csv', uploadedAt: new Date().toISOString(), uploadedBy: m.name, rows: o.rows }; db.datasets.push(d); save(); return { id: d.id, count: d.rows.length }; },
    async deleteDataset(id) { const c = cid(); const d = db.datasets.find(x => x.id === id); if (!d || !db.schools.some(s => s.id === d.schoolId && s.companyId === c)) return; db.datasets = db.datasets.filter(x => x.id !== id); save(); },
    async addRider(schoolId, r) { const c = cid(); if (!db.schools.some(s => s.id === schoolId && s.companyId === c)) throw new Error('School not found'); const row = Object.assign({ rid: uid('M-') }, r, { source: 'manual', schoolId, addedAt: new Date().toISOString() }); db.manual.push(row); save(); return row; },
    async ridersFor(schoolId, date) { const c = cid(); if (!db.schools.some(s => s.id === schoolId && s.companyId === c)) return { dataset: null, riders: [] };
      const D = date || today(), ds = db.datasets.filter(d => d.schoolId === schoolId && d.effectiveFrom <= D).sort((a, b) => b.effectiveFrom.localeCompare(a.effectiveFrom))[0];
      const inRange = r => (!r.start || r.start <= D) && (!r.end || r.end >= D);
      const rows = (ds ? ds.rows : []).map(r => ({ ...r, source: 'csv' })).concat(db.manual.filter(r => r.schoolId === schoolId)).filter(inRange);
      return { dataset: ds ? { id: ds.id, effectiveFrom: ds.effectiveFrom, fileName: ds.fileName } : null, riders: rows }; },
    async riderEvents(schoolId) { const c = cid(); if (!db.schools.some(s => s.id === schoolId && s.companyId === c)) return []; return riderEvents(db.datasets.filter(d => d.schoolId === schoolId), db.manual.filter(r => r.schoolId === schoolId)); },
    async listVehicles() { const c = cid(); return db.vehicles.filter(v => v.companyId === c); },
    async saveVehicle(o) { const c = cid(); if (!o.plate) throw new Error('Licence plate is required'); let v = o.id && db.vehicles.find(x => x.id === o.id && x.companyId === c); if (!v) { v = { id: uid('v_'), companyId: c }; db.vehicles.push(v); } Object.assign(v, o, { id: v.id, companyId: c, plate: o.plate.trim().toUpperCase() }); save(); return v; },
    async deleteVehicle(id) { const c = cid(); db.vehicles = db.vehicles.filter(v => !(v.id === id && v.companyId === c)); save(); },
    async listTrips() { const c = cid(); return (db.trips || []).filter(t => t.companyId === c); },
    async saveTrip(o) { const c = cid(); db.trips = db.trips || []; let t = o.id && db.trips.find(x => x.id === o.id && x.companyId === c); if (!t) { t = { id: o.id || uid('t_'), companyId: c }; db.trips.push(t); } Object.assign(t, o, { id: t.id, companyId: c }); save(); return t; },
    async deleteTrip(id) { const c = cid(); db.trips = (db.trips || []).filter(t => !(t.id === id && t.companyId === c)); save(); },
    async getSettings() { const c = cid(); return db.settings[c] || { labels: clone(LBL) }; },
    async saveSettings(o) { const c = cid(); db.settings[c] = Object.assign({}, db.settings[c] || {}, o); save(); return db.settings[c]; },
    async getStops() { const c = cid(); return db.stops[c] || { lib: [], counters: {} }; },
    async putStops(o) { const c = cid(); db.stops[c] = o; save(); },
    async getDraft(schoolId) { return (db.drafts || {})[schoolId] || null; },
    async putDraft(schoolId, o) { db.drafts = db.drafts || {}; db.drafts[schoolId] = o; save(); },
    async getPlans(schoolId) { return (db.plans || {})[schoolId] || []; },
    async putPlans(schoolId, plans) { db.plans = db.plans || {}; db.plans[schoolId] = plans; save(); }
  };

  // Convoy Admin (super) can open any company but only view it
  const RO = () => { const m = me(); return !!(m && m.role === 'super'); };
  ['saveSchool', 'saveVehicle', 'deleteVehicle', 'saveAttendant', 'deleteAttendant', 'saveSettings', 'saveLabels', 'uploadDataset', 'deleteDataset', 'addRider', 'setStopStatus', 'createUser', 'updateUser', 'putStops', 'saveTrip', 'deleteTrip'].forEach(k => { const f = local[k]; if (!f) return; local[k] = async function () { if (RO()) throw new Error('Convoy Admin has view-only access to company data'); return f.apply(this, arguments); }; });
  ['putDraft', 'putPlans'].forEach(k => { const f = local[k]; if (!f) return; local[k] = async function () { if (RO()) return; return f.apply(this, arguments); }; });

  // ---------------- server mode ----------------
  const call = async (method, path, body) => { const r = await fetch(API + path, { method, credentials: 'same-origin', headers: body ? { 'Content-Type': 'application/json' } : {}, body: body ? JSON.stringify(body) : undefined }); const t = await r.text(); const j = t ? JSON.parse(t) : null; if (!r.ok) throw new Error((j && j.error) || ('Request failed (' + r.status + ')')); return j; };
  const remote = {
    session: () => call('GET', '/session').catch(() => null), login: (email, password) => call('POST', '/login', { email, password }), logout: () => call('DELETE', '/logout'), setContext: o => call('POST', '/context', o),
    listCompanies: () => call('GET', '/companies'), createCompany: o => call('POST', '/companies', o), setCompanyLogo: logo => call('PUT', '/company/logo', { logo }), switchCompany: id => call('POST', '/context', { companyId: id, schoolId: null }),
    loginAs: kind => call('POST', '/login-as', { kind }), listUsers: () => call('GET', '/users'), createUser: o => call('POST', '/users', o), updateUser: (id, o) => call('PUT', '/users/' + id, o),
    listAttendants: () => call('GET', '/attendants'), saveAttendant: o => call('POST', '/attendants', o), deleteAttendant: id => call('DELETE', '/attendants/' + id),
    getLabels: sid => call('GET', '/schools/' + sid + '/labels'), saveLabels: (sid, l) => call('PUT', '/schools/' + sid + '/labels', l),
    listLibRequests: () => call('GET', '/library/requests'), setStopStatus: (uid, status) => call('POST', '/library/' + encodeURIComponent(uid) + '/status', { status }),
    listSchools: () => call('GET', '/schools'), saveSchool: o => call('POST', '/schools', o),
    listDatasets: sid => call('GET', '/schools/' + sid + '/datasets'), uploadDataset: (sid, o) => call('POST', '/schools/' + sid + '/datasets', o), deleteDataset: id => call('DELETE', '/datasets/' + id),
    addRider: (sid, r) => call('POST', '/schools/' + sid + '/riders', r), ridersFor: (sid, date) => call('GET', '/schools/' + sid + '/riders?date=' + encodeURIComponent(date || today())),
    riderEvents: sid => call('GET', '/schools/' + sid + '/rider-events'), listVehicles: () => call('GET', '/vehicles'), saveVehicle: o => call('POST', '/vehicles', o), deleteVehicle: id => call('DELETE', '/vehicles/' + id),
    listTrips: () => call('GET', '/trips'), saveTrip: t => call('POST', '/trips', t), deleteTrip: id => call('DELETE', '/trips/' + id),
    getSettings: () => call('GET', '/settings'), saveSettings: o => call('PUT', '/settings', o),
    getStops: () => call('GET', '/stops'), putStops: o => call('PUT', '/stops', o),
    getDraft: sid => call('GET', '/schools/' + sid + '/draft'), putDraft: (sid, o) => call('PUT', '/schools/' + sid + '/draft', o),
    getPlans: sid => call('GET', '/schools/' + sid + '/plans'), putPlans: (sid, p) => call('PUT', '/schools/' + sid + '/plans', p)
  };
  const B = remote;

  // ---------------- geocoding (OneMap) ----------------
  const geoCache = (() => { try { return JSON.parse(localStorage.getItem(GK) || '{}'); } catch (e) { return {}; } })();
  async function geocode(postal, address) {
    const k = postal || address; if (!k) return null; if (geoCache[k] !== undefined) return geoCache[k];
    try { const r = await fetch('https://www.onemap.gov.sg/api/common/elastic/search?searchVal=' + encodeURIComponent(k) + '&returnGeom=Y&getAddrDetails=Y&pageNum=1'); const j = await r.json(); const x = (j.results || []).find(y => !postal || y.POSTAL === postal) || null;
      const v = x ? { lat: +x.LATITUDE, lng: +x.LONGITUDE, address: [x.BLK_NO, x.ROAD_NAME].filter(Boolean).join(' ') } : null; geoCache[k] = v; try { localStorage.setItem(GK, JSON.stringify(geoCache)); } catch (e) {} return v; } catch (e) { return undefined; }
  }

  // ---------------- CSV ----------------
  const COLS = [['student_id', 'Student ID', ['id', 'studentid', 'student id']], ['student_name', 'Student Name', ['name', 'studentname', 'student name', 'name of child']], ['gender', 'Gender', ['sex']], ['grade_class', 'Grade/Class', ['grade', 'class', 'level', 'gradeclass', 'grade/class']],
    ['address', 'Address', ['home address']], ['postal_code', 'Postal Code', ['postal', 'postcode', 'postalcode']], ['am', 'AM', ['am pickup', 'morning']], ['pm', 'PM', ['pm dropoff', 'afternoon']], ['cca_days', 'CCA Days', ['cca', 'asa', 'asa/cca', 'cca days']],
    ['start_date', 'Start Date', ['start', 'from']], ['end_date', 'End Date', ['end', 'to']], ['parent_name', 'Parent Name', ['parent', 'guardian']], ['parent_contact', 'Parent Contact', ['contact', 'phone', 'parent phone']], ['remarks', 'Remarks', ['remark', 'notes']]];
  function parseCSV(text) {
    const rows = []; let row = [], f = '', q = false;
    for (let i = 0; i < text.length; i++) { const ch = text[i];
      if (q) { if (ch === '"') { if (text[i + 1] === '"') { f += '"'; i++; } else q = false; } else f += ch; }
      else if (ch === '"') q = true; else if (ch === ',') { row.push(f); f = ''; } else if (ch === '\n' || ch === '\r') { if (ch === '\r' && text[i + 1] === '\n') i++; row.push(f); rows.push(row); row = []; f = ''; } else f += ch; }
    if (f !== '' || row.length) { row.push(f); rows.push(row); }
    return rows.filter(r => r.some(c => String(c).trim() !== ''));
  }
  const yes = v => /^(y|yes|true|1|x|✓)$/i.test(String(v || '').trim());
  const normDate = v => { v = String(v || '').trim(); if (!v) return ''; let m = v.match(/^(\d{4})-(\d{1,2})-(\d{1,2})$/); if (m) return `${m[1]}-${m[2].padStart(2, '0')}-${m[3].padStart(2, '0')}`; m = v.match(/^(\d{1,2})[\/.-](\d{1,2})[\/.-](\d{4})$/); if (m) return `${m[3]}-${m[2].padStart(2, '0')}-${m[1].padStart(2, '0')}`; return 'bad'; };
  function readRiders(text) {
    const t = parseCSV(text.replace(/^\uFEFF/, '')); if (!t.length) return { rows: [], errors: [{ line: 0, msg: 'The file is empty' }], cols: [] };
    const head = t[0].map(h => h.trim().toLowerCase().replace(/[_\s]+/g, ' ')), map = {};
    COLS.forEach(([k, lbl, al]) => { const i = head.findIndex(h => h === k.replace(/_/g, ' ') || h === lbl.toLowerCase() || al.includes(h)); if (i >= 0) map[k] = i; });
    const errors = [], rows = [];
    ['student_name', 'address', 'postal_code'].forEach(k => { if (map[k] == null) errors.push({ line: 1, msg: `Missing column "${COLS.find(c => c[0] === k)[1]}"` }); });
    if (errors.length) return { rows, errors, cols: Object.keys(map) };
    t.slice(1).forEach((c, i) => { const g = k => map[k] == null ? '' : String(c[map[k]] || '').trim(), line = i + 2;
      const postal = g('postal_code').replace(/\D/g, '').padStart(6, '0'), r = { rid: g('student_id') || 'S-' + String(line).padStart(4, '0'), name: g('student_name'), gender: g('gender'), grade: g('grade_class'), address: g('address'), postal,
        am: map.am == null ? true : yes(g('am')), pm: map.pm == null ? true : yes(g('pm')), cca: g('cca_days'), start: normDate(g('start_date')), end: normDate(g('end_date')), parentName: g('parent_name'), parentContact: g('parent_contact'), remarks: g('remarks') };
      const e = []; if (!r.name) e.push('no student name'); if (!/^\d{6}$/.test(postal) || postal === '000000') e.push('postal code must be 6 digits'); if (r.start === 'bad' || r.end === 'bad') e.push('dates must be YYYY-MM-DD or DD/MM/YYYY'); if (r.start && r.end && r.start !== 'bad' && r.end !== 'bad' && r.end < r.start) e.push('end date is before start date'); if (!r.am && !r.pm && !r.cca) e.push('no session (AM, PM or CCA days)');
      if (e.length) errors.push({ line, msg: `${r.name || 'Row ' + line}: ${e.join(', ')}` }); else rows.push(r); });
    const dup = {}; rows.forEach(r => { dup[r.rid] = (dup[r.rid] || 0) + 1; }); Object.keys(dup).filter(k => dup[k] > 1).forEach(k => errors.push({ line: 0, msg: `Student ID ${k} appears ${dup[k]} times` }));
    return { rows, errors, cols: Object.keys(map) };
  }
  const README = [
    ['student_id', 'Optional', 'Your own ID for the student. Keep it the same in every upload so changes are matched. Generated if empty.', 'S-1001'],
    ['student_name', 'Required', 'Full name as it should appear on route sheets.', 'Tan Wei Ling'],
    ['gender', 'Optional', 'F or M.', 'F'],
    ['grade_class', 'Optional', 'Level or class.', 'Sec 1A'],
    ['address', 'Required', 'Street address. Block, street and unit or building name.', '20 Siglap View'],
    ['postal_code', 'Required', '6-digit Singapore postal code. Used to place the home on the map.', '455789'],
    ['am', 'Optional', 'Y if the student takes the morning bus to school. Empty column = Y for everyone.', 'Y'],
    ['pm', 'Optional', 'Y if the student takes the afternoon bus home. Empty column = Y for everyone.', 'Y'],
    ['cca_days', 'Optional', 'Days the student needs the CCA / after-school bus, separated by ; . Leave empty if none.', 'Mon;Wed'],
    ['start_date', 'Optional', 'First day on the bus, YYYY-MM-DD or DD/MM/YYYY. Empty = from the dataset Effective From date.', '2026-01-02'],
    ['end_date', 'Optional', 'Last day on the bus. Empty = no end date.', '2026-11-20'],
    ['parent_name', 'Optional', 'Shown on the driver route sheet.', 'Tan Ah Kow'],
    ['parent_contact', 'Optional', 'Phone number for the driver and attendant.', '91234567'],
    ['remarks', 'Optional', 'Notes for the driver, e.g. gate or special days.', 'Gate B']];
  function templateXlsx() {
    const H = x => ({ v: x, s: 'h' }), C = x => ({ v: x, s: 'c' });
    const riders = { name: 'Riders', widths: [12, 24, 8, 12, 34, 12, 6, 6, 12, 12, 12, 20, 14, 20], rows: [COLS.map(c => H(c[0])), ['S-1001', 'Tan Wei Ling', 'F', 'Sec 1A', '20 Siglap View', '455789', 'Y', 'Y', 'Mon;Wed', '2026-01-02', '', 'Tan Ah Kow', '91234567', 'Gate B'].map(C)] };
    const how = { name: 'Read Me', widths: [18, 11, 80, 18], rows: [[{ v: 'How to fill in the rider file', s: 'title' }], [],
      ['1. Fill in one row per student on the Riders sheet. Keep the header row as it is.'], ['2. Save the Riders sheet as CSV (File > Save As > CSV UTF-8).'], ['3. In Schools > the school > Rider Data, pick the Effective From date and upload the CSV.'], ['4. When ridership changes, upload the full list again with a later Effective From date. The old list is used until that date.'], [],
      ['Column', 'Required', 'What to put', 'Example'].map(H)].concat(README.map(r => r.map(C))) };
    return [riders, how];
  }
  const TEMPLATE = COLS.map(c => c[0]).join(',') + '\n' + 'S-1001,Tan Wei Ling,F,Sec 1A,"20 Siglap View",455789,Y,Y,Mon;Wed,2026-01-02,,Tan Ah Kow,91234567,Gate B\n';

  // ---------------- page data (VS_DATA) ----------------
  const cache = { plans: [], draft: null };
  async function build() {
    const s = await B.session(); window.SA.sess = s;
    if (!s || !s.user.companyId) { window.VS_DATA = emptyData(null); return s; }
    const schools = await B.listSchools(); window.SA.schools = schools;
    let school = schools.find(x => x.id === s.schoolId) || schools[0] || null;
    if (school && school.id !== s.schoolId) { await B.setContext({ schoolId: school.id }); s.schoolId = school.id; }
    const st = await B.getStops(); window.SA.stopStore = st;
    if (!school) { window.VS_DATA = emptyData(null, st); return s; }
    const R = await B.ridersFor(school.id, s.date); window.SA.dataset = R.dataset;
    cache.plans = (await B.getPlans(school.id)) || []; cache.draft = await B.getDraft(school.id); window.SA.labels = await B.getLabels(school.id);
    const riders = R.riders.map(r => ({ rid: r.rid, name: r.name, postal: r.postal, address: r.address, lat: r.lat == null ? null : r.lat, lng: r.lng == null ? null : r.lng, level: r.grade || '', gender: r.gender, sessions: { AM: r.am !== false, PM: r.pm !== false, ASA: r.cca || '' }, start: r.start || '', end: r.end || '', parentName: r.parentName, parentContact: r.parentContact, remarks: r.remarks, addrStatus: r.lat == null ? 'POSTAL_NOT_FOUND' : r.addrStatus }));
    const lib = (st.lib || []).filter(x => !x.libStatus || x.libStatus === 'approved' || x.ownerSchool === school.id).map(x => { const o = clone(x), b = (x.bySchool || {})[school.id] || {}; o.postalCodes = b.postalCodes || []; o.areas = b.areas || []; o.off = b.off || []; delete o.bySchool; return o; });
    window.VS_DATA = Object.assign(emptyData(school, st), { riders, stops: lib, counters: st.counters || {}, rev: 'sa-' + school.id });
    return s;
  }
  function emptyData(school, st) {
    const base = SEED ? { subzones: SEED.subzones, planningAreas: SEED.planningAreas, regions: SEED.regions } : {};
    const sc = school ? { name: school.name, short: school.short || school.name.split(' ').map(w => w[0]).join('').slice(0, 4).toUpperCase(), lat: school.lat, lng: school.lng, address: school.address } : { name: 'No school yet', short: '', lat: 1.3521, lng: 103.8198, address: '' };
    return Object.assign({}, SEED || {}, base, { school: sc, riders: [], stops: [], counters: (st && st.counters) || {}, rev: 'sa-empty' });
  }
  // stop library edits from the page (catchments stored per school)
  let saveT = null;
  function saveDraft(o) {
    const s = window.SA.sess; if (!s || !s.schoolId) return; clearTimeout(saveT);
    saveT = setTimeout(async () => {
      const sid = s.schoolId, cur = window.SA.stopStore || { lib: [] }, prev = {}; (cur.lib || []).forEach(x => { prev[x.uid] = x; });
      const lib = (o.lib || []).map(x => { const y = clone(x), mine = (y.bySchool || {}).sch1 || { postalCodes: y.postalCodes || [], areas: y.areas || [], off: y.off || [] }; const other = Object.assign({}, (prev[y.uid] || {}).bySchool || {}); other[sid] = mine; y.bySchool = other; delete y.postalCodes; delete y.areas; delete y.off; return y; });
      const seen = new Set(lib.map(x => x.uid)); (cur.lib || []).forEach(x => { if (!seen.has(x.uid)) lib.push(x); });
      const store = { lib, counters: o.counters || cur.counters || {} }; window.SA.stopStore = store;
      try { await B.putStops(store); await B.putDraft(sid, { links: o.links || null, at: o.at }); } catch (e) { console.warn('Saving stops failed', e); }
    }, 500);
  }
  let planT = null;
  function savePlans(plans) { const s = window.SA.sess; if (!s || !s.schoolId) return; cache.plans = plans; clearTimeout(planT); planT = setTimeout(() => B.putPlans(s.schoolId, plans).catch(e => console.warn('Saving plans failed', e)), 800); }
  function routeLabel(settings, session, n) { const L = ((settings && settings.labels) || window.SA.labels || LBL)[session] || LBL.AM, num = (+L.start || 1) + n - 1; return (L.prefix || '') + (L.digits ? String(num).padStart(+L.digits, '0') : String(num)) + (L.suffix || ''); }

  window.SA = { api: B, mode: API ? 'server' : 'local', demoLogin: !API || !!CFG.demoLogin, PERMS, templateXlsx, README, today, build, geocode, readRiders, parseCSV, TEMPLATE, COLS, saveDraft, savePlans, routeLabel, cachedPlans: () => cache.plans, cachedDraft: () => cache.draft, LBL };
  window.SA.ready = build().then(s => { window.SA.settings = null; if (s && s.user.companyId) return B.getSettings().then(x => { window.SA.settings = x; return s; }).catch(() => s); return s; }).catch(e => { console.error('SA boot failed', e); window.VS_DATA = emptyData(null); });
})();
