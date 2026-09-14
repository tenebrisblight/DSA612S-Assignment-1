import ballerina/http;
import ballerina/io;


final http:Client api = check new ("http://localhost:8090/ministry/api");

public function main() returns error? {
while true {
    printMenu();
    string choice = io:readln("Select an option: ").trim();
    if choice == "1" {
        error? _r = globalView();
    } else if choice == "2" {
        error? _r = campusView();
    } else if choice == "3" {
        error? _r = loanAsset();
    } else if choice == "4" {
        error? _r = returnLoan();
    } else if choice == "5" {
        error? _r = bookRoom();
    } else if choice == "6" {
        error? _r = overdueDashboard();
    } else if choice == "7" {
        error? _r = scheduleManager();
    } else if choice == "8" {
        error? _r = workOrderManager();
    } else if choice == "9" {
        error? _r = manageAssets();
    } else if choice == "10" {
        error? _r = manageInstitutions();
    } else if choice == "0" {
        io:println("Goodbye!");
        return;
    } else {
        io:println("Invalid option, please try again.");
    }
}
}


function printMenu() {
io:println("\n==========================================================");
io:println(" Ministry Library & Resource Management System - Client");
io:println("==========================================================");
io:println(" 1. Global view           (all assets)");
io:println(" 2. Campus view           (filter by institution/site)");
io:println(" 3. Loan an asset");
io:println(" 4. Return a loaned asset");
io:println(" 5. Book a meeting room / lab");
io:println(" 6. Overdue dashboard");
io:println(" 7. Schedule manager      (add/modify/remove schedules)");
io:println(" 8. Work orders           (open/update/close + tasks)");
io:println(" 9. Asset management      (add/update/remove/lookup)");
io:println(" 10. Institution manager  (register/remove institutions)");
io:println(" 0. Exit");
}

//Shared helpers

function ask(string prompt) returns string {
return io:readln(prompt).trim();
}

//encode a path segment.
function urlEncode(string value) returns string {
string encoded = "";
foreach int i in 0 ..< value.length() {
string c = value[i];
if (c >= "a" && c <= "z") || (c >= "A" && c <= "Z") || (c >= "0" && c <= "9")
   || c == "-" || c == "_" || c == "." || c == "~" {
    encoded += c;

} else {
foreach int b in c.toBytes() {
string hex = b.toHexString().toLowerAscii();
if hex.length() < 2 {
    hex = "0" + hex;
}
    encoded += "%" + hex;
}
}
}
 return encoded;
}

function getJson(string path) returns json|error {
http:Response resp = check api->get(path);
return check resp.getJsonPayload();
}

// Print a service error payload of the shape.
function reportError(json body, int status) {
string message = "Request failed (HTTP " + status.toString() + ")";
if body is map<json> {
json? msg = body["message"];
if msg is string {
    message = msg;
    }
}
io:println("  ERROR: " + message);
}

// render a json field as a string.
function statusOf(json value) returns string {
if value is string {
 return value;
}
return value.toString();
}

// Safely read a string field from a json object payload.
function jsonToStringField(json body, string fieldName) returns string {
if body is map<json> {
    json? value = body[fieldName];
    if value is string {
    return value;
   }
}
 return "";
}

function printAssets(Asset[] list) {
if list.length() == 0 {
    io:println("  (no assets found)");
    return;
}
foreach Asset a in list {
    io:println("  [" + a.assetTag + "] " + a.name +
        "\n      Institution: " + a.institution +
        " | Site: " + a.site +
        "\n      Status: " + a.status +
        " | Acquired: " + a.dateAcquired +
        "\n      " + a.description);
    if a.schedules.length() > 0 {
        io:println("      Schedules:");
        foreach Schedule s in a.schedules {
            io:println("        - " + s.scheduleId + " (" + s.'type +
                ", due " + s.dueDate + "): " + s.description);
        }
    }
    if a.workOrders.length() > 0 {
         io:println("      Work orders:");
        foreach WorkOrder w in a.workOrders {
            io:println("        - " + w.orderId + " [" + w.status + "]: " + w.description);
            foreach Task t in w.tasks {
                io:println("            * " + t.taskId + ": " + t.description);
            }
        }
    }
    io:println("");
}
}

//1. Global view

function globalView() returns error? {
    Asset[] list = check (check getJson("/assets")).cloneWithType();
    io:println("\n--- GLOBAL VIEW: all assets across the ministry ---");
    printAssets(list);
}

