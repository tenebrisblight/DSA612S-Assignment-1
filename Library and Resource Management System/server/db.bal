import ballerina/sql;
import ballerinax/mysql;

// Persistence for the ministry library system. One MySQL database


public type MysqlConfig record {|
    string host = "localhost";
    int port = 3306;
    string user = "root";
    string password = "";
    string database = "ministry";
|};

configurable MysqlConfig dbConfig = ?;

final mysql:Client db = check new (
    host = dbConfig.host,
    port = dbConfig.port,
    user = dbConfig.user,
    password = dbConfig.password,
    database = dbConfig.database
);

//schema


function initSchema() returns error? {
    _ = check db->execute(`
        CREATE TABLE IF NOT EXISTS institutions (
            name     VARCHAR(255) PRIMARY KEY,
            location VARCHAR(255) NOT NULL
        )`);
    _ = check db->execute(`
        CREATE TABLE IF NOT EXISTS assets (
            asset_tag     VARCHAR(64) PRIMARY KEY,
            name          VARCHAR(255) NOT NULL,
            description   TEXT,
            institution   VARCHAR(255) NOT NULL,
            site          VARCHAR(255) NOT NULL,
            status        VARCHAR(32)  NOT NULL,
            date_acquired VARCHAR(10)
        )`);
    _ = check db->execute(`
        CREATE TABLE IF NOT EXISTS components (
            comp_id     VARCHAR(64),
            asset_tag   VARCHAR(64) NOT NULL,
            name        VARCHAR(255) NOT NULL,
            description TEXT,
            PRIMARY KEY (comp_id, asset_tag),
            FOREIGN KEY (asset_tag) REFERENCES assets(asset_tag) ON DELETE CASCADE
        )`);
    _ = check db->execute(`
        CREATE TABLE IF NOT EXISTS schedules (
            schedule_id VARCHAR(64),
            asset_tag   VARCHAR(64) NOT NULL,
            type        VARCHAR(32) NOT NULL,
            due_date    VARCHAR(10),
            description TEXT,
            PRIMARY KEY (schedule_id, asset_tag),
            FOREIGN KEY (asset_tag) REFERENCES assets(asset_tag) ON DELETE CASCADE
        )`);
    _ = check db->execute(`
        CREATE TABLE IF NOT EXISTS work_orders (
            order_id    VARCHAR(64),
            asset_tag   VARCHAR(64) NOT NULL,
            status      VARCHAR(32) NOT NULL,
            description TEXT,
            PRIMARY KEY (order_id, asset_tag),
            FOREIGN KEY (asset_tag) REFERENCES assets(asset_tag) ON DELETE CASCADE
        )`);
    
    _ = check db->execute(`
        CREATE TABLE IF NOT EXISTS tasks (
            task_id     VARCHAR(64),
            order_id    VARCHAR(64) NOT NULL,
            asset_tag   VARCHAR(64) NOT NULL,
            description TEXT,
            PRIMARY KEY (task_id, order_id, asset_tag),
            FOREIGN KEY (order_id, asset_tag) REFERENCES work_orders(order_id, asset_tag) ON DELETE CASCADE
        )`);
}

//row types

type AssetRow record {|
    string asset_tag;
    string name;
    string? description;
    string institution;
    string site;
    string status;
    string? date_acquired;
|};

type ComponentRow record {|
    string comp_id;
    string name;
    string? description;
|};

type ScheduleRow record {|
    string schedule_id;
    string 'type;
    string? due_date;
    string? description;
|};

type WorkOrderRow record {|
    string order_id;
    string status;
    string? description;
|};

type TaskRow record {|
    string task_id;
    string description;
|};

type InstitutionRow record {|
    string name;
    string location;
|};

// asset reads


function dbGetAsset(string tag) returns Asset?|error {
    stream<AssetRow, sql:Error?> rows = db->query(`
        SELECT asset_tag, name, description, institution, site, status, date_acquired
        FROM assets WHERE asset_tag = ${tag}`);
    var first = check rows.next();
    _ = rows.close();
    if first is () {
        return ();
    }
    return hydrateAsset(first.value);
}


