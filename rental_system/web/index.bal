
public const string INDEX_HTML = string `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Rental Accommodations · Ministry of Tourism</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
      <link href="https://fonts.googleapis.com/css2?family=Fraunces:opsz,wght@9..144,400;9..144,500;9..144,600&family=IBM+Plex+Sans:wght@400;500;600&display=swap" rel="stylesheet">
<style>
  :root {
    --bg: #f7f2e6;
    --ink: #23201a;
    --ink-soft: #57503f;
    --line: #ddd0af;
    --pine: #1f4a42;
    --pine-dark: #163934;
    --ochre: #b8722e;
    --ochre-dark: #96591f;
    --sage: #6e7a5c;
    --clay: #a6432d;
    --paper: #fffdf7;
  }
  * { box-sizing: border-box; }
  body {
    margin: 0;
    background: var(--bg);
    color: var(--ink);
    font-family: 'IBM Plex Sans', sans-serif;
    font-size: 15px;
    line-height: 1.5;
  }
  h1, h2, h3 { font-family: 'Fraunces', serif; font-weight: 500; margin: 0; }
  .topbar {
    display: flex;
    justify-content: space-between;
    align-items: flex-end;
    padding: 28px 40px 20px;
    border-bottom: 1px solid var(--line);
  }
          .wordmark h1 { font-size: 28px; color: var(--pine-dark); letter-spacing: -0.01em; }
          .wordmark p { margin: 4px 0 0; color: var(--ink-soft); font-size: 14px; }
          .role-toggle { display: flex; border: 1px solid var(--pine); border-radius: 999px; overflow: hidden; }
  .role-toggle button {
      border: none; background: transparent; color: var(--pine);
      padding: 9px 22px; font-family: 'IBM Plex Sans', sans-serif; font-size: 14px;
      font-weight: 500; cursor: pointer; transition: background .15s, color .15s;
  }
  .role-toggle button.active { background: var(--pine); color: var(--paper); }

  .idbar {
      display: flex; align-items: center; gap: 14px;
      padding: 16px 40px; background: var(--paper); border-bottom: 1px solid var(--line);
      flex-wrap: wrap;
  }
  .idbar label { font-size: 13px; color: var(--ink-soft); }
  .idbar input {
      font-family: 'IBM Plex Sans', sans-serif; font-size: 14px;
   padding: 8px 12px; border: 1px solid var(--line); border-radius: 6px;
       background: var(--bg); color: var(--ink); min-width: 200px;
   }
  .idbar button.linklike {
    background: none; border: none; color: var(--pine); text-decoration: underline;
    font-size: 13px; cursor: pointer; padding: 0; font-family: 'IBM Plex Sans', sans-serif;
  }
  #registerPanel {
      width: 100%; display: flex; gap: 10px; align-items: center; flex-wrap: wrap;
    padding-top: 12px; margin-top: 4px; border-top: 1px dashed var(--line);
  }
  #registerPanel input, #registerPanel select {
    font-family: 'IBM Plex Sans', sans-serif; font-size: 13px;
    padding: 7px 10px; border: 1px solid var(--line); border-radius: 6px;
  }

  main { display: grid; grid-template-columns: 300px 1fr; gap: 28px; padding: 28px 40px 60px; }
  @media (max-width: 800px) { main { grid-template-columns: 1fr; } }

  .panel { background: var(--paper); border: 1px solid var(--line); border-radius: 10px; padding: 22px; height: fit-content; }
  .panel h2 { font-size: 18px; margin-bottom: 14px; }
  .panel h2.second { margin-top: 26px; }
  .panel form { display: flex; flex-direction: column; gap: 10px; }
  .panel label { font-size: 12px; color: var(--ink-soft); }
  .panel input, .panel select, .panel textarea {
    font-family: 'IBM Plex Sans', sans-serif; font-size: 14px;
    padding: 9px 11px; border: 1px solid var(--line); border-radius: 6px;
    background: var(--bg); width: 100%;
  }
  .panel textarea { resize: vertical; min-height: 56px; }
  .btn {
    font-family: 'IBM Plex Sans', sans-serif; font-size: 14px; font-weight: 500;
    padding: 10px 16px; border-radius: 6px; border: none; cursor: pointer;
    transition: opacity .15s;
  }
  .btn:hover { opacity: .88; }
  .btn-primary { background: var(--ochre); color: var(--paper); }
  .btn-pine { background: var(--pine); color: var(--paper); }
  .btn-outline { background: transparent; border: 1px solid var(--line); color: var(--ink); }
  .btn-danger { background: transparent; border: 1px solid var(--clay); color: var(--clay); }

  .listing h2 { font-size: 20px; margin-bottom: 16px; }
  .row {
    background: var(--paper); border: 1px solid var(--line); border-left: 4px solid var(--sage);
    border-radius: 6px; padding: 16px 18px; margin-bottom: 12px;
  }
  .row.status-AVAILABLE { border-left-color: #3f7d5c; }
  .row.status-OCCUPIED { border-left-color: var(--ochre); }
  .row.status-UNAVAILABLE { border-left-color: var(--ink-soft); }
  .row-top { display: flex; justify-content: space-between; align-items: baseline; gap: 12px; flex-wrap: wrap; }
  .row-top h3 { font-size: 17px; }
  .row-meta { color: var(--ink-soft); font-size: 13px; margin-top: 2px; }
  .row-price { font-family: 'Fraunces', serif; font-size: 18px; color: var(--pine-dark); white-space: nowrap; }
  .pill {
    display: inline-block; font-size: 11px; padding: 3px 9px; border-radius: 999px;
    background: var(--bg); border: 1px solid var(--line); color: var(--ink-soft); margin-left: 8px;
  }
  .row-desc { margin-top: 8px; font-size: 13px; color: var(--ink-soft); }
  .row-actions { margin-top: 12px; display: flex; gap: 10px; flex-wrap: wrap; align-items: center; }
  .row-expand { margin-top: 12px; padding-top: 12px; border-top: 1px dashed var(--line); display: none; gap: 10px; flex-wrap: wrap; align-items: flex-end; }
  .row-expand.open { display: flex; }
  .row-expand label { font-size: 12px; color: var(--ink-soft); display: block; margin-bottom: 4px; }
  .row-expand input { font-family: 'IBM Plex Sans', sans-serif; padding: 7px 9px; border: 1px solid var(--line); border-radius: 6px; }
  .empty { color: var(--ink-soft); font-style: italic; padding: 20px 0; }
  .feedback { margin-top: 8px; font-size: 13px; }
  .feedback.ok { color: #2f6b4c; }
  .feedback.err { color: var(--clay); }
</style>
</head>
<body>

<header class="topbar">
  <div class="wordmark">
    <h1>Rental Accommodations</h1>
    <p>Ministry of Tourism — short-term stays across the regions</p>
  </div>
  <div class="role-toggle">
    <button data-role="guest" class="active">Guest</button>
    <button data-role="host">Host</button>
  </div>
</header>

<section class="idbar">
  <label id="idLabel" for="userId">Your Guest ID</label>
  <input id="userId" placeholder="e.g. USR-GUEST01" value="USR-GUEST01">
  <button class="linklike" id="toggleRegister">New here? Register</button>
  <div id="registerPanel" hidden>
    <input id="regName" placeholder="Full name">
    <input id="regEmail" placeholder="Email">
    <select id="regRole"><option value="GUEST">Guest</option><option value="HOST">Host</option></select>
    <button class="btn btn-pine" id="regSubmit">Register</button>
    <span id="regFeedback" class="feedback"></span>
  </div>
</section>

<main>
  <!HOST VIEW>
  <div id="hostView" style="display:none; display: contents;">
    <aside class="panel">
      <h2>List a property</h2>
      <form id="addPropertyForm">
        <div><label>Name</label><input name="name" required></div>
            <div><label>Location</label><input name="location" required></div>
        <div><label>Type</label><input name="propertyType" placeholder="Apartment, Cabin, Loft…" required></div>
            <div><label>Price per night (N$)</label><input name="pricePerNight" type="number" step="0.01" min="0" required></div>
            <div><label>Description</label><textarea name="description"></textarea></div>
        <button class="btn btn-primary" type="submit">List property</button>
        <span id="addFeedback" class="feedback"></span>
      </form>
    </aside>
    <div class="listing">
      <h2>Your properties</h2>
      <div id="hostProperties"></div>
    </div>
  </div>

  <GUEST VIEW>
  <div id="guestView">
    <aside class="panel">
      <h2>Find a stay</h2>
      <form id="filterForm">
        <div><label>Location</label><input name="location" placeholder="Any"></div>
              <div><label>Min price</label><input name="minPrice" type="number" step="0.01" min="0"></div>
          <div><label>Max price</label><input name="maxPrice" type="number" step="0.01" min="0"></div>
              <button class="btn btn-primary" type="submit">Search</button>
            </form>
      <h2 class="second">Look up by ID</h2>
      <form id="lookupForm">
        <div><label>Property ID</label><input name="propertyId" placeholder="PROP-xxxxxxxx"></div>
            <button class="btn btn-outline" type="submit">Look up</button>
      </form>
  </aside>
    <div class="listing">
      <h2>Available properties</h2>
      <div id="guestProperties"></div>
    </div>
  </div>
</main>

<script>
  const state = { role: 'guest' };
  const $ = (sel, root) => (root || document).querySelector(sel);
  const $$ = (sel, root) => Array.from((root || document).querySelectorAll(sel));

  function fmtMoney(n) { return 'N$' + Number(n).toFixed(2); }

  async function api(path, options) {
    const res = await fetch(path, Object.assign({ headers: { 'Content-Type': 'application/json' } }, options || {}));
    let body = null;
    try { body = await res.json(); } catch (e) {}
    if (!res.ok) throw new Error((body && body.message) || ('Request failed (' + res.status + ')'));
    return body;
  }

  //role toggle 
 $$('.role-toggle button').forEach(btn => {
    btn.addEventListener('click', () => {
         state.role = btn.dataset.role;
      $$('.role-toggle button').forEach(b => b.classList.toggle('active', b === btn));
          $('#hostView').style.display = state.role === 'host' ? 'contents' : 'none';
            $('#guestView').style.display = state.role === 'guest' ? 'contents' : 'none';
            $('#idLabel').textContent = state.role === 'host' ? 'Your Host ID' : 'Your Guest ID';
    $('#userId').value = state.role === 'host' ? 'USR-HOST01' : 'USR-GUEST01';
      $('#regRole').value = state.role === 'host' ? 'HOST' : 'GUEST';
      refresh();
    });
  });

  $('#toggleRegister').addEventListener('click', () => {
    const p = $('#registerPanel');
    p.hidden = !p.hidden;
  });

  $('#regSubmit').addEventListener('click', async () => {
    const fb = $('#regFeedback');
    fb.textContent = ''; fb.className = 'feedback';
    try {
      const result = await api('/api/users', {
        method: 'POST',
        body: JSON.stringify({ name: $('#regName').value, email: $('#regEmail').value, role: $('#regRole').value })
      });
      const newId = (result.userIds && result.userIds[0]) || '?';
    fb.textContent = 'Registered! Your ID: ' + newId;
      fb.className = 'feedback ok';
    $('#userId').value = newId;
    } catch (e) {
      fb.textContent = e.message;
      fb.className = 'feedback err';
    }
  });

  // property row rendering 
  function propertyRow(p, mode) {
    const row = document.createElement('div');
    row.className = 'row status-' + p.status;
    row.innerHTML =
      '<div class="row-top">' +
            '<div><h3>' + p.name + '<span class="pill">' + p.status + '</span></h3>' +
            '<div class="row-meta">' + p.location + ' · ' + p.propertyType + ' · #' + p.propertyId + '</div></div>' +
            '<div class="row-price">' + fmtMoney(p.pricePerNight) + '<span style="font-size:12px;color:var(--ink-soft)">/night</span></div>' +
      '</div>' +
    (p.description ? '<div class="row-desc">' + p.description + '</div>' : '') +
   '<div class="row-actions"></div>' +
   '<div class="row-expand"></div>';

    const actions = row.querySelector('.row-actions');
    const expand = row.querySelector('.row-expand');

    if (mode === 'host') {
      const editBtn = document.createElement('button');
      editBtn.className = 'btn btn-outline';
    editBtn.textContent = 'Update';
   editBtn.onclick = () => expand.classList.toggle('open');
      const delBtn = document.createElement('button');
          delBtn.className = 'btn btn-danger';
          delBtn.textContent = 'Remove';
          delBtn.onclick = () => removeProperty(p.propertyId);
      actions.append(editBtn, delBtn);

      expand.innerHTML =
        '<div><label>New price</label><input class="upPrice" type="number" step="0.01" placeholder="' + p.pricePerNight + '"></div>' +
        '<div><label>New status</label><select class="upStatus">' +
          '<option value="">unchanged</option><option value="AVAILABLE">AVAILABLE</option>' +
              '<option value="OCCUPIED">OCCUPIED</option><option value="UNAVAILABLE">UNAVAILABLE</option>' +
            '</select></div>';
      const saveBtn = document.createElement('button');
         saveBtn.className = 'btn btn-primary';
          saveBtn.textContent = 'Save';
          saveBtn.onclick = () => updateProperty(p.propertyId, expand);
          expand.appendChild(saveBtn);
    }

    if (mode === 'guest') {
      const bookBtn = document.createElement('button');
       bookBtn.className = 'btn btn-primary';
          bookBtn.textContent = 'Book';
          bookBtn.disabled = p.status !== 'AVAILABLE';
            bookBtn.onclick = () => expand.classList.toggle('open');
      actions.appendChild(bookBtn);

      expand.innerHTML =
        '<div><label>Check-in</label><input class="ciDate" type="date"></div>' +
    '<div><label>Check-out</label><input class="coDate" type="date"></div>';
        const reqBtn = document.createElement('button');
              reqBtn.className = 'btn btn-pine';
              reqBtn.textContent = 'Request booking';
              reqBtn.onclick = () => requestBooking(p.propertyId, expand);
              expand.appendChild(reqBtn);
      const fb = document.createElement('div');
           fb.className = 'feedback';
      expand.appendChild(fb);
    }

    return row;
  }

  //host actions
  async function loadHostProperties() {
    const hostId = $('#userId').value.trim();
                const container = $('#hostProperties');
                container.innerHTML = '';
    if (!hostId) { container.innerHTML = '<div class="empty">Enter a Host ID above to see your listings.</div>'; return; }
    try {
     const props = await api('/api/properties/host/' + encodeURIComponent(hostId));
          if (!props.length) { container.innerHTML = '<div class="empty">No properties yet — list your first one.</div>'; return; }
          props.forEach(p => container.appendChild(propertyRow(p, 'host')));
    } catch (e) {
           container.innerHTML = '<div class="feedback err">' + e.message + '</div>';
    }
  }

  $('#addPropertyForm').addEventListener('submit', async (ev) => {
    ev.preventDefault();
    const fd = new FormData(ev.target);
    const fb = $('#addFeedback');
    fb.textContent = ''; fb.className = 'feedback';
    try {
      const result = await api('/api/properties', {
        method: 'POST',
          body: JSON.stringify({
          hostId: $('#userId').value.trim(),
              name: fd.get('name'),
              location: fd.get('location'),
              propertyType: fd.get('propertyType'),
          pricePerNight: parseFloat(fd.get('pricePerNight')),
          status: 'AVAILABLE',
                description: fd.get('description') || ''
        })
      });
      if (result.success) {
        fb.textContent = 'Listed: ' + result.property.propertyId;
              fb.className = 'feedback ok';
              ev.target.reset();
              loadHostProperties();
            } else {
              fb.textContent = result.message; fb.className = 'feedback err';
            }
    } catch (e) {
      fb.textContent = e.message; fb.className = 'feedback err';
    }
  });

  async function updateProperty(propertyId, expandEl) {
        const price = expandEl.querySelector('.upPrice').value;
        const status = expandEl.querySelector('.upStatus').value;
              const body = { propertyId: propertyId, hostId: $('#userId').value.trim() };
          if (price) body.pricePerNight = parseFloat(price);
          if (status) body.status = status;
          try {
      const result = await api('/api/properties/' + encodeURIComponent(propertyId), {
        method: 'PUT', body: JSON.stringify(body)
      });
      if (!result.success) throw new Error(result.message);
            loadHostProperties();
    } catch (e) { alert(e.message); }
  }

  async function removeProperty(propertyId) {
    if (!confirm('Remove this property?')) return;
          try {
            const hostId = $('#userId').value.trim();
            const result = await api('/api/properties/' + encodeURIComponent(propertyId) + '?hostId=' + encodeURIComponent(hostId), {
              method: 'DELETE'
            });
            if (!result.success) throw new Error(result.message);
      loadHostProperties();
    } catch (e) { alert(e.message); }
  }

  // guest actions
  async function loadGuestProperties(params) {
    const container = $('#guestProperties');
    container.innerHTML = '';
    const qs = new URLSearchParams();
    if (params && params.location) qs.set('location', params.location);
    if (params && params.minPrice) qs.set('minPrice', params.minPrice);
    if (params && params.maxPrice) qs.set('maxPrice', params.maxPrice);
    try {
      const props = await api('/api/properties/available' + (qs.toString() ? '?' + qs.toString() : ''));
      if (!props.length) { container.innerHTML = '<div class="empty">No properties match those filters.</div>'; return; }
      props.forEach(p => container.appendChild(propertyRow(p, 'guest')));
    } catch (e) {
      container.innerHTML = '<div class="feedback err">' + e.message + '</div>';
    }
  }

      $('#filterForm').addEventListener('submit', (ev) => {
        ev.preventDefault();
        const fd = new FormData(ev.target);
        loadGuestProperties({ location: fd.get('location'), minPrice: fd.get('minPrice'), maxPrice: fd.get('maxPrice') });
  });

  $('#lookupForm').addEventListener('submit', async (ev) => {
    ev.preventDefault();
    const id = new FormData(ev.target).get('propertyId').trim();
    const container = $('#guestProperties');
    container.innerHTML = '';
    if (!id) return;
    try {
      const result = await api('/api/properties/' + encodeURIComponent(id));
      if (!result.found) { container.innerHTML = '<div class="empty">' + result.status + '</div>'; return; }
      container.appendChild(propertyRow(result.property, 'guest'));
    } catch (e) {
      container.innerHTML = '<div class="feedback err">' + e.message + '</div>';
    }
  });

  async function requestBooking(propertyId, expandEl) {
    const checkIn = expandEl.querySelector('.ciDate').value;
    const checkOut = expandEl.querySelector('.coDate').value;
    const fb = expandEl.querySelector('.feedback');
    fb.textContent = ''; fb.className = 'feedback';
    if (!checkIn || !checkOut) { fb.textContent = 'Pick both dates.'; fb.className = 'feedback err'; return; }
    try {
      const result = await api('/api/bookings', {
        method: 'POST',
        body: JSON.stringify({ propertyId: propertyId, guestId: $('#userId').value.trim(), checkIn: checkIn, checkOut: checkOut })
      });
      if (!result.success) { fb.textContent = result.message; fb.className = 'feedback err'; return; }
      fb.innerHTML = 'Request ' + result.requestId + ' — <button class="btn btn-pine" style="padding:4px 10px;font-size:12px">Confirm now</button>';
      fb.className = 'feedback ok';
      fb.querySelector('button').onclick = () => confirmBooking(result.requestId, fb);
    } catch (e) {
      fb.textContent = e.message; fb.className = 'feedback err';
    }
  }

  async function confirmBooking(requestId, fb) {
    try {
      const result = await api('/api/bookings/confirm', {
        method: 'POST',
        body: JSON.stringify({ requestId: requestId, guestId: $('#userId').value.trim() })
      });
      if (!result.success) { fb.textContent = result.message; fb.className = 'feedback err'; return; }
      fb.textContent = 'Confirmed: ' + result.bookingId + ' · ' + result.nights + ' nights · ' + fmtMoney(result.totalCost);
      fb.className = 'feedback ok';
      loadGuestProperties();
    } catch (e) { fb.textContent = e.message; fb.className = 'feedback err'; }
  }

  function refresh() {
    if (state.role === 'host') loadHostProperties(); else loadGuestProperties();
  }

  $('#guestView').style.display = 'contents';
  $('#hostView').style.display = 'none';
  refresh();
</script>
</body>
</html>
`;
