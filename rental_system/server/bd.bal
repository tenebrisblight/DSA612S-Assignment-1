import ballerina/sql;
import ballerinax/mysql;
import ballerina/time;

// Persistence for the Ministry Rental Accommodation System.
// Runs on its own `rental_accommodation` database, separate from the library
// system's `ministry` db, so the two can be wiped/reset independently.

public type MysqlConfig record {|
    string host = "localhost";
    int port = 3306;
    string user = "root";
    string password = "";
    string database = "rental_accommodation";
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

// Dates are stored as yyyy-MM-dd strings rather than DATE columns: proto

function initSchema() returns error? {
    _ = check db->execute(`
        CREATE TABLE IF NOT EXISTS users (
            user_id VARCHAR(64) PRIMARY KEY,
            name    VARCHAR(255) NOT NULL,
            email   VARCHAR(255) NOT NULL,
            role    VARCHAR(16)  NOT NULL
        )`);
    _ = check db->execute(`
        CREATE TABLE IF NOT EXISTS properties (
            property_id      VARCHAR(64) PRIMARY KEY,
            host_id          VARCHAR(64)  NOT NULL,
            name             VARCHAR(255) NOT NULL,
            location         VARCHAR(255) NOT NULL,
            property_type    VARCHAR(64)  NOT NULL,
            price_per_night  DOUBLE       NOT NULL,
            status           VARCHAR(32)  NOT NULL,
            description      TEXT
        )`);
   
    _ = check db->execute(`
        CREATE TABLE IF NOT EXISTS booking_cart (
            request_id  VARCHAR(64) PRIMARY KEY,
            property_id VARCHAR(64) NOT NULL,
            guest_id    VARCHAR(64) NOT NULL,
            check_in    VARCHAR(10) NOT NULL,
            check_out   VARCHAR(10) NOT NULL,
            FOREIGN KEY (property_id) REFERENCES properties(property_id) ON DELETE CASCADE
        )`);
    _ = check db->execute(`
        CREATE TABLE IF NOT EXISTS bookings (
            booking_id  VARCHAR(64) PRIMARY KEY,
            property_id VARCHAR(64) NOT NULL,
            guest_id    VARCHAR(64) NOT NULL,
            check_in    VARCHAR(10) NOT NULL,
            check_out   VARCHAR(10) NOT NULL,
            nights      INT         NOT NULL,
            total_cost  DOUBLE      NOT NULL,
            FOREIGN KEY (property_id) REFERENCES properties(property_id) ON DELETE CASCADE
        )`);
}

//row / internal types


type PropertyRow record {|
    string property_id;
    string host_id;
    string name;
    string location;
    string property_type;
    float price_per_night;
    string status;
    string? description;
|};

type UserRow record {|
    string user_id;
    string name;
    string email;
    string role;
|};


public type CartEntry record {|
    string requestId;
    string propertyId;
    string guestId;
    string checkIn;
    string checkOut;
|};

type CartRow record {|
    string request_id;
    string property_id;
    string guest_id;
    string check_in;
    string check_out;
|};


public type BookingInsert record {|
    string bookingId;
    string propertyId;
    string guestId;
    string checkIn;
    string checkOut;
    int nights;
    float totalCost;
|};

//properties

function rowToProperty(PropertyRow r) returns Property => {
    propertyId: r.property_id,
    hostId: r.host_id,
    name: r.name,
    location: r.location,
    propertyType: r.property_type,
    pricePerNight: r.price_per_night,
    status: r.status,
    description: r.description ?: ""
};

function dbInsertProperty(Property p) returns error? {
    _ = check db->execute(`
        INSERT INTO properties (property_id, host_id, name, location, property_type, price_per_night, status, description)
        VALUES (${p.propertyId}, ${p.hostId}, ${p.name}, ${p.location}, ${p.propertyType}, ${p.pricePerNight}, ${p.status}, ${p.description})`);
}

// PK lookup: grab the first row (there can only be one) and stop reading
function dbGetProperty(string propertyId) returns Property?|error {
    stream<PropertyRow, sql:Error?> rows = db->query(`
        SELECT property_id, host_id, name, location, property_type, price_per_night, status, description
        FROM properties WHERE property_id = ${propertyId}`);
    var first = check rows.next();
    _ = rows.close();
    if first is () {
        return ();
    }
    return rowToProperty(first.value);
}

function dbPropertiesByHost(string hostId) returns Property[]|error {
    stream<PropertyRow, sql:Error?> rows = db->query(`
        SELECT property_id, host_id, name, location, property_type, price_per_night, status, description
        FROM properties WHERE host_id = ${hostId} ORDER BY property_id`);
    return check from PropertyRow r in rows
           select rowToProperty(r);
}



function dbAvailableProperties(string location, float minPrice, float maxPrice)
        returns Property[]|error {
    // compare the trimmed value so " Windhoek" from a form still matches
    string loc = location.trim();
    stream<PropertyRow, sql:Error?> rows = db->query(`
        SELECT property_id, host_id, name, location, property_type, price_per_night, status, description
        FROM properties
        WHERE status = 'AVAILABLE'
          AND (${loc} = '' OR location = ${loc})
          AND (${minPrice} = 0 OR price_per_night >= ${minPrice})
          AND (${maxPrice} = 0 OR price_per_night <= ${maxPrice})
        ORDER BY property_id`);
    Property[] out = [];
    while true {
        var next = check rows.next();
        if next is () {
            break;
        }
        out.push(rowToProperty(next.value));
    }
    return out;
}


function dbUpdateProperty(UpdatePropertyRequest req) returns error? {
    _ = check db->execute(`
        UPDATE properties SET
            name            = COALESCE(${req.name}, name),
            description     = COALESCE(${req.description}, description),
            price_per_night = COALESCE(${req.pricePerNight}, price_per_night),
            status          = COALESCE(${req.status}, status)
        WHERE property_id = ${req.propertyId}`);
}


function dbDeleteProperty(string propertyId) returns error? {
    _ = check db->execute(`DELETE FROM properties WHERE property_id = ${propertyId}`);
}

// ---------- users ----------


function dbInsertUser(User u) returns error? {
    _ = check db->execute(`
        INSERT INTO users (user_id, name, email, role)
        VALUES (${u.userId}, ${u.name}, ${u.email}, ${u.role})`);
}

// ---------- booking cart ----------

function rowToCart(CartRow r) returns CartEntry => {
    requestId: r.request_id,
    propertyId: r.property_id,
    guestId: r.guest_id,
    checkIn: r.check_in,
    checkOut: r.check_out
};

function dbInsertCartEntry(CartEntry c) returns error? {
    _ = check db->execute(`
        INSERT INTO booking_cart (request_id, property_id, guest_id, check_in, check_out)
        VALUES (${c.requestId}, ${c.propertyId}, ${c.guestId}, ${c.checkIn}, ${c.checkOut})`);
}

function dbGetCartEntry(string requestId) returns CartEntry?|error {
    
    stream<CartRow, sql:Error?> rows = db->query(`
        SELECT request_id, property_id, guest_id, check_in, check_out
        FROM booking_cart WHERE request_id = ${requestId}`);
    var first = check rows.next();
    _ = rows.close();
    if first is () {
        return ();
    }
    return rowToCart(first.value);
}


function dbDeleteCartEntry(string requestId) returns error? {
    _ = check db->execute(`DELETE FROM booking_cart WHERE request_id = ${requestId}`);
}

//bookings

function dbInsertBooking(BookingInsert b) returns error? {
    _ = check db->execute(`
        INSERT INTO bookings (booking_id, property_id, guest_id, check_in, check_out, nights, total_cost)
        VALUES (${b.bookingId}, ${b.propertyId}, ${b.guestId}, ${b.checkIn}, ${b.checkOut}, ${b.nights}, ${b.totalCost})`);
}



function dbHasOverlap(string propertyId, string checkIn, string checkOut) returns boolean|error {
    // COUNT(*) always returns exactly one row
    stream<record {| int cnt; |}, sql:Error?> rows = db->query(`
        SELECT COUNT(*) AS cnt FROM bookings
        WHERE property_id = ${propertyId}
          AND NOT (check_out <= ${checkIn} OR check_in >= ${checkOut})`);
    var first = check rows.next();
    _ = rows.close();
    if first is () {
        // unreachable for a COUNT, but the type system can't know that
        return false;
    }
    return first.value.cnt > 0;
}

//date helpers


function parseDate(string dateStr) returns time:Utc|error {
    return time:utcFromString(dateStr + "T00:00:00.00Z");
}


function daysBetween(string checkIn, string checkOut) returns int|error {
    time:Utc inUtc = check parseDate(checkIn);
    time:Utc outUtc = check parseDate(checkOut);
    decimal diffSeconds = time:utcDiffSeconds(outUtc, inUtc);
    return <int>(diffSeconds / 86400);
}

//seed


function dbSeedIfEmpty() returns error? {
    stream<PropertyRow, sql:Error?> probe = db->query(`
        SELECT property_id, host_id, name, location, property_type, price_per_night, status, description
        FROM properties LIMIT 1`);
    var first = check probe.next();
    _ = probe.close();
    if !(first is ()) {
        return; // already seeded
    }

    User[] seedUsers = [
        {userId: "USR-HOST01", name: "Anna Kavari", email: "anna.kavari@example.com", role: "HOST"},
        {userId: "USR-GUEST01", name: "Peter Amutse", email: "peter.amutse@example.com", role: "GUEST"}
    ];
    foreach User u in seedUsers {
        check dbInsertUser(u);
    }

    Property[] seedProperties = [
        {
            propertyId: "PROP-0001",
            hostId: "USR-HOST01",
            name: "Seaside Studio Apartment",
            location: "Swakopmund",
            propertyType: "Apartment",
            pricePerNight: 850.0,
            status: "AVAILABLE",
            description: "Cosy self-catering studio, 5 minutes from the beach."
        },
        {
            propertyId: "PROP-0002",
            hostId: "USR-HOST01",
            name: "Windhoek City Loft",
            location: "Windhoek",
            propertyType: "Loft",
            pricePerNight: 1200.0,
            status: "AVAILABLE",
            description: "Modern loft in the city centre, walking distance to Independence Ave."
        },
        {
            propertyId: "PROP-0003",
            hostId: "USR-HOST01",
            name: "Desert View Cabin",
            location: "Sossusvlei",
            propertyType: "Cabin",
            pricePerNight: 1800.0,
            status: "UNAVAILABLE",
            description: "Off-grid cabin with a private deck overlooking the dunes."
        }
    ];
    foreach Property p in seedProperties {
        check dbInsertProperty(p);
    }
}