function hydrateAsset(AssetRow row) returns Asset|error {
    AssetStatus status = check row.status.cloneWithType();

    Component[] components = [];
    stream<ComponentRow, sql:Error?> compRows = db->query(`
        SELECT comp_id, name, description FROM components
        WHERE asset_tag = ${row.asset_tag} ORDER BY comp_id`);
    while true {
        var next = check compRows.next();
        if next is () {
            break;
        }
        ComponentRow c = next.value;
        components.push({
            compId: c.comp_id,
            name: c.name,
            description: c.description ?: ""
        });
    }

    Schedule[] schedules = [];
    stream<ScheduleRow, sql:Error?> schedRows = db->query(`
        SELECT schedule_id, type, due_date, description FROM schedules
        WHERE asset_tag = ${row.asset_tag} ORDER BY schedule_id`);
    while true {
        var next = check schedRows.next();
        if next is () {
            break;
        }
        ScheduleRow s = next.value;
       
        ScheduleType schedType = check s.'type.cloneWithType();
        schedules.push({
            scheduleId: s.schedule_id,
            'type: schedType,
            dueDate: s.due_date ?: "",
            description: s.description ?: ""
        });
    }

    WorkOrder[] orders = [];
    stream<WorkOrderRow, sql:Error?> woRows = db->query(`
        SELECT order_id, status, description FROM work_orders
        WHERE asset_tag = ${row.asset_tag} ORDER BY order_id`);
    while true {
        var next = check woRows.next();
        if next is () {
            break;
        }
        WorkOrderRow w = next.value;
        WorkOrderStatus woStatus = check w.status.cloneWithType();

        Task[] tasks = [];
        stream<TaskRow, sql:Error?> taskRows = db->query(`
            SELECT task_id, description FROM tasks
            WHERE order_id = ${w.order_id} AND asset_tag = ${row.asset_tag}
            ORDER BY task_id`);
        while true {
            var taskNext = check taskRows.next();
            if taskNext is () {
                break;
            }
            tasks.push({taskId: taskNext.value.task_id,
                        description: taskNext.value.description});
        }
        orders.push({
            orderId: w.order_id,
            status: woStatus,
            description: w.description ?: "",
            tasks: tasks
        });
    }

    return {
        assetTag: row.asset_tag,
        name: row.name,
        description: row.description ?: "",
        institution: row.institution,
        site: row.site,
        status: status,
        dateAcquired: row.date_acquired ?: "",
        components: components,
        schedules: schedules,
        workOrders: orders
    };
}


function loadAssets(stream<AssetRow, sql:Error?> rows) returns Asset[]|error {
    Asset[] out = [];
    while true {
        var next = check rows.next();
        if next is () {
            break;
        }
        Asset? a = check dbGetAsset(next.value.asset_tag);
        if a is Asset {
            out.push(a);
        }
    }
    _ = rows.close();
    return out;
}

function dbAllAssets() returns Asset[]|error {
    stream<AssetRow, sql:Error?> rows = db->query(`
        SELECT asset_tag, name, description, institution, site, status, date_acquired
        FROM assets ORDER BY asset_tag`);
    return loadAssets(rows);
}

function dbAssetsByInstitution(string institution) returns Asset[]|error {
    stream<AssetRow, sql:Error?> rows = db->query(`
        SELECT asset_tag, name, description, institution, site, status, date_acquired
        FROM assets WHERE LOWER(institution) = ${institution.toLowerAscii()}
        ORDER BY asset_tag`);
    return loadAssets(rows);
}

function dbAssetsByInstitutionSite(string institution, string site) returns Asset[]|error {
    stream<AssetRow, sql:Error?> rows = db->query(`
        SELECT asset_tag, name, description, institution, site, status, date_acquired
        FROM assets
        WHERE LOWER(institution) = ${institution.toLowerAscii()}
          AND LOWER(site) = ${site.toLowerAscii()}
        ORDER BY asset_tag`);
    return loadAssets(rows);
}