//2. Campus view

function campusView() returns error? {
    Institution[] institutions = check (check getJson("/institutions")).cloneWithType();
    io:println("\nRegistered institutions:");
    foreach Institution i in institutions {
        io:println("  - " + i.name + " (" + i.location + ")");
    }
    string institution = ask("Institution (or leave blank for all): ");
    if institution == "" {
        error? _r = globalView();
        return;
    }
    string site = ask("Site/campus (or leave blank for whole institution): ");
    string path;
    if site == "" {
        path = "/assets/institution/" + urlEncode(institution);
    } else {
        path = "/assets/institution/" + urlEncode(institution) +
                "/site/" + urlEncode(site);
    }
    Asset[] list = check (check getJson(path)).cloneWithType();
    io:println("\n--- CAMPUS VIEW ---");
    printAssets(list);
}

// 3 & 4. Loans

function loanAsset() returns error? {
    string tag = ask("Asset tag to loan: ");
    http:Response resp = check api->post("/assets/" + urlEncode(tag) + "/loan", ());
    json body = check resp.getJsonPayload();
    if resp.statusCode >= 200 && resp.statusCode < 300 {
        io:println("  Loaned out. Status is now " + statusOf(body));
    } else {
        reportError(body, resp.statusCode);
    }
}

function returnLoan() returns error? {
    string tag = ask("Asset tag to return: ");
    http:Response resp = check api->post("/assets/" + urlEncode(tag) + "/returnLoan", ());
    json body = check resp.getJsonPayload();
    if resp.statusCode >= 200 && resp.statusCode < 300 {
        io:println("  Returned. Status is now " + statusOf(body));
    } else {
        reportError(body, resp.statusCode);
    }
}

//5. Bookinn

function bookRoom() returns error? {
    string tag = ask("Room/lab tag to book: ");
    string date = ask("Booking date (YYYY-MM-DD): ");
    string description = ask("Description (optional): ");
    BookingRequest payload = {date: date};
    if description != "" {
        payload.description = description;
    }
    http:Response resp = check api->post("/assets/" + urlEncode(tag) + "/booking", payload);
    json body = check resp.getJsonPayload();
    if resp.statusCode >= 200 && resp.statusCode < 300 {
        io:println("  Booked. Room is now " + statusOf(body) + " and a BOOKING schedule was added.");
    } else {
        reportError(body, resp.statusCode);
    }
}

//6. Overdue dashboard

