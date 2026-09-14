import ballerina/http;
import ballerina/time;

// Ministry library / resource management API.
// Data lives in MySQL (creds + schema in db.bal). Every asset is keyed by
// Run with: bal run  (listens on :8090)

listener http:Listener httpListener = new (8090);

service /ministry/api on httpListener {

    function init() returns error? {
        // first boot: create tables, then drop in sample rows if empty
        error? e = initSchema();
        if e is error {
            return e;
        }
        return dbSeedIfEmpty();
    }

    //assets

    resource function post assets(@http:Payload Asset asset)
            returns Asset|http:Conflict|http:BadRequest|http:InternalServerError {
        if asset.assetTag.trim() == "" {
            return badInput("assetTag must not be empty");
        }
        if asset.name.trim() == "" {
            return badInput("name must not be empty");
        }

        var already = loadAsset(asset.assetTag);
        if already is error {
            return dbErr(already);
        }
        if already is Asset {
            return conflict("asset '" + asset.assetTag + "' already exists");
        }

        error? e = dbInsertAsset(asset);
        if e is error {
            return dbErr(e);
        }
        return asset;
    }

    resource function get assets() returns Asset[]|http:InternalServerError {
        
        var rows = dbAllAssets();
        if rows is error {
            return dbErr(rows);
        }
        return <Asset[]>rows;
    }

    resource function get assets/[string assetTag]()
            returns Asset|http:NotFound|http:InternalServerError {
        var found = loadAsset(assetTag);
        if found is error {
            return dbErr(found);
        }
        if found is Asset {
            return found;
        }
        return notFound("no asset with tag '" + assetTag + "'");
    }

    resource function put assets/[string assetTag](@http:Payload AssetUpdate upd)
            returns Asset|http:NotFound|http:InternalServerError {
        var found = loadAsset(assetTag);
        if found is error {
            return dbErr(found);
        }
        if found !is Asset {
            return notFound("no asset with tag '" + assetTag + "'");
        }

        error? e = dbUpdateAsset(assetTag, upd);
        if e is error {
            return dbErr(e);
        }
        var after = loadAsset(assetTag);
        if after is error {
            return dbErr(after);
        }
        if after is Asset {
            return after;
        }
        return notFound("no asset with tag '" + assetTag + "'");
    }

    resource function delete assets/[string assetTag]()
            returns Asset|http:NotFound|http:InternalServerError {
        var found = loadAsset(assetTag);
        if found is error {
            return dbErr(found);
        }
        if found !is Asset {
            return notFound("no asset with tag '" + assetTag + "'");
        }

        error? e = dbDeleteAsset(assetTag);
        if e is error {
            return dbErr(e);
        }
        return found;
    }

    // filters

    resource function get assets/institution/[string institution]()
            returns Asset[]|http:InternalServerError {
        var rows = dbAssetsByInstitution(institution);
        if rows is error {
            return dbErr(rows);
        }
        return rows;
    }

    resource function get assets/institution/[string institution]/site/[string site]()
            returns Asset[]|http:InternalServerError {
        var rows = dbAssetsByInstitutionSite(institution, site);
        if rows is error {
            return dbErr(rows);
        }
        return rows;
    }

    resource function get assets/overdue() returns OverdueItem[]|http:InternalServerError {
        var rows = dbOverdue(todayStr());
        if rows is error {
            return dbErr(rows);
        }
        return rows;
    }

    //loans / bookings

    resource function post assets/[string assetTag]/loan()
            
            returns Asset|http:Conflict|http:NotFound|http:InternalServerError {
        var found = loadAsset(assetTag);
        if found is error {
            return dbErr(found);
        }
        if found !is Asset {
            return notFound("no asset with tag '" + assetTag + "'");
        }
        if found.status != AVAILABLE {
            return conflict("asset '" + assetTag + "' is " + found.status + ", not AVAILABLE");
        }

        // NOTE: check + update isn't atomic, two people could grab the same
        // thing at once. internal tool, we live with it for now
        error? e = dbUpdateAssetStatus(assetTag, LOANED_OUT);
        if e is error {
            return dbErr(e);
        }
        found.status = LOANED_OUT;
        return found;
    }

    resource function post assets/[string assetTag]/returnLoan()
            returns Asset|http:Conflict|http:NotFound|http:InternalServerError {
        var found = loadAsset(assetTag);
        if found is error {
            return dbErr(found);
        }
        if found !is Asset {
            return notFound("no asset with tag '" + assetTag + "'");
        }
        if found.status != LOANED_OUT {
            return conflict("asset '" + assetTag + "' is not loaned out right now");
        }

        error? e = dbUpdateAssetStatus(assetTag, AVAILABLE);
        if e is error {
            return dbErr(e);
        }
        found.status = AVAILABLE;
        return found;
    }

  
    resource function post assets/[string assetTag]/booking(@http:Payload BookingRequest req)
            returns Asset|http:Conflict|http:NotFound|http:BadRequest|http:InternalServerError {
        var found = loadAsset(assetTag);
        if found is error {
            return dbErr(found);
        }
        if found !is Asset {
            return notFound("no asset with tag '" + assetTag + "'");
        }
        if req.date.trim() == "" {
            return badInput("booking needs a date");
        }
        if found.status != AVAILABLE {
            return conflict("asset '" + assetTag + "' is " + found.status + ", not AVAILABLE");
        }

        error? e = dbUpdateAssetStatus(assetTag, OCCUPIED);
        if e is error {
            return dbErr(e);
        }

        
        Schedule booking = {
            scheduleId: "BKG-" + (found.schedules.length() + 1).toString(),
            'type: BOOKING,
            dueDate: req.date,
            description: req.description ?: "Room booking"
        };
        error? se = dbInsertSchedule(assetTag, booking);
        if se is error {
            return dbErr(se);
        }
        found.status = OCCUPIED;
        found.schedules.push(booking);
        return found;
    }

    //components

    resource function post assets/[string assetTag]/components(@http:Payload Component comp)
            returns Asset|http:NotFound|http:Conflict|http:InternalServerError {
        var found = loadAsset(assetTag);
        if found is error {
            return dbErr(found);
        }
        if found !is Asset {
            return notFound("no asset with tag '" + assetTag + "'");
        }
        // compId only has to be unique within the asset, not globally
        foreach var c in found.components {
            if c.compId == comp.compId {
                return conflict("component '" + comp.compId + "' already exists");
            }
        }

        error? e = dbInsertComponent(assetTag, comp);
        if e is error {
            return dbErr(e);
        }
        found.components.push(comp);
        return found;
    }

    resource function delete assets/[string assetTag]/components/[string compId]()
            returns Asset|http:NotFound|http:InternalServerError {
        var found = loadAsset(assetTag);
        if found is error {
            return dbErr(found);
        }
        if found !is Asset {
            return notFound("no asset with tag '" + assetTag + "'");
        }

        var gone = dbDeleteComponent(assetTag, compId);
        if gone is error {
            return dbErr(gone);
        }
        int removed = <int>gone;
        if removed == 0 {
            return notFound("asset '" + assetTag + "' has no component '" + compId + "'");
        }
        // filter it out of the copy we send back
        found.components = from var c in found.components
                           where c.compId != compId
                           select c;
        return found;
    }

    //schedules (servicing / maintenance / bookings)

    resource function post assets/[string assetTag]/schedules(@http:Payload Schedule sch)
            returns Asset|http:NotFound|http:Conflict|http:InternalServerError {
        var found = loadAsset(assetTag);
        if found is error {
            return dbErr(found);
        }
        if found !is Asset {
            return notFound("no asset with tag '" + assetTag + "'");
        }
        foreach var s in found.schedules {
            if s.scheduleId == sch.scheduleId {
                return conflict("schedule '" + sch.scheduleId + "' already exists");
            }
        }

        error? e = dbInsertSchedule(assetTag, sch);
        if e is error {
            return dbErr(e);
        }
        found.schedules.push(sch);
        return found;
    }

    resource function put assets/[string assetTag]/schedules/[string scheduleId](
            @http:Payload ScheduleUpdate upd) returns Asset|http:NotFound|http:InternalServerError {
        var found = loadAsset(assetTag);
        if found is error {
            return dbErr(found);
        }
        if found !is Asset {
            return notFound("no asset with tag '" + assetTag + "'");
        }
        // just an existence check, the db call below does the real work
        [int, Schedule]? pos = findSchedule(found, scheduleId);
        if pos is () {
            return notFound("no schedule '" + scheduleId + "' on asset '" + assetTag + "'");
        }

        error? e = dbUpdateSchedule(assetTag, scheduleId, upd);
        if e is error {
            return dbErr(e);
        }
        var after = loadAsset(assetTag);
        if after is error {
            return dbErr(after);
        }
        if after is Asset {
            return after;
        }
        return notFound("no asset with tag '" + assetTag + "'");
    }

    resource function delete assets/[string assetTag]/schedules/[string scheduleId]()
            returns Asset|http:NotFound|http:InternalServerError {
        var found = loadAsset(assetTag);
        if found is error {
            return dbErr(found);
        }
        if found !is Asset {
            return notFound("no asset with tag '" + assetTag + "'");
        }

        var gone = dbDeleteSchedule(assetTag, scheduleId);
        if gone is error {
            return dbErr(gone);
        }
        int removed = <int>gone;
        if removed == 0 {
            return notFound("no schedule '" + scheduleId + "' on asset '" + assetTag + "'");
        }
        found.schedules = from var s in found.schedules
                          where s.scheduleId != scheduleId
                          select s;
        return found;
    }

    // work orders
    resource function post assets/[string assetTag]/workorders(@http:Payload WorkOrder wo)
            returns Asset|http:NotFound|http:Conflict|http:InternalServerError {
        var found = loadAsset(assetTag);
        if found is error {
            return dbErr(found);
        }
        if found !is Asset {
            return notFound("no asset with tag '" + assetTag + "'");
        }
        foreach var existing in found.workOrders {
            if existing.orderId == wo.orderId {
                return conflict("work order '" + wo.orderId + "' already exists");
            }
        }

        error? e = dbInsertWorkOrder(assetTag, wo);
        if e is error {
            return dbErr(e);
        }
        if found.status == AVAILABLE {
            error? se = dbUpdateAssetStatus(assetTag, UNDER_MAINTENANCE);
            if se is error {
                return dbErr(se);
            }
            found.status = UNDER_MAINTENANCE;
        }
        found.workOrders.push(wo);
        return found;
    }

    resource function put assets/[string assetTag]/workorders/[string orderId](
            @http:Payload WorkOrderUpdate upd) returns Asset|http:NotFound|http:InternalServerError {
        var found = loadAsset(assetTag);
        if found is error {
            return dbErr(found);
        }
        if found !is Asset {
            return notFound("no asset with tag '" + assetTag + "'");
        }
        [int, WorkOrder]? pos = findWorkOrder(found, orderId);
        if pos is () {
            return notFound("no work order '" + orderId + "' on asset '" + assetTag + "'");
        }

        error? e = dbUpdateWorkOrder(assetTag, orderId, upd);
        if e is error {
            return dbErr(e);
        }
        if upd.status == CLOSED {
            boolean othersOpen = false;
            foreach var wo in found.workOrders {
                if wo.orderId != orderId && wo.status != CLOSED {
                    othersOpen = true;
                    break;
                }
            }
            if !othersOpen && found.status == UNDER_MAINTENANCE {
                error? se = dbUpdateAssetStatus(assetTag, AVAILABLE);
                if se is error {
                    return dbErr(se);
                }
                found.status = AVAILABLE;
            }
        }
        var after = loadAsset(assetTag);
        if after is error {
            return dbErr(after);
        }
        if after is Asset {
            return after;
        }
        return notFound("no asset with tag '" + assetTag + "'");
    }

    resource function post assets/[string assetTag]/workorders/[string orderId]/tasks(
            @http:Payload Task task) returns Asset|http:NotFound|http:InternalServerError {
        var found = loadAsset(assetTag);
        if found is error {
            return dbErr(found);
        }
        if found !is Asset {
            return notFound("no asset with tag '" + assetTag + "'");
        }
        [int, WorkOrder]? pos = findWorkOrder(found, orderId);
        if pos is () {
            return notFound("no work order '" + orderId + "' on asset '" + assetTag + "'");
        }

        error? e = dbInsertTask(assetTag, orderId, task);
        if e is error {
            return dbErr(e);
        }
        found.workOrders[pos[0]].tasks.push(task);
        return found;
    }

    resource function delete assets/[string assetTag]/workorders/[string orderId]/tasks/[string taskId]()
            returns Asset|http:NotFound|http:InternalServerError {
        var found = loadAsset(assetTag);
        if found is error {
            return dbErr(found);
        }
        if found !is Asset {
            return notFound("no asset with tag '" + assetTag + "'");
        }
        [int, WorkOrder]? pos = findWorkOrder(found, orderId);
        if pos is () {
            return notFound("no work order '" + orderId + "' on asset '" + assetTag + "'");
        }

        var gone = dbDeleteTask(assetTag, orderId, taskId);
        if gone is error {
            return dbErr(gone);
        }
        int removed = <int>gone;
        if removed == 0 {
            return notFound("no task '" + taskId + "' on work order '" + orderId + "'");
        }
        found.workOrders[pos[0]].tasks = from var t in found.workOrders[pos[0]].tasks
                                         where t.taskId != taskId
                                         select t;
        return found;
    }

    //institutions

    resource function post institutions(@http:Payload Institution institution)
            returns Institution|http:Conflict|http:BadRequest|http:InternalServerError {
        if institution.name.trim() == "" {
            return badInput("institution name must not be empty");
        }
        var exists = dbInstitutionExists(institution.name);
        if exists is error {
            return dbErr(exists);
        }
        if <boolean>exists {
            return conflict("institution '" + institution.name + "' is already registered");
        }

        error? e = dbInsertInstitution(institution);
        if e is error {
            return dbErr(e);
        }
        return institution;
    }

    resource function get institutions() returns Institution[]|http:InternalServerError {
        var rows = dbAllInstitutions();
        if rows is error {
            return dbErr(rows);
        }
        return rows;
    }

    resource function delete institutions/[string name]()
            returns Institution|http:NotFound|http:InternalServerError {
        var gone = dbDeleteInstitution(name);
        if gone is error {
            return dbErr(gone);
        }
        Institution? removed = <Institution?>gone;
        if removed is Institution {
            return removed;
        }
        return notFound("no institution called '" + name + "'");
    }
}

//helpers

function loadAsset(string tag) returns Asset?|error {
    var res = dbGetAsset(tag);
    if res is error {
        return res;
    }
    return <Asset?>res;
}

// yyyy-mm-dd slice of current UTC time, good enough for overdue checks
function todayStr() returns string {
    return <string>time:utcToString(time:utcNow()).substring(0, 10);
}

function notFound(string msg) returns http:NotFound {
    return {body: {message: msg}};
}

function conflict(string msg) returns http:Conflict {
    return {body: {message: msg}};
}

function badInput(string msg) returns http:BadRequest {
    return {body: {message: msg}};
}

// every db failure surfaces as a 500 with the driver message tacked on
function dbErr(error e) returns http:InternalServerError {
    return {body: {message: "Database error: " + e.message()}};
}

function findSchedule(Asset a, string id) returns [int, Schedule]? {
    int i = 0;
    foreach var s in a.schedules {
        if s.scheduleId == id {
            return [i, s];
        }
        i += 1;
    }
    return ();
}

function findWorkOrder(Asset a, string id) returns [int, WorkOrder]? {
    int i = 0;
    foreach var wo in a.workOrders {
        if wo.orderId == id {
            return [i, wo];
        }
        i += 1;
    }
    return ();
}
