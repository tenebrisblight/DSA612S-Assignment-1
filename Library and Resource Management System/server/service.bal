import ballerina/http;
import ballerina/time;

// REST API for the Ministry Library and Resource Management System.
// All data is persisted in MySQL (see db.bal); assets are keyed by the
// unique asset_tag.

// Shared HTTP listener for both the REST API and the web dashboard.
listener http:Listener apiListener = new (8090);

service /ministry/api on apiListener {

    function init() returns error? {
        error? e = initSchema();
        if e is error {
            return e;
        }
        return dbSeedIfEmpty();
    }

    // ---------- Asset CRUD ----------

    // Create a new asset.
    resource function post assets(@http:Payload Asset asset)
            returns Asset|http:Conflict|http:BadRequest|http:InternalServerError {
        if asset.assetTag.trim() == "" {
            return badRequest("assetTag must not be empty.");
        }
        if asset.name.trim() == "" {
            return badRequest("name must not be empty.");
        }
        var existingErr = dbGetAsset(asset.assetTag);
        if existingErr is error {
            return dbError(existingErr);
        }
        Asset? existing = <Asset?>existingErr;
        if existing is Asset {
            return conflictError("Asset '" + asset.assetTag + "' already exists.");
        }
        error? e = dbInsertAsset(asset);
        if e is error {
            return dbError(e);
        }
        return asset;
    }

    // Retrieve all assets (global view across the ministry).
    resource function get assets() returns Asset[]|http:InternalServerError {
        var listErr = dbAllAssets();
        if listErr is error {
            return dbError(listErr);
        }
        Asset[] list = <Asset[]>listErr;
        return list;
    }

    // Retrieve a single asset by its unique tag.
    resource function get assets/[string assetTag]()
            returns Asset|http:NotFound|http:InternalServerError {
        var assetErr = dbGetAsset(assetTag);
        if assetErr is error {
            return dbError(assetErr);
        }
        Asset? asset = <Asset?>assetErr;
        if asset is Asset {
            return asset;
        }
        return notFound("No asset with tag '" + assetTag + "'.");
    }

    // Update an existing asset.
    resource function put assets/[string assetTag](@http:Payload AssetUpdate body)
            returns Asset|http:NotFound|http:InternalServerError {
        var existingErr = dbGetAsset(assetTag);
        if existingErr is error {
            return dbError(existingErr);
        }
        Asset? existing = <Asset?>existingErr;
        if existing !is Asset {
            return notFound("No asset with tag '" + assetTag + "'.");
        }
        error? e = dbUpdateAsset(assetTag, body);
        if e is error {
            return dbError(e);
        }
        var updatedErr = dbGetAsset(assetTag);
        if updatedErr is error {
            return dbError(updatedErr);
        }
        Asset? updated = <Asset?>updatedErr;
        if updated !is Asset {
            return notFound("No asset with tag '" + assetTag + "'.");
        }
        return updated;
    }

    // Delete an asset.
    resource function delete assets/[string assetTag]()
            returns Asset|http:NotFound|http:InternalServerError {
        var existingErr = dbGetAsset(assetTag);
        if existingErr is error {
            return dbError(existingErr);
        }
        Asset? existing = <Asset?>existingErr;
        if existing !is Asset {
            return notFound("No asset with tag '" + assetTag + "'.");
        }
        error? e = dbDeleteAsset(assetTag);
        if e is error {
            return dbError(e);
        }
        return existing;
    }

    // ---------- Institution filtering / campus view ----------

    // All assets belonging to one institution.
    resource function get assets/institution/[string institution]()
            returns Asset[]|http:InternalServerError {
        var resultVal = dbAssetsByInstitution(institution);
        if resultVal is error {
            return dbError(resultVal);
        }
        return resultVal;
    }

    // Assets belonging to one institution AND one site/campus.
    resource function get assets/institution/[string institution]/site/[string site]()
            returns Asset[]|http:InternalServerError {
        var resultVal = dbAssetsByInstitutionSite(institution, site);
        if resultVal is error {
            return dbError(resultVal);
        }
        return resultVal;
    }

    // ---------- Maintenance / overdue checks ----------

    // Schedules whose due date has already passed, across all assets.
    resource function get assets/overdue() returns OverdueItem[]|http:InternalServerError {
        var resultVal = dbOverdue(today());
        if resultVal is error {
            return dbError(resultVal);
        }
        return resultVal;
    }

    // ---------- Loaning / booking ----------

    // Loan an asset out to a user.
    resource function post assets/[string assetTag]/loan()
            returns Asset|http:Conflict|http:NotFound|http:InternalServerError {
        var existingErr = dbGetAsset(assetTag);
        if existingErr is error {
            return dbError(existingErr);
        }
        Asset? existing = <Asset?>existingErr;
        if existing !is Asset {
            return notFound("No asset with tag '" + assetTag + "'.");
        }
        if existing.status != AVAILABLE {
            return conflictError("Asset '" + assetTag + "' is " +
                existing.status + ", not AVAILABLE.");
        }
        error? e = dbUpdateAssetStatus(assetTag, LOANED_OUT);
        if e is error {
            return dbError(e);
        }
        existing.status = LOANED_OUT;
        return existing;
    }

    // Return a loaned asset.
    resource function post assets/[string assetTag]/returnLoan()
            returns Asset|http:Conflict|http:NotFound|http:InternalServerError {
        var existingErr = dbGetAsset(assetTag);
        if existingErr is error {
            return dbError(existingErr);
        }
        Asset? existing = <Asset?>existingErr;
        if existing !is Asset {
            return notFound("No asset with tag '" + assetTag + "'.");
        }
        if existing.status != LOANED_OUT {
            return conflictError("Asset '" + assetTag + "' is not currently loaned out.");
        }
        error? e = dbUpdateAssetStatus(assetTag, AVAILABLE);
        if e is error {
            return dbError(e);
        }
        existing.status = AVAILABLE;
        return existing;
    }

    // Book a meeting room / lab.
    resource function post assets/[string assetTag]/booking(@http:Payload BookingRequest body)
            returns Asset|http:Conflict|http:NotFound|http:BadRequest|http:InternalServerError {
        var existingErr = dbGetAsset(assetTag);
        if existingErr is error {
            return dbError(existingErr);
        }
        Asset? existing = <Asset?>existingErr;
        if existing !is Asset {
            return notFound("No asset with tag '" + assetTag + "'.");
        }
        if body.date.trim() == "" {
            return badRequest("Booking requires a 'date'.");
        }
        if existing.status != AVAILABLE {
            return conflictError("Asset '" + assetTag + "' is " +
                existing.status + ", not AVAILABLE.");
        }
        error? e = dbUpdateAssetStatus(assetTag, OCCUPIED);
        if e is error {
            return dbError(e);
        }
        Schedule booking = {
            scheduleId: "BKG-" + (existing.schedules.length() + 1).toString(),
            'type: BOOKING,
            dueDate: body.date,
            description: body.description ?: "Room booking"
        };
        error? se = dbInsertSchedule(assetTag, booking);
        if se is error {
            return dbError(se);
        }
        existing.status = OCCUPIED;
        existing.schedules.push(booking);
        return existing;
    }

    // ---------- Component management ----------

    // Add a component to a complex asset.
    resource function post assets/[string assetTag]/components(@http:Payload Component component)
            returns Asset|http:NotFound|http:Conflict|http:InternalServerError {
        var existingErr = dbGetAsset(assetTag);
        if existingErr is error {
            return dbError(existingErr);
        }
        Asset? existing = <Asset?>existingErr;
        if existing !is Asset {
            return notFound("No asset with tag '" + assetTag + "'.");
        }
        foreach var c in existing.components {
            if c.compId == component.compId {
                return conflictError("Component '" + component.compId + "' already exists.");
            }
        }
        error? e = dbInsertComponent(assetTag, component);
        if e is error {
            return dbError(e);
        }
        existing.components.push(component);
        return existing;
    }

    // Remove a component from an asset.
    resource function delete assets/[string assetTag]/components/[string compId]()
            returns Asset|http:NotFound|http:InternalServerError {
        var existingErr = dbGetAsset(assetTag);
        if existingErr is error {
            return dbError(existingErr);
        }
        Asset? existing = <Asset?>existingErr;
        if existing !is Asset {
            return notFound("No asset with tag '" + assetTag + "'.");
        }
        var removedErr = dbDeleteComponent(assetTag, compId);
        if removedErr is error {
            return dbError(removedErr);
        }
        int removed = <int>removedErr;
        if removed == 0 {
            return notFound("No component '" + compId + "' on asset '" + assetTag + "'.");
        }
        Component[] remaining = [];
        foreach var c in existing.components {
            if c.compId != compId {
                remaining.push(c);
            }
        }
        existing.components = remaining;
        return existing;
    }

    // ---------- Schedule management ----------

    // Add a servicing/maintenance/booking schedule to an asset.
    resource function post assets/[string assetTag]/schedules(@http:Payload Schedule schedule)
            returns Asset|http:NotFound|http:Conflict|http:InternalServerError {
        var existingErr = dbGetAsset(assetTag);
        if existingErr is error {
            return dbError(existingErr);
        }
        Asset? existing = <Asset?>existingErr;
        if existing !is Asset {
            return notFound("No asset with tag '" + assetTag + "'.");
        }
        foreach var s in existing.schedules {
            if s.scheduleId == schedule.scheduleId {
                return conflictError("Schedule '" + schedule.scheduleId + "' already exists.");
            }
        }
        error? e = dbInsertSchedule(assetTag, schedule);
        if e is error {
            return dbError(e);
        }
        existing.schedules.push(schedule);
        return existing;
    }

    // Modify an existing schedule.
    resource function put assets/[string assetTag]/schedules/[string scheduleId](
            @http:Payload ScheduleUpdate body) returns Asset|http:NotFound|http:InternalServerError {
        var existingErr = dbGetAsset(assetTag);
        if existingErr is error {
            return dbError(existingErr);
        }
        Asset? existing = <Asset?>existingErr;
        if existing !is Asset {
            return notFound("No asset with tag '" + assetTag + "'.");
        }
        [int, Schedule]? result = findSchedule(existing, scheduleId);
        if result !is [int, Schedule] {
            return notFound("No schedule '" + scheduleId + "' on asset '" + assetTag + "'.");
        }
        error? e = dbUpdateSchedule(assetTag, scheduleId, body);
        if e is error {
            return dbError(e);
        }
        var updatedErr = dbGetAsset(assetTag);
        if updatedErr is error {
            return dbError(updatedErr);
        }
        Asset? updated = <Asset?>updatedErr;
        if updated !is Asset {
            return notFound("No asset with tag '" + assetTag + "'.");
        }
        return updated;
    }

    // Remove a schedule from an asset.
    resource function delete assets/[string assetTag]/schedules/[string scheduleId]()
            returns Asset|http:NotFound|http:InternalServerError {
        var existingErr = dbGetAsset(assetTag);
        if existingErr is error {
            return dbError(existingErr);
        }
        Asset? existing = <Asset?>existingErr;
        if existing !is Asset {
            return notFound("No asset with tag '" + assetTag + "'.");
        }
        var removedErr = dbDeleteSchedule(assetTag, scheduleId);
        if removedErr is error {
            return dbError(removedErr);
        }
        int removed = <int>removedErr;
        if removed == 0 {
            return notFound("No schedule '" + scheduleId + "' on asset '" + assetTag + "'.");
        }
        Schedule[] remaining = [];
        foreach var s in existing.schedules {
            if s.scheduleId != scheduleId {
                remaining.push(s);
            }
        }
        existing.schedules = remaining;
        return existing;
    }

    // ---------- Work orders & task tracking ----------

    // Open a new work order against a faulty resource.
    resource function post assets/[string assetTag]/workorders(@http:Payload WorkOrder workOrder)
            returns Asset|http:NotFound|http:Conflict|http:InternalServerError {
        var existingErr = dbGetAsset(assetTag);
        if existingErr is error {
            return dbError(existingErr);
        }
        Asset? existing = <Asset?>existingErr;
        if existing !is Asset {
            return notFound("No asset with tag '" + assetTag + "'.");
        }
        foreach var wo in existing.workOrders {
            if wo.orderId == workOrder.orderId {
                return conflictError("Work order '" + workOrder.orderId + "' already exists.");
            }
        }
        error? e = dbInsertWorkOrder(assetTag, workOrder);
        if e is error {
            return dbError(e);
        }
        if existing.status == AVAILABLE {
            error? se = dbUpdateAssetStatus(assetTag, UNDER_MAINTENANCE);
            if se is error {
                return dbError(se);
            }
            existing.status = UNDER_MAINTENANCE;
        }
        existing.workOrders.push(workOrder);
        return existing;
    }

    // Update the status or description of a work order.
    resource function put assets/[string assetTag]/workorders/[string orderId](
            @http:Payload WorkOrderUpdate body) returns Asset|http:NotFound|http:InternalServerError {
        var existingErr = dbGetAsset(assetTag);
        if existingErr is error {
            return dbError(existingErr);
        }
        Asset? existing = <Asset?>existingErr;
        if existing !is Asset {
            return notFound("No asset with tag '" + assetTag + "'.");
        }
        [int, WorkOrder]? result = findWorkOrder(existing, orderId);
        if result !is [int, WorkOrder] {
            return notFound("No work order '" + orderId + "' on asset '" + assetTag + "'.");
        }
        error? e = dbUpdateWorkOrder(assetTag, orderId, body);
        if e is error {
            return dbError(e);
        }
        // Closing the last open work order frees the asset again.
        if body.status == CLOSED {
            boolean anyOpen = false;
            foreach var wo in existing.workOrders {
                if wo.orderId != orderId && wo.status != CLOSED {
                    anyOpen = true;
                    break;
                }
            }
            if !anyOpen && existing.status == UNDER_MAINTENANCE {
                error? se = dbUpdateAssetStatus(assetTag, AVAILABLE);
                if se is error {
                    return dbError(se);
                }
                existing.status = AVAILABLE;
            }
        }
        var updatedErr = dbGetAsset(assetTag);
        if updatedErr is error {
            return dbError(updatedErr);
        }
        Asset? updated = <Asset?>updatedErr;
        if updated !is Asset {
            return notFound("No asset with tag '" + assetTag + "'.");
        }
        return updated;
    }

    // Add a sub-task to a work order.
    resource function post assets/[string assetTag]/workorders/[string orderId]/tasks(
            @http:Payload Task task) returns Asset|http:NotFound|http:InternalServerError {
        var existingErr = dbGetAsset(assetTag);
        if existingErr is error {
            return dbError(existingErr);
        }
        Asset? existing = <Asset?>existingErr;
        if existing !is Asset {
            return notFound("No asset with tag '" + assetTag + "'.");
        }
        [int, WorkOrder]? result = findWorkOrder(existing, orderId);
        if result !is [int, WorkOrder] {
            return notFound("No work order '" + orderId + "' on asset '" + assetTag + "'.");
        }
        error? e = dbInsertTask(assetTag, orderId, task);
        if e is error {
            return dbError(e);
        }
        existing.workOrders[result[0]].tasks.push(task);
        return existing;
    }

    // Remove a sub-task from a work order.
    resource function delete assets/[string assetTag]/workorders/[string orderId]/tasks/[string taskId]()
            returns Asset|http:NotFound|http:InternalServerError {
        var existingErr = dbGetAsset(assetTag);
        if existingErr is error {
            return dbError(existingErr);
        }
        Asset? existing = <Asset?>existingErr;
        if existing !is Asset {
            return notFound("No asset with tag '" + assetTag + "'.");
        }
        [int, WorkOrder]? orderResult = findWorkOrder(existing, orderId);
        if orderResult !is [int, WorkOrder] {
            return notFound("No work order '" + orderId + "' on asset '" + assetTag + "'.");
        }
        var removedErr = dbDeleteTask(assetTag, orderId, taskId);
        if removedErr is error {
            return dbError(removedErr);
        }
        int removed = <int>removedErr;
        if removed == 0 {
            return notFound("No task '" + taskId + "' on work order '" + orderId + "'.");
        }
        Task[] remaining = [];
        foreach var t in existing.workOrders[orderResult[0]].tasks {
            if t.taskId != taskId {
                remaining.push(t);
            }
        }
        existing.workOrders[orderResult[0]].tasks = remaining;
        return existing;
    }

    // ---------- Institution management ----------

    // Register an institution.
    resource function post institutions(@http:Payload Institution institution)
            returns Institution|http:Conflict|http:BadRequest|http:InternalServerError {
        if institution.name.trim() == "" {
            return badRequest("Institution name must not be empty.");
        }
        var existsErr = dbInstitutionExists(institution.name);
        if existsErr is error {
            return dbError(existsErr);
        }
        boolean exists = <boolean>existsErr;
        if exists {
            return conflictError("Institution '" + institution.name + "' is already registered.");
        }
        error? e = dbInsertInstitution(institution);
        if e is error {
            return dbError(e);
        }
        return institution;
    }

    // List all registered institutions.
    resource function get institutions() returns Institution[]|http:InternalServerError {
        var resultVal = dbAllInstitutions();
        if resultVal is error {
            return dbError(resultVal);
        }
        return resultVal;
    }

    // Remove an institution from the listings.
    resource function delete institutions/[string name]()
            returns Institution|http:NotFound|http:InternalServerError {
        var removedErr = dbDeleteInstitution(name);
        if removedErr is error {
            return dbError(removedErr);
        }
        Institution? removed = <Institution?>removedErr;
        if removed is Institution {
            return removed;
        }
        return notFound("No institution named '" + name + "'.");
    }
}

// ---------- Shared helpers ----------

function today() returns string {
    return <string>time:utcToString(time:utcNow()).substring(0, 10);
}

function notFound(string message) returns http:NotFound {
    return {body: {message: message}};
}

function conflictError(string message) returns http:Conflict {
    return {body: {message: message}};
}

function badRequest(string message) returns http:BadRequest {
    return {body: {message: message}};
}

function dbError(error e) returns http:InternalServerError {
    return {body: {message: "Database error: " + e.message()}};
}

function findSchedule(Asset asset, string scheduleId) returns [int, Schedule]? {
    foreach int i in 0 ..< asset.schedules.length() {
        if asset.schedules[i].scheduleId == scheduleId {
            return [i, asset.schedules[i]];
        }
    }
    return ();
}

function findWorkOrder(Asset asset, string orderId) returns [int, WorkOrder]? {
    foreach int i in 0 ..< asset.workOrders.length() {
        if asset.workOrders[i].orderId == orderId {
            return [i, asset.workOrders[i]];
        }
    }
    return ();
}