//asset writes

// children ride along with the parent insert
function dbInsertAsset(Asset asset) returns error? {
    _ = check db->execute(`
        INSERT INTO assets (asset_tag, name, description, institution, site, status, date_acquired)
        VALUES (${asset.assetTag}, ${asset.name}, ${asset.description},
                ${asset.institution}, ${asset.site}, ${asset.status}, ${asset.dateAcquired})`);
    foreach Component c in asset.components {
        _ = check db->execute(`
            INSERT INTO components (comp_id, asset_tag, name, description)
            VALUES (${c.compId}, ${asset.assetTag}, ${c.name}, ${c.description})`);
    }
    foreach Schedule s in asset.schedules {
        _ = check db->execute(`
            INSERT INTO schedules (schedule_id, asset_tag, type, due_date, description)
            VALUES (${s.scheduleId}, ${asset.assetTag}, ${s.'type}, ${s.dueDate}, ${s.description})`);
    }
    foreach WorkOrder w in asset.workOrders {
        error? e = dbInsertWorkOrder(asset.assetTag, w);
        if e is error {
            return e;
        }
    }
}


function dbUpdateAsset(string assetTag, AssetUpdate body) returns error? {
    _ = check db->execute(`UPDATE assets SET
        name = COALESCE(${body.name}, name),
        description = COALESCE(${body.description}, description),
        institution = COALESCE(${body.institution}, institution),
        site = COALESCE(${body.site}, site),
        status = COALESCE(${body.status}, status),
        date_acquired = COALESCE(${body.dateAcquired}, date_acquired)
        WHERE asset_tag = ${assetTag}`);
}


function dbDeleteAsset(string assetTag) returns error? {
    _ = check db->execute(`DELETE FROM assets WHERE asset_tag = ${assetTag}`);
}

function dbUpdateAssetStatus(string assetTag, AssetStatus status) returns error? {
    _ = check db->execute(`UPDATE assets SET status = ${status.toString()}
        WHERE asset_tag = ${assetTag}`);
}

//schedules

function dbInsertSchedule(string assetTag, Schedule s) returns error? {
    _ = check db->execute(`
        INSERT INTO schedules (schedule_id, asset_tag, type, due_date, description)
        VALUES (${s.scheduleId}, ${assetTag}, ${s.'type}, ${s.dueDate}, ${s.description})`);
}

function dbUpdateSchedule(string assetTag, string scheduleId, ScheduleUpdate body) returns error? {
    // same COALESCE partial-update trick as assets
    _ = check db->execute(`UPDATE schedules SET
        type = COALESCE(${body.'type}, type),
        due_date = COALESCE(${body.dueDate}, due_date),
        description = COALESCE(${body.description}, description)
        WHERE asset_tag = ${assetTag} AND schedule_id = ${scheduleId}`);
}


function dbDeleteSchedule(string assetTag, string scheduleId) returns int|error {
    sql:ExecutionResult result = check db->execute(`
        DELETE FROM schedules WHERE asset_tag = ${assetTag} AND schedule_id = ${scheduleId}`);
    return result.affectedRowCount ?: 0;
}

// ---------- components ----------

function dbInsertComponent(string assetTag, Component c) returns error? {
    _ = check db->execute(`
        INSERT INTO components (comp_id, asset_tag, name, description)
        VALUES (${c.compId}, ${assetTag}, ${c.name}, ${c.description})`);
}

function dbDeleteComponent(string assetTag, string compId) returns int|error {
    sql:ExecutionResult result = check db->execute(`
        DELETE FROM components WHERE asset_tag = ${assetTag} AND comp_id = ${compId}`);
    return result.affectedRowCount ?: 0;
}


