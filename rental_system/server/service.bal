import ballerina/grpc;
import ballerina/uuid;

// gRPC backend for the Ministry Rental Accommodation System.
// Message types + the wire descriptor come from rental_service_pb.bal,

// Port 9090 so this can run alongside the library API on 8090.

listener grpc:Listener grpcListener = new (9090);

function init() returns error? {
    // same boot order as the library service: tables first, seed on first run
    check initSchema();
    check dbSeedIfEmpty();
}


function shortId(string prefix) returns string {
    return prefix + "-" + uuid:createType1AsString();
}


function propFail(string msg) returns PropertyResponse =>
    {success: false, message: msg, property: {}};

function bookFail(string msg) returns BookPropertyResponse =>
    {success: false, message: msg, requestId: ""};

function confirmFail(string msg) returns ConfirmBookingResponse =>
    {success: false, message: msg, bookingId: "", nights: 0, totalCost: 0.0};

@grpc:Descriptor {value: RENTAL_SERVICE_DESC}
service "RentalService" on grpcListener {

    remote function addProperty(PropertyRequest req) returns PropertyResponse|error {
        if req.hostId.trim() == "" {
            return propFail("hostId is required.");
        }
        if req.name.trim() == "" || req.location.trim() == "" {
            return propFail("name and location are required.");
        }
        Property newProp = {
            propertyId: shortId("PROP"),
            hostId: req.hostId,
            name: req.name,
            location: req.location,
            propertyType: req.propertyType,
            pricePerNight: req.pricePerNight,
            // no whitelist on status — whatever the client sends lands in
            // the db verbatim, and only 'AVAILABLE' shows up in listings.
            // TODO: tighten to AVAILABLE/UNAVAILABLE before some third
            // value sneaks in and silently vanishes from searches
            status: req.status.trim() == "" ? "AVAILABLE" : req.status,
            description: req.description
        };
        check dbInsertProperty(newProp);
        return {success: true, message: "Property registered.", property: newProp};
    }

    // client-streaming: the tester pushes N UserRequests down one call and
    // gets a single roll-up back. The `check` inside the query aborts on
    // the first bad row, so usersCreated doubles as "how far we got".
    remote function createUsers(stream<UserRequest, grpc:Error?> clientStream) returns UserStreamResponse|error {
        string[] ids = [];
        error? streamErr = from UserRequest u in clientStream
            do {
                string userId = shortId("USR");
                check dbInsertUser({userId: userId, name: u.name, email: u.email, role: u.role});
                ids.push(userId);
            };
        if streamErr is error {
            return {
                success: false,
                usersCreated: ids.length(),
                message: "Stopped after error: " + streamErr.message(),
                userIds: ids
            };
        }
        return {
            success: true,
            usersCreated: ids.length(),
            message: ids.length().toString() + " user(s) registered.",
            userIds: ids
        };
    }


    remote function updateProperty(UpdatePropertyRequest req) returns PropertyResponse|error {
        Property? current = check dbGetProperty(req.propertyId);
        if current is () {
            return propFail("No property with id '" + req.propertyId + "'.");
        }
        if current.hostId != req.hostId {
            return propFail("Only the owning host may update this property.");
        }
        check dbUpdateProperty(req);
        // read back so the client sees what's actually stored now
        Property? updated = check dbGetProperty(req.propertyId);
        return {success: true, message: "Property updated.", property: updated ?: current};
    }

    // hands back the host's remaining listings so the client can refresh
    
    remote function removeProperty(RemovePropertyRequest req) returns PropertyList|error {
        Property? existing = check dbGetProperty(req.propertyId);
        if existing is () {
            return {success: false, message: "No property with id '" + req.propertyId + "'.", properties: []};
        }
        if existing.hostId != req.hostId {
            return {success: false, message: "Only the owning host may remove this property.", properties: []};
        }
        // cart entries + bookings for this property go via the FK cascade
        check dbDeleteProperty(req.propertyId);
        Property[] remaining = check dbPropertiesByHost(req.hostId);
        return {success: true, message: "Property removed.", properties: remaining};
    }

    // materialise-then-stream: dbAvailableProperties returns the whole list
    
    remote function listAvailableProperties(ListPropertiesRequest req) returns stream<Property, error?>|error {
        Property[] results = check dbAvailableProperties(req.location, req.minPrice, req.maxPrice);
        return results.toStream();
    }

   
    remote function searchProperty(SearchPropertyRequest req) returns SearchPropertyResponse|error {
        Property? found = check dbGetProperty(req.propertyId);
        if found is () {
            return {found: false, status: "Not Available", property: {}};
        }
        return {found: true, status: found.status, property: found};
    }

   
    remote function bookProperty(BookPropertyRequest req) returns BookPropertyResponse|error {
        Property? prop = check dbGetProperty(req.propertyId);
        if prop is () {
            return bookFail("No property with id '" + req.propertyId + "'.");
        }
        if prop.status != "AVAILABLE" {
            return bookFail("Property is not currently available.");
        }
        int|error nights = daysBetween(req.checkIn, req.checkOut);
        if nights is error || nights <= 0 {
            return bookFail("checkOut date must be after checkIn date.");
        }
        string requestId = shortId("REQ");
        check dbInsertCartEntry({
            requestId: requestId,
            propertyId: req.propertyId,
            guestId: req.guestId,
            checkIn: req.checkIn,
            checkOut: req.checkOut
        });
        return {success: true, message: "Added to booking cart - call confirmBooking to finalize.", requestId: requestId};
    }

   
    remote function confirmBooking(ConfirmBookingRequest req) returns ConfirmBookingResponse|error {
        CartEntry? cart = check dbGetCartEntry(req.requestId);
        if cart is () {
            return confirmFail("Booking request not found or already processed.");
        }
        if cart.guestId != req.guestId {
            return confirmFail("This booking request does not belong to you.");
        }
        Property? prop = check dbGetProperty(cart.propertyId);
        if prop is () {
            // property deleted out from under the cart — drop the entry so
            // a retry at least takes the clean "not found" path
            check dbDeleteCartEntry(req.requestId);
            return confirmFail("Property no longer exists.");
        }
        boolean overlap = check dbHasOverlap(cart.propertyId, cart.checkIn, cart.checkOut);
        if overlap {
            
            return confirmFail("Property is no longer available for those dates.");
        }
        int nights = check daysBetween(cart.checkIn, cart.checkOut);
        
        float totalCost = <float>nights * prop.pricePerNight;
        string bookingId = shortId("BKG");
        check dbInsertBooking({
            bookingId: bookingId,
            propertyId: cart.propertyId,
            guestId: cart.guestId,
            checkIn: cart.checkIn,
            checkOut: cart.checkOut,
            nights: nights,
            totalCost: totalCost
        });
        check dbDeleteCartEntry(req.requestId);
        return {success: true, message: "Booking confirmed.", bookingId: bookingId, nights: nights, totalCost: totalCost};
    }
}
