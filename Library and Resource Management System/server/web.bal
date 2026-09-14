import ballerina/http;

// Web interface for the Ministry Library and Resource Management System (bonus).
// A single-page dashboard served at http://localhost:8090/ that talks to the
// REST API at /ministry/api from browser JavaScript.

string DASHBOARD_HTML = string `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Ministry Library &amp; Resource Management</title>
<style>
  :root {
    --paper:#f7f2e9; --card:#fffdf8; --ink:#2b2118; --ink-soft:#6b5d4f;
    --line:#e3d9c6; --green:#1f4d3a; --green-dark:#153528; --gold:#c98a2d;
    --gold-soft:#f3e3c3; --red:#a4342a; --amber:#9a6b1f;
  }
  * { box-sizing:border-box; }
  body {
    font-family:Georgia,"Times New Roman",serif; margin:0;
    background:var(--paper); color:var(--ink);
  }
  /* faint paper grain */
  body::before {
    content:""; position:fixed; inset:0; pointer-events:none; opacity:.4;
    background-image:radial-gradient(#d8ccb4 1px, transparent 1px);
    background-size:22px 22px;
  }
  header {
    background:var(--green); color:#f5efdf; padding:26px 32px 22px;
    border-bottom:4px solid var(--gold); position:relative;
  }
  header h1 { margin:0; font-size:26px; font-weight:normal; letter-spacing:.02em; }
  header h1 .crest { color:var(--gold); margin-right:10px; }
  header p { margin:6px 0 0; font-size:13.5px; font-style:italic; opacity:.85; }
  nav {
    display:flex; gap:4px; flex-wrap:wrap; padding:0 32px;
    background:var(--green-dark); border-bottom:1px solid var(--gold);
  }
  nav button {
    font-family:inherit; font-size:14px; letter-spacing:.03em;
    background:transparent; color:#d9cfb8; border:none;
    padding:13px 20px 11px; cursor:pointer; border-bottom:3px solid transparent;
  }
  nav button:hover { color:#fff; }
  nav button.active { color:var(--gold-soft); border-bottom-color:var(--gold); }
  main { padding:26px 32px 60px; max-width:1180px; margin:0 auto; position:relative; }
  .toolbar { display:flex; gap:10px; flex-wrap:wrap; margin-bottom:18px; align-items:center; }
  .toolbar input, .toolbar select, dialog input, dialog select {
    font-family:inherit; font-size:14px; color:var(--ink);
    padding:8px 12px; border:1px solid var(--line); border-radius:3px; background:#fff;
  }
  .toolbar input:focus, .toolbar select:focus, dialog input:focus, dialog select:focus {
    outline:2px solid var(--gold); outline-offset:1px;
  }
  .toolbar button.primary, dialog button.primary {
    font-family:inherit; font-size:14px; letter-spacing:.03em;
    background:var(--green); color:#f5efdf; border:none; padding:9px 18px;
    border-radius:3px; cursor:pointer; box-shadow:0 2px 0 var(--green-dark);
  }
  .toolbar button.primary:hover, dialog button.primary:hover { background:var(--green-dark); }
  .toolbar button.primary:active, dialog button.primary:active { transform:translateY(1px); box-shadow:none; }
  .toolbar button.ghost {
    font-family:inherit; font-size:14px; background:transparent;
    border:1px solid var(--line); border-radius:3px; padding:9px 16px;
    cursor:pointer; color:var(--ink-soft);
  }
  .cards { display:grid; grid-template-columns:repeat(auto-fill,minmax(330px,1fr)); gap:16px; }
  .card {
    background:var(--card); border:1px solid var(--line); border-radius:4px;
    padding:16px 18px; box-shadow:0 1px 3px rgba(90,70,40,.12);
    border-top:3px solid var(--gold);
  }
  .card:hover { box-shadow:0 3px 10px rgba(90,70,40,.18); }
  .card h3 { margin:0 0 2px; font-size:17px; font-weight:normal; }
  .card .tag {
    font-family:Verdana,Geneva,sans-serif; font-size:10.5px; color:var(--ink-soft);
    letter-spacing:.05em; text-transform:uppercase; margin-bottom:10px;
  }
  .badge {
    display:inline-block; padding:2px 10px; border-radius:2px; vertical-align:2px;
    font-family:Verdana,Geneva,sans-serif; font-size:9.5px; font-weight:bold;
    letter-spacing:.08em; text-transform:uppercase;
  }
  .badge.AVAILABLE { background:#e4efe3; color:#2f5e33; border:1px solid #b9d4b8; }
  .badge.LOANED_OUT, .badge.OCCUPIED { background:var(--gold-soft); color:var(--amber); border:1px solid #dcc187; }
  .badge.UNDER_MAINTENANCE { background:#f6e0dd; color:var(--red); border:1px solid #dcaaa3; }
  .badge.DISPOSED { background:#eae5da; color:#7a6f60; border:1px solid #cfc4ae; }
  .card dl { margin:10px 0 0; font-size:13px; }
  .card dt {
    font-family:Verdana,Geneva,sans-serif; font-size:10px; font-weight:bold;
    letter-spacing:.08em; text-transform:uppercase; color:var(--ink-soft); margin-top:8px;
  }
  .card dd { margin:3px 0 0 0; color:#4a4036; }
  .card ul { margin:0 0 0 16px; padding:0; font-size:12.5px; }
  .actions { margin-top:12px; display:flex; gap:6px; flex-wrap:wrap; }
  .actions button {
    font-family:inherit; font-size:12.5px; padding:5px 12px; border-radius:3px;
    border:1px solid var(--line); background:#fbf7ee; color:var(--ink); cursor:pointer;
  }
  .actions button:hover { background:var(--gold-soft); border-color:var(--gold); }
  .actions button.danger { color:var(--red); }
  .actions button.danger:hover { background:#f6e0dd; border-color:var(--red); }
  table { width:100%; border-collapse:collapse; background:var(--card);
    border:1px solid var(--line); border-radius:4px; overflow:hidden;
    box-shadow:0 1px 3px rgba(90,70,40,.12); }
  th, td { text-align:left; padding:10px 14px; border-bottom:1px solid var(--line); font-size:13.5px; }
  th {
    font-family:Verdana,Geneva,sans-serif; font-size:10px; letter-spacing:.08em;
    text-transform:uppercase; color:var(--ink-soft);
    background:#f1e9d8; border-bottom:2px solid var(--gold);
  }
  tr:last-child td { border-bottom:none; }
  dialog {
    font-family:inherit; border:none; border-radius:4px; padding:22px 24px;
    width:430px; max-width:92vw; background:var(--card); color:var(--ink);
    box-shadow:0 18px 50px rgba(43,33,24,.35); border-top:4px solid var(--gold);
  }
  dialog::backdrop { background:rgba(43,33,24,.55); }
  dialog h2 { margin:0 0 16px; font-size:18px; font-weight:normal; }
  dialog label {
    display:block; font-family:Verdana,Geneva,sans-serif; font-size:10px;
    font-weight:bold; letter-spacing:.08em; text-transform:uppercase;
    color:var(--ink-soft); margin:12px 0 4px;
  }
  dialog input, dialog select { width:100%; }
  dialog .row { display:flex; gap:10px; margin-top:20px; justify-content:flex-end; }
  dialog .row button {
    font-family:inherit; font-size:14px; padding:8px 16px; border-radius:3px;
    border:1px solid var(--line); background:transparent; cursor:pointer;
  }
  .empty { color:var(--ink-soft); font-style:italic; font-size:15px; padding:40px 0; text-align:center; }
  .error {
    background:#f6e0dd; color:var(--red); border:1px solid #dcaaa3; border-left:4px solid var(--red);
    border-radius:3px; padding:10px 14px; margin-bottom:14px; font-size:13.5px;
  }
  .overdue { border-left:4px solid var(--red); }
  footer {
    text-align:center; font-size:12px; font-style:italic; color:var(--ink-soft);
    padding:18px 0 26px; border-top:1px solid var(--line); margin-top:20px;
  }
</style>
</head>
<body>
<header>
  <h1><span class="crest">&#9670;</span>Ministry Library &amp; Resource Management System</h1>
  <p>Ministry of Higher Education, Training and Innovations &mdash; books, e-resources, labs and meeting rooms across all campuses</p>
</header>
<nav id="tabs">
  <button data-view="assets" class="active">Global view</button>
  <button data-view="campus">Campus view</button>
  <button data-view="overdue">Overdue dashboard</button>
</nav>
<main id="main"></main>
<footer>Republic of Namibia &middot; Ministry of Higher Education, Training and Innovations</footer>

<dialog id="dlg"></dialog>

<script>
const API = "/ministry/api";
const main = document.getElementById("main");
const dlg = document.getElementById("dlg");
let assets = [];

async function apiCall(path, opts) {
  const resp = await fetch(API + path, opts);
  const body = await resp.json().catch(() => ({}));
  if (!resp.ok) throw new Error(body.message || ("HTTP " + resp.status));
  return body;
}

function showError(msg) {
  const div = document.createElement("div");
  div.className = "error";
  div.textContent = msg;
  main.prepend(div);
  setTimeout(() => div.remove(), 5000);
}

function badge(status) { return '<span class="badge ' + status + '">' + status + "</span>"; }

async function loadAssets() {
  assets = await apiCall("/assets");
  return assets;
}

// ---------- Views ----------

function assetCard(a) {
  const schedules = (a.schedules || []).map(s =>
    "<li>" + s.scheduleId + " &middot; " + s.type + " &middot; due " + s.dueDate +
    " &mdash; " + s.description + "</li>").join("");
  const orders = (a.workOrders || []).map(w =>
    "<li>" + w.orderId + " [" + w.status + "] " + w.description +
    ((w.tasks || []).length ? "<ul>" + w.tasks.map(t => "<li>" + t.taskId + ": " + t.description + "</li>").join("") + "</ul>" : "") +
    "</li>").join("");
  const loanAction = a.status === "AVAILABLE"
    ? '<button onclick="loan(\'' + a.assetTag + '\')">Loan</button>' +
      '<button onclick="bookDlg(\'' + a.assetTag + '\')">Book</button>' : "";
  const returnAction = a.status === "LOANED_OUT"
    ? '<button onclick="returnLoan(\'' + a.assetTag + '\')">Return</button>' : "";
  const maintain = a.status !== "DISPOSED"
    ? '<button onclick="workOrderDlg(\'' + a.assetTag + '\')">Work order</button>' +
      '<button onclick="scheduleDlg(\'' + a.assetTag + '\')">Schedule</button>' : "";
  return '<div class="card' + ((a.schedules || []).some(s => s.dueDate < new Date().toISOString().slice(0,10)) ? " overdue" : "") + '">' +
    "<h3>" + a.name + " " + badge(a.status) + "</h3>" +
    '<div class="tag">' + a.assetTag + " &middot; " + a.institution + " &middot; " + a.site +
    " &middot; acquired " + a.dateAcquired + "</div>" +
    "<div>" + a.description + "</div>" +
    (schedules ? "<dl><dt>Schedules</dt><dd><ul>" + schedules + "</ul></dd></dl>" : "") +
    (orders ? "<dl><dt>Work orders</dt><dd><ul>" + orders + "</ul></dd></dl>" : "") +
    '<div class="actions">' + loanAction + returnAction + maintain +
      '<button class="danger" onclick="removeAsset(\'' + a.assetTag + '\')">Remove</button>' +
    "</div></div>";
}

async function viewAssets() {
  await loadAssets();
  main.innerHTML =
    '<div class="toolbar">' +
      '<button class="primary" onclick="addAssetDlg()">+ Add asset</button>' +
      '<input id="filter" placeholder="Filter by tag / name / site..." oninput="renderAssets()">' +
    "</div>" +
    '<div class="cards" id="cards"></div>';
  renderAssets();
}

function renderAssets() {
  const q = (document.getElementById("filter")?.value || "").toLowerCase();
  const shown = assets.filter(a =>
    !q || (a.assetTag + " " + a.name + " " + a.site + " " + a.institution).toLowerCase().includes(q));
  document.getElementById("cards").innerHTML =
    shown.length ? shown.map(assetCard).join("") : '<div class="empty">No assets match.</div>';
}

async function viewCampus() {
  const institutions = await apiCall("/institutions");
  main.innerHTML =
    '<div class="toolbar">' +
      '<select id="inst"><option value="">All institutions</option>' +
        institutions.map(i => '<option>' + i.name + "</option>").join("") +
      "</select>" +
      '<input id="site" placeholder="Site/campus (optional substring)">' +
      '<button class="primary" onclick="renderCampus()">Filter</button>' +
    "</div>" +
    '<div class="cards" id="cards"></div>';
  renderCampus();
}

async function renderCampus() {
  await loadAssets();
  const inst = document.getElementById("inst").value.toLowerCase();
  const site = document.getElementById("site").value.toLowerCase();
  const shown = assets.filter(a =>
    (!inst || a.institution.toLowerCase() === inst) &&
    (!site || a.site.toLowerCase().includes(site)));
  document.getElementById("cards").innerHTML =
    shown.length ? shown.map(assetCard).join("") : '<div class="empty">No assets for this campus.</div>';
}

async function viewOverdue() {
  await loadAssets();
  const overdue = await apiCall("/assets/overdue");
  main.innerHTML = overdue.length
    ? '<table><tr><th>Asset</th><th>Institution</th><th>Schedule</th><th>Type</th><th>Was due</th><th>Description</th></tr>' +
      overdue.map(o => "<tr><td>" + o.assetName + " (" + o.assetTag + ")</td><td>" + o.institution +
        "</td><td>" + o.scheduleId + "</td><td>" + o.type + "</td><td>" + o.dueDate +
        "</td><td>" + o.description + "</td></tr>").join("") + "</table>"
    : '<div class="empty">Nothing is overdue. All good!</div>';
}

// ---------- Actions ----------

async function loan(tag) {
  try { await apiCall("/assets/" + encodeURIComponent(tag) + "/loan", {method:"POST"});
        await refreshCurrent(); }
  catch (e) { showError(e.message); }
}

async function returnLoan(tag) {
  try { await apiCall("/assets/" + encodeURIComponent(tag) + "/returnLoan", {method:"POST"});
        await refreshCurrent(); }
  catch (e) { showError(e.message); }
}

async function removeAsset(tag) {
  if (!confirm("Remove asset " + tag + "?")) return;
  try { await apiCall("/assets/" + encodeURIComponent(tag), {method:"DELETE"});
        await refreshCurrent(); }
  catch (e) { showError(e.message); }
}

function dlgForm(title, fields, onsubmit) {
  dlg.innerHTML = "<h2>" + title + "</h2>" +
    fields.map(f =>
      "<label>" + f.label + "</label>" +
      (f.options
        ? '<select id="f_' + f.id + '">' + f.options.map(o => "<option>" + o + "</option>").join("") + "</select>"
        : '<input id="f_' + f.id + '" type="' + (f.type || "text") + '" value="' + (f.value || "") + '">')
    ).join("") +
    '<div class="row"><button onclick="dlg.close()">Cancel</button>' +
    '<button class="primary" id="dlgSubmit">Save</button></div>';
  dlg.querySelector("#dlgSubmit").onclick = async () => {
    const values = {};
    fields.forEach(f => values[f.id] = document.getElementById("f_" + f.id).value.trim());
    try { await onsubmit(values); dlg.close(); await refreshCurrent(); }
    catch (e) { showError(e.message); }
  };
  dlg.showModal();
}

function addAssetDlg() {
  dlgForm("Add asset", [
    {id:"assetTag", label:"Asset tag (unique)"},
    {id:"name", label:"Name"},
    {id:"description", label:"Description"},
    {id:"institution", label:"Institution"},
    {id:"site", label:"Site / campus"},
    {id:"status", label:"Status", options:["AVAILABLE","LOANED_OUT","OCCUPIED","UNDER_MAINTENANCE","DISPOSED"]},
    {id:"dateAcquired", label:"Date acquired", type:"date"}
  ], async v => {
    await apiCall("/assets", {method:"POST", headers:{"Content-Type":"application/json"},
      body: JSON.stringify(v)});
  });
}

function bookDlg(tag) {
  dlgForm("Book " + tag, [
    {id:"date", label:"Booking date", type:"date"},
    {id:"description", label:"Description (optional)"}
  ], async v => {
    await apiCall("/assets/" + encodeURIComponent(tag) + "/booking",
      {method:"POST", headers:{"Content-Type":"application/json"}, body: JSON.stringify(v)});
  });
}

function scheduleDlg(tag) {
  dlgForm("Add schedule to " + tag, [
    {id:"scheduleId", label:"Schedule ID"},
    {id:"type", label:"Type", options:["MAINTENANCE","SERVICING","BOOKING"]},
    {id:"dueDate", label:"Due date", type:"date"},
    {id:"description", label:"Description"}
  ], async v => {
    await apiCall("/assets/" + encodeURIComponent(tag) + "/schedules",
      {method:"POST", headers:{"Content-Type":"application/json"}, body: JSON.stringify(v)});
  });
}

function workOrderDlg(tag) {
  dlgForm("Open work order on " + tag, [
    {id:"orderId", label:"Order ID"},
    {id:"description", label:"Fault description"}
  ], async v => {
    await apiCall("/assets/" + encodeURIComponent(tag) + "/workorders",
      {method:"POST", headers:{"Content-Type":"application/json"},
       body: JSON.stringify({orderId: v.orderId, status: "OPEN", description: v.description})});
  });
}

// ---------- Boot ----------

const views = { assets: viewAssets, campus: viewCampus, overdue: viewOverdue };
let current = "assets";

async function refreshCurrent() { await views[current](); }

document.querySelectorAll("#tabs button").forEach(btn => {
  btn.onclick = async () => {
    document.querySelectorAll("#tabs button").forEach(b => b.classList.remove("active"));
    btn.classList.add("active");
    current = btn.dataset.view;
    try { await refreshCurrent(); } catch (e) { showError(e.message); }
  };
});

views.assets().catch(e => showError(e.message));
</script>
</body>
</html>`;

// Serves the single-page dashboard at http://localhost:8090/
// Shares the API listener declared in service.bal.
service / on apiListener {

    resource function get .() returns http:Response {
        http:Response response = new;
        response.setTextPayload(DASHBOARD_HTML, "text/html");
        return response;
    }
}
