import ballerina/io;
import ballerina/grpc;

final RentalServiceClient rentalClient = check new ("http://localhost:9090");

public function main() returns error? {
    while true {
    printMenu();
    string choice = ask("Select an option: ");
    if choice == "1" {
        error? _r = addPropertyFlow();
        reportIfError(_r);
    } else if choice == "2" {
        error? _r = createUsersFlow();
        reportIfError(_r);
    } else if choice == "3" {
        error? _r = updatePropertyFlow();
        reportIfError(_r);
    } else if choice == "4" {
        error? _r = removePropertyFlow();
        reportIfError(_r);
    } else if choice == "5" {
        error? _r = listAvailableFlow();
        reportIfError(_r);
    } else if choice == "6" {
        error? _r = searchPropertyFlow();
        reportIfError(_r);
    } else if choice == "7" {
        error? _r = bookPropertyFlow();
        reportIfError(_r);
    } else if choice == "8" {
        error? _r = confirmBookingFlow();
        reportIfError(_r);
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
    io:println(" Ministry of Tourism - Rental Accommodation System ");
    io:println("==========================================================");
    io:println(" 1. Add property               ");
    io:println(" 2. Register users in bulk     ");
    io:println(" 3. Update property            ");
    io:println(" 4. Remove property            ");
    io:println(" 5. List available properties  ");
    io:println(" 6. Search property by ID");
    io:println(" 7. Book a property             ");
    io:println(" 8. Confirm a booking");
    io:println(" 0. Exit");
}

//Shared helpers/resources

function ask(string prompt) returns string {
return io:readln(prompt).trim();
}

function askFloat(string prompt) returns float|error {
return float:fromString(ask(prompt));
}

function reportIfError(error? e) {
if e is error {
    io:println("Request failed: ", e.message());
}
}

// Adding properties

function addPropertyFlow() returns error? {
    string hostId = ask("Host ID: ");
    string name = ask("Property name: ");
    string location = ask("Location: ");
    string propertyType = ask("Property type: ");
    float price = check askFloat("Price per night: ");
    string description = ask("Description: ");

    PropertyResponse resp = check rentalClient->addProperty({
        hostId: hostId,
        name: name,
        location: location,
        propertyType: propertyType,
        pricePerNight: price,
        status: "AVAILABLE",
        description: description
    });
    if resp.success {
        io:println("Registered. Property ID: ", resp.property.propertyId);
    } else {
        io:println("Failed: ", resp.message);
    }
}

// Creating users

function createUsersFlow() returns error? {
    int count = check int:fromString(ask("How many users to register? "));

    CreateUsersStreamingClient streamingClient = check rentalClient->createUsers();
    foreach int i in 1 ... count {
        string name = ask(string `User ${i} name: `);
        string email = ask(string `User ${i} email: `);
        string role = ask(string `User ${i} role: `);
        check streamingClient->sendUserRequest({name: name, email: email, role: role});
    }
    check streamingClient->complete();

    UserStreamResponse? resp = check streamingClient->receiveUserStreamResponse();
    if resp is UserStreamResponse {
        io:println(resp.message);
        io:println("Assigned IDs: ", resp.userIds.toString());
    } else {
        io:println("No confirmation received from server.");
    }
}

// updating property

function updatePropertyFlow() returns error? {
    string propertyId = ask("Property ID: ");
    string hostId = ask("Host ID: ");
    string priceStr = ask("New price per night: ");
    string status = ask("New status AVAILABLE/OCCUPIED/UNAVAILABLE: ");
    string name = ask("New name: ");
    string description = ask("New description: ");

    UpdatePropertyRequest req = {propertyId: propertyId, hostId: hostId};
    if priceStr != "" {
        req.pricePerNight = check float:fromString(priceStr);
    }
    if status != "" {
        req.status = status;
    }
    if name != "" {
        req.name = name;
    }
    if description != "" {
        req.description = description;
    }

    PropertyResponse resp = check rentalClient->updateProperty(req);
    if resp.success {
        io:println("Updated: ", resp.property.toString());
    } else {
        io:println("Failed: ", resp.message);
    }
}

// removing properties

function removePropertyFlow() returns error? {
    string propertyId = ask("Property ID: ");
    string hostId = ask("Host ID (must match owner): ");

    PropertyList resp = check rentalClient->removeProperty({propertyId: propertyId, hostId: hostId});
    io:println(resp.message);
    if resp.success {
        io:println("Remaining properties for this host:");
        foreach Property p in resp.properties {
            printProperty(p);
        }
    }
}

// listing available properties

function listAvailableFlow() returns error? {
    string location = ask("Filter by location: ");
    string minStr = ask("Min price: ");
    string maxStr = ask("Max price: ");
    float minPrice = minStr == "" ? 0.0 : check float:fromString(minStr);
    float maxPrice = maxStr == "" ? 0.0 : check float:fromString(maxStr);

    stream<Property, grpc:Error?> results = check rentalClient->listAvailableProperties({
        location: location,
        minPrice: minPrice,
        maxPrice: maxPrice
    });

    io:println("\nAvailable properties:");
    int count = 0;
    error? e = results.forEach(function(Property p) {
        printProperty(p);
        count += 1;
    });
    if e is error {
        io:println("Stream ended with error: ", e.message());
    }
    if count == 0 {
        io:println("  (none matched)");
    }
}

function printProperty(Property p) {
    io:println(string `  [${p.propertyId}] ${p.name} - ${p.location} (${p.propertyType})` +
        string ` - N$${p.pricePerNight}/night - ${p.status}`);
}

// searching for properties

function searchPropertyFlow() returns error? {
    string propertyId = ask("Property ID: ");
    SearchPropertyResponse resp = check rentalClient->searchProperty({propertyId: propertyId});
    if resp.found {
        io:println("Status: ", resp.status);
        printProperty(resp.property);
        io:println("Description: ", resp.property.description);
    } else {
        io:println("Status: ", resp.status);
    }
}

// Bookking properties

function bookPropertyFlow() returns error? {
    string propertyId = ask("Property ID: ");
    string guestId = ask("Guest ID: ");
    string checkIn = ask("Check-in date (yyyy-MM-dd): ");
    string checkOut = ask("Check-out date (yyyy-MM-dd): ");

    BookPropertyResponse resp = check rentalClient->bookProperty({
        propertyId: propertyId,
        guestId: guestId,
        checkIn: checkIn,
        checkOut: checkOut
    });
    io:println(resp.message);
    if resp.success {
        io:println("Your booking request ID: ", resp.requestId);
    }
}

// Confirmation of booking

function confirmBookingFlow() returns error? {
    string requestId = ask("Booking request ID: ");
    string guestId = ask("Guest ID: ");

    ConfirmBookingResponse resp = check rentalClient->confirmBooking({requestId: requestId, guestId: guestId});
    io:println(resp.message);
    if resp.success {
    io:println("Booking ID: ", resp.bookingId);
    io:println("Nights: ", resp.nights);
    io:println("Total cost: N$", resp.totalCost);
    }
}