function overdueDashboard() returns error? {
    OverdueItem[] overdue = check (check getJson("/assets/overdue")).cloneWithType();
    io:println("\n--- OVERDUE DASHBOARD  ---");
    if overdue.length() == 0 {
        io:println("  Nothing is overdue. All good!");
        return;
    }
    foreach OverdueItem item in overdue {
        io:println("  [" + item.assetTag + "] " + item.assetName + " @ " + item.institution +"\n      " + item.scheduleId + " (" + item.'type + ") was due " + item.dueDate +": " + item.description + "\n");
    }
}

//7. Schedule manager

function scheduleManager() returns error? {
    string tag = ask("Asset tag: ");
    http:Response resp = check api->get("/assets/" + urlEncode(tag));
    json body = check resp.getJsonPayload();
    if !(resp.statusCode >= 200 && resp.statusCode < 300) {
        reportError(body, resp.statusCode);
        return;
    }
    Asset asset = check body.cloneWithType();
    io:println("Schedules on " + asset.name + ":");
    if asset.schedules.length() == 0 {
        io:println("  (none)");
    }
    foreach Schedule s in asset.schedules {
        io:println("  - " + s.scheduleId + " (" + s.'type + ", due " + s.dueDate +
            "): " + s.description);
    }
    io:println("\n a. Add schedule   b. Modify schedule   c. Remove schedule");
    string action = ask("Action: ").toLowerAscii();
    if action == "a" {
        error? _r = addSchedule(tag);
    } else if action == "b" {
        error? _r = modifySchedule(tag);
    } else if action == "c" {
        error? _r = removeSchedule(tag);
    }
}

function addSchedule(string tag) returns error? {
    string id = ask("New scheduleId: ");
    string typeIn = ask("Type (MAINTENANCE/SERVICING/BOOKING): ").toUpperAscii();
    string dueDate = ask("Due date (YYYY-MM-DD): ");
    string description = ask("Description: ");
    ScheduleType? scheduleType = check typeIn.cloneWithType();
    if scheduleType is () {
        io:println("  ERROR: type must be MAINTENANCE, SERVICING or BOOKING.");
        return;
    }
Schedule schedule = {
    scheduleId: id,
    'type: scheduleType,
    dueDate: dueDate,
    description: description
};
http:Response resp = check api->post("/assets/" + urlEncode(tag) + "/schedules", schedule);
json body = check resp.getJsonPayload();
if resp.statusCode >= 200 && resp.statusCode < 300 {
    io:println("  Schedule added.");
} else {
    reportError(body, resp.statusCode);
 }
}

function modifySchedule(string tag) returns error? {
string id = ask("scheduleId to modify: ");
string dueDate = ask("New due date (blank to keep): ");
string description = ask("New description (blank to keep): ");
ScheduleUpdate update = {};
if dueDate != "" {
    update.dueDate = dueDate;
}
if description != "" {
    update.description = description;
}
http:Response resp = check api->put(
    "/assets/" + urlEncode(tag) + "/schedules/" + urlEncode(id), update);
json body = check resp.getJsonPayload();
if resp.statusCode >= 200 && resp.statusCode < 300 {
    io:println("  Schedule updated.");
} else {
    reportError(body, resp.statusCode);
}
}

function removeSchedule(string tag) returns error? {
string id = ask("scheduleId to remove: ");
http:Response resp = check api->delete(
    "/assets/" + urlEncode(tag) + "/schedules/" + urlEncode(id));
json body = check resp.getJsonPayload();
if resp.statusCode >= 200 && resp.statusCode < 300 {
    io:println("  Schedule removed.");
} else {
    reportError(body, resp.statusCode);
 }
}

// 8. Work orders

function workOrderManager() returns error? {
string tag = ask("Asset tag: ");
io:println("\n a. Open work order\n b. Update work order status\n c. Add task\n d. Remove task");
string action = ask("Action: ").toLowerAscii();
if action == "a" {
    error? _r = openWorkOrder(tag);
} else if action == "b" {
    error? _r = updateWorkOrder(tag);
} else if action == "c" {
    error? _r = addTask(tag);
} else if action == "d" {
    error? _r = removeTask(tag);
}
}

function openWorkOrder(string tag) returns error? {
string id = ask("New orderId: ");
string description = ask("Fault description: ");
WorkOrder workOrder = {orderId: id, status: OPEN, description: description};
http:Response resp = check api->post("/assets/" + urlEncode(tag) + "/workorders", workOrder);
json body = check resp.getJsonPayload();
if resp.statusCode >= 200 && resp.statusCode < 300 {
    io:println("  Work order opened (asset moved to UNDER_MAINTENANCE if it was AVAILABLE).");
} else {
    reportError(body, resp.statusCode);
}
}

function updateWorkOrder(string tag) returns error? {
string id = ask("orderId: ");
string status = ask("New status (OPEN/IN_PROGRESS/CLOSED): ").toUpperAscii();
WorkOrderStatus? woStatus = check status.cloneWithType();
if woStatus is () {
    io:println("  ERROR: status must be OPEN, IN_PROGRESS or CLOSED.");
    return;
}
WorkOrderUpdate update = {status: woStatus};
http:Response resp = check api->put(
    "/assets/" + urlEncode(tag) + "/workorders/" + urlEncode(id), update);
json body = check resp.getJsonPayload();
if resp.statusCode >= 200 && resp.statusCode < 300 {
    io:println("  Work order updated.");
} else {
    reportError(body, resp.statusCode);
}
}

function addTask(string tag) returns error? {
string id = ask("orderId: ");
string taskId = ask("New taskId: ");
string description = ask("Task description (e.g. replace screen): ");
http:Response resp = check api->post(
    "/assets/" + urlEncode(tag) + "/workorders/" + urlEncode(id) + "/tasks",
    {taskId: taskId, description: description});
json body = check resp.getJsonPayload();
if resp.statusCode >= 200 && resp.statusCode < 300 {
    io:println("  Task added.");
} else {
    reportError(body, resp.statusCode);
}
}

function removeTask(string tag) returns error? {
string id = ask("orderId: ");
string taskId = ask("taskId to remove: ");
http:Response resp = check api->delete(
    "/assets/" + urlEncode(tag) + "/workorders/" + urlEncode(id) +
    "/tasks/" + urlEncode(taskId));
json body = check resp.getJsonPayload();
if resp.statusCode >= 200 && resp.statusCode < 300 {
    io:println("  Task removed.");
} else {
    reportError(body, resp.statusCode);
}
}

//9. Asset managemen

function manageAssets() returns error? {
io:println("\n a. Add asset\n b. Look up asset\n c. Update asset\n d. Remove asset");
string action = ask("Action: ").toLowerAscii();
if action == "a" {
    error? _r = addAsset();
} else if action == "b" {
    error? _r = lookUpAsset();
} else if action == "c" {
    error? _r = updateAsset();
} else if action == "d" {
    error? _r = removeAsset();
}
}

function addAsset() returns error? {
    string tag = ask("assetTag: ");
    string name = ask("name: ");
    string description = ask("description: ");
    string institution = ask("institution: ");
    string site = ask("site/campus: ");
    string status = ask("status (AVAILABLE/LOANED_OUT/OCCUPIED/UNDER_MAINTENANCE/DISPOSED): ").toUpperAscii();
    string dateAcquired = ask("date acquired (YYYY-MM-DD): ");
    AssetStatus assetStatus = check status.cloneWithType();
    Asset asset = {
    assetTag: tag,
    name: name,
    description: description,
    institution: institution,
    site: site,
    status: assetStatus,
    dateAcquired: dateAcquired
    };
    http:Response resp = check api->post("/assets", asset);
    json body = check resp.getJsonPayload();
    if resp.statusCode == 201 {
        io:println("  Asset '" + tag + "' created.");
    } else {
        reportError(body, resp.statusCode);
    }
}

function lookUpAsset() returns error? {
    string tag = ask("assetTag: ");
    http:Response resp = check api->get("/assets/" + urlEncode(tag));
    json body = check resp.getJsonPayload();
    if resp.statusCode >= 200 && resp.statusCode < 300 {
        Asset asset = check body.cloneWithType();
        printAssets([asset]);
    } else {
        reportError(body, resp.statusCode);
    }
}

function updateAsset() returns error? {
    string tag = ask("assetTag to update: ");
    string name = ask("New name: ");
    string site = ask("New site/campus: ");
    string status = ask("New status: ").toUpperAscii();
    AssetUpdate update = {};
    if name != "" {
        update.name = name;
    }
    if site != "" {
        update.site = site;
    }
    if status != "" {
    AssetStatus? assetStatus = check status.cloneWithType();
    if assetStatus is () {
        io:println("  ERROR: invalid status value.");
        return;
    }
        update.status = assetStatus;
    }
    http:Response resp = check api->put("/assets/" + urlEncode(tag), update);
    json body = check resp.getJsonPayload();
    if resp.statusCode >= 200 && resp.statusCode < 300 {
    io:println("  Assetm has been updated: " + jsonToStringField(body, "name") + " @ " +
        jsonToStringField(body, "site") + " (" + jsonToStringField(body, "status") + ")");
    } else {
        reportError(body, resp.statusCode);
    }
}

function removeAsset() returns error? {
    string tag = ask("asset tag to remove: ");
    http:Response resp = check api->delete("/assets/" + urlEncode(tag));
    json body = check resp.getJsonPayload();
    if resp.statusCode >= 200 && resp.statusCode < 300 {
        io:println("  Asset has been removed.");
    } else {
        reportError(body, resp.statusCode);
    }
}

//10. Institutions

function manageInstitutions() returns error? {
    io:println("\n a. List institutions\n b. Register institution\n c. Remove institution");
    string action = ask("Action: ").toLowerAscii();
    if action == "a" {
        Institution[] institutions = check (check getJson("/institutions")).cloneWithType();
        foreach Institution i in institutions {
            io:println("  - " + i.name + " (" + i.location + ")");
        }
    } else if action == "b" {
    string name = ask("Institution name: ");
    string location = ask("Location: ");
    http:Response resp = check api->post("/institutions", {name: name, location: location});
    json body = check resp.getJsonPayload();
    if resp.statusCode == 201 {
        io:println("  Institution has been registered.");
    } else {
        reportError(body, resp.statusCode);
    }
    } else if action == "c" {
    string name = ask("Institution  to remove: ");
    http:Response resp = check api->delete("/institutions/" + urlEncode(name));
    json body = check resp.getJsonPayload();
    if resp.statusCode >= 200 && resp.statusCode < 300 {
        io:println("  Institution has been removed.");
    } else {
        reportError(body, resp.statusCode);
    }
    }
}