function dbInsertWorkOrder(string assetTag, WorkOrder w) returns error? {
    _ = check db->execute(`
        INSERT INTO work_orders (order_id, asset_tag, status, description)
        VALUES (${w.orderId}, ${assetTag}, ${w.status}, ${w.description})`);
    foreach Task t in w.tasks {
        _ = check db->execute(`
            INSERT INTO tasks (task_id, order_id, asset_tag, description)
            VALUES (${t.taskId}, ${w.orderId}, ${assetTag}, ${t.description})`);
    }
}

function dbUpdateWorkOrder(string assetTag, string orderId, WorkOrderUpdate body) returns error? {
    
    _ = check db->execute(`UPDATE work_orders SET
        status = COALESCE(${body.status}, status),
        description = COALESCE(${body.description}, description)
        WHERE asset_tag = ${assetTag} AND order_id = ${orderId}`);
}

function dbInsertTask(string assetTag, string orderId, Task t) returns error? {
    _ = check db->execute(`
        INSERT INTO tasks (task_id, order_id, asset_tag, description)
        VALUES (${t.taskId}, ${orderId}, ${assetTag}, ${t.description})`);
}

function dbDeleteTask(string assetTag, string orderId, string taskId) returns int|error {
    sql:ExecutionResult result = check db->execute(`
        DELETE FROM tasks WHERE asset_tag = ${assetTag} AND order_id = ${orderId}
        AND task_id = ${taskId}`);
    return result.affectedRowCount ?: 0;
}

//institutions


function fetchInstitution(string name) returns Institution?|error {
    stream<InstitutionRow, sql:Error?> rows = db->query(
        `SELECT name, location FROM institutions WHERE name = ${name}`);
    var first = check rows.next();
    _ = rows.close();
    if first is () {
        return ();
    }
    return {name: first.value.name, location: first.value.location};
}

function dbInsertInstitution(Institution institution) returns error? {
    _ = check db->execute(`
        INSERT INTO institutions (name, location)
        VALUES (${institution.name}, ${institution.location})`);
}

function dbAllInstitutions() returns Institution[]|error {
    stream<InstitutionRow, sql:Error?> rows = db->query(
        `SELECT name, location FROM institutions ORDER BY name`);
    // comprehension drains the stream in one go
    return check from InstitutionRow r in rows
           select {name: r.name, location: r.location};
}

function dbInstitutionExists(string name) returns boolean|error {
    Institution? hit = check fetchInstitution(name);
    return hit is Institution;
}

function dbDeleteInstitution(string name) returns Institution?|error {
    
    Institution? existing = check fetchInstitution(name);
    if existing is Institution {
        _ = check db->execute(`DELETE FROM institutions WHERE name = ${name}`);
    }
    return existing;
}

//overdue


public type OverdueRow record {|
    string asset_tag;
    string asset_name;
    string institution;
    string schedule_id;
    string 'type;
    string due_date;
    string? description;
|};

function dbOverdue(string cutoff) returns OverdueItem[]|error {
    stream<OverdueRow, sql:Error?> rows = db->query(`
        SELECT a.asset_tag, a.name AS asset_name, a.institution,
               s.schedule_id, s.type, s.due_date, s.description
        FROM schedules s
        JOIN assets a ON a.asset_tag = s.asset_tag
        WHERE s.due_date < ${cutoff}
        ORDER BY s.due_date`);
    OverdueItem[] overdue = [];
    while true {
        var next = check rows.next();
        if next is () {
            break;
        }
        OverdueRow r = next.value;
        ScheduleType schedType = check r.'type.cloneWithType();
        overdue.push({
            assetTag: r.asset_tag,
            assetName: r.asset_name,
            institution: r.institution,
            scheduleId: r.schedule_id,
            'type: schedType,
            dueDate: r.due_date,
            description: r.description ?: ""
        });
    }
    return overdue;
}

//seed

function dbSeedIfEmpty() returns error? {
    stream<InstitutionRow, sql:Error?> probe = db->query(
        `SELECT name, location FROM institutions LIMIT 1`);
    var first = check probe.next();
    _ = probe.close();
    if !(first is ()) {
        return; // already seeded
    }

    Institution[] seedInstitutions = [
        {name: "Namibia University of Science and Technology", location: "Windhoek"},
        {name: "University of Namibia", location: "Windhoek"},
        {name: "International University of Management", location: "Windhoek"}
    ];
    foreach Institution institution in seedInstitutions {
        error? e = dbInsertInstitution(institution);
        if e is error {
            return e;
        }
    }

    Asset[] seedAssets = [
        {
            assetTag: "NUST-LIB-3DP-001",
            name: "Pro-Series 3D Printer",
            description: "High-precision laboratory printer for simulation and prototype development.",
            institution: "Namibia University of Science and Technology",
            site: "Main Campus - Innovation Lab",
            status: AVAILABLE,
            dateAcquired: "2024-03-10",
            components: [
                {compId: "C101", name: "High-Torque Stepper Motor",
                 description: "Main motor for X-axis movement."}
            ],
            schedules: [
                {scheduleId: "SCH-882", 'type: MAINTENANCE, dueDate: "2026-09-01",
                 description: "Quarterly calibration and nozzle cleaning."}
            ],
            workOrders: [
                {orderId: "WO-554", status: OPEN,
                 description: "Nozzle heat-bed failure",
                 tasks: [{taskId: "T1", description: "Check thermal sensor connectivity."}]}
            ]
        },
        {
            assetTag: "NUST-LIB-LAP-014",
            name: "Dell Latitude 5540",
            description: "Student loan laptop, 16GB RAM.",
            institution: "Namibia University of Science and Technology",
            site: "Main Campus - Library",
            status: LOANED_OUT,
            dateAcquired: "2025-01-20",
            schedules: [
                {scheduleId: "SCH-901", 'type: SERVICING, dueDate: "2027-01-15",
                 description: "Annual hardware service and battery check."}
            ]
        },
        {
            assetTag: "UNAM-LIB-ROOM-101",
            name: "Meeting Room 101",
            description: "12-seat meeting room with projector and whiteboard.",
            institution: "University of Namibia",
            site: "Main Campus - Library Wing",
            status: AVAILABLE,
            dateAcquired: "2023-08-01",
            schedules: [
                {scheduleId: "SCH-770", 'type: BOOKING, dueDate: "2026-09-10",
                 description: "Research group weekly meeting."}
            ]
        },
        {
            assetTag: "UNAM-LAB-PC-220",
            name: "Thin Client TC-440",
            description: "Lab thin client terminal, row 2.",
            institution: "University of Namibia",
            site: "Science Campus - Computer Lab 2",
            status: UNDER_MAINTENANCE,
            dateAcquired: "2022-11-05",
            schedules: [
                {scheduleId: "SCH-665", 'type: MAINTENANCE, dueDate: "2026-08-20",
                 description: "Firmware update and disk cleanup."}
            ],
            workOrders: [
                {orderId: "WO-610", status: IN_PROGRESS,
                 description: "Boot loop after power outage",
                 tasks: [
                     {taskId: "T1", description: "Reflash firmware."},
                     {taskId: "T2", description: "Replace faulty power supply."}
                 ]}
            ]
        },
        {
            assetTag: "IUM-LIB-PROJ-007",
            name: "Epson EB-X49 Projector",
            description: "Portable projector for lecture halls.",
            institution: "International University of Management",
            site: "Dorado Park Campus - Lecture Hall B",
            status: AVAILABLE,
            dateAcquired: "2024-06-18",
            schedules: [
                {scheduleId: "SCH-540", 'type: SERVICING, dueDate: "2026-12-01",
                 description: "Lamp replacement and filter cleaning."}
            ]
        }
    ];
    foreach Asset asset in seedAssets {
        error? e = dbInsertAsset(asset);
        if e is error {
            return e;
        }
    }
}
