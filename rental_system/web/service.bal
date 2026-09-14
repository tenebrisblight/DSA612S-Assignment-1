import ballerina/grpc;
import ballerina/http;
import ballerina/sql;
import ballerinax/mysql;


public type MysqlConfig record
 {|
        string host = "localhost";
        int port = 3306;
    string user = "root";
        string password = "";
    string database = "rental_accommodation";
|};

configurable MysqlConfig dbConfig = ?;

final mysql:Client readDb = check new 
(
 host = dbConfig.host,
     port = dbConfig.port,
          user = dbConfig.user,
          password = dbConfig.password,
          database = dbConfig.database
);

final RentalServiceClient rentalClient = check new ("http://localhost:9090");

function serverError(string msg) returns http:InternalServerError => {
    body: {"message": msg}
};

//read-only host listing (direct DB read, see note above)

type PropertyRow record 
{|
    string property_id;
        string host_id;
        string name;
    string location;
      string property_type;
        float price_per_night;
    string status;
        string? description;
|};

function rowToProperty(PropertyRow r) returns Property =>
 {
    propertyId: r.property_id,
      hostId: r.host_id,
          name: r.name,
    location: r.location,
           propertyType: r.property_type,
          pricePerNight: r.price_per_night,
         status: r.status,
     description: r.description ?: ""
};

function propertiesByHost(string hostId) returns Property[]|error {
            stream<PropertyRow, sql:Error?> result = readDb->query(`
                SELECT property_id, host_id, name, location, property_type, price_per_night, status, description
                FROM properties WHERE host_id = ${hostId} ORDER BY property_id`);
    Property[] list = [];
    while true {
        var nextVal = check result.next();
                if nextVal is () {
                    break;
                }
        list.push(rowToProperty(nextVal.value));
    }
    check result.close();
    return list;
}

listener http:Listener webListener = new (8080);

service / on webListener {

    //  frontend
    resource function get .() returns http:Response {
        http:Response res = new;
        res.setTextPayload(INDEX_HTML);
        res.setHeader("Content-Type", "text/html; charset=UTF-8");
        return res;
    }

    // guest: browse available propertie
    resource function get api/properties/available(string? location, float? minPrice, float? maxPrice)
            returns Property[]|http:InternalServerError {
                stream<Property, grpc:Error?>|grpc:Error result = rentalClient->listAvailableProperties({
                    location: location ?: "",
                    minPrice: minPrice ?: 0.0,
                    maxPrice: maxPrice ?: 0.0
                });
        if result is grpc:Error {
            return serverError(result.message());
        }
               Property[] list = [];
        error? e = result.forEach(function(Property p) {
                      list.push(p);
        });
              if e is error {
                   return serverError(e.message());
        }
        return list;
    }

    // host: every property they own, any status 
    resource function get api/properties/host/[string hostId]() returns Property[]|http:InternalServerError {
        Property[]|error result = propertiesByHost(hostId);
        if result is error {
            return serverError(result.message());
        }
        return result;
    }

    //lookup a single property by id 
    resource function get api/properties/[string propertyId]() returns SearchPropertyResponse|http:InternalServerError {
     SearchPropertyResponse|grpc:Error result = rentalClient->searchProperty({propertyId: propertyId});
           if result is grpc:Error {
                return serverError(result.message());
            }
            return result;
    }

    // host: add a property 
    resource function post api/properties(@http:Payload PropertyRequest payload)
            returns PropertyResponse|http:InternalServerError 
            {
            PropertyResponse|grpc:Error result = rentalClient->addProperty(payload);
            if result is grpc:Error {
                return serverError(result.message());
        }
        return result;
    }

    // host: update a property 
    resource function put api/properties/[string propertyId](@http:Payload UpdatePropertyRequest payload)
            returns PropertyResponse|http:InternalServerError {
        UpdatePropertyRequest req = payload;
        req.propertyId = propertyId;
        PropertyResponse|grpc:Error result = rentalClient->updateProperty(req);
        if result is grpc:Error {
            return serverError(result.message());
        }
        return result;
    }

    //host: remove a property 
    resource function delete api/properties/[string propertyId](string hostId)
                    returns PropertyList|http:InternalServerError {
                PropertyList|grpc:Error result = rentalClient->removeProperty({propertyId: propertyId, hostId: hostId});
                if result is grpc:Error {
            return serverError(result.message());
        }
        return result;
    }

    // guest: book a property (adds to cart) 
    resource function post api/bookings(@http:Payload BookPropertyRequest payload)
                    returns BookPropertyResponse|http:InternalServerError {
                BookPropertyResponse|grpc:Error result = rentalClient->bookProperty(payload);
                if result is grpc:Error {
                    return serverError(result.message());
        }
        return result;
    }

    // guest: confirm a booking
    resource function post api/bookings/confirm(@http:Payload ConfirmBookingRequest payload)
                  returns ConfirmBookingResponse|http:InternalServerError {
                ConfirmBookingResponse|grpc:Error result = rentalClient->confirmBooking(payload);
                if result is grpc:Error {
                    return serverError(result.message());
                }
                return result;
    }

    //  register a new host or guest
       resource function post api/users(@http:Payload UserRequest payload)
                    returns UserStreamResponse|http:InternalServerError {
                CreateUsersStreamingClient|grpc:Error sc = rentalClient->createUsers();
                if sc is grpc:Error {
            return serverError(sc.message());
        }
        grpc:Error? sendErr = sc->sendUserRequest(payload);
        if sendErr is grpc:Error {
                    return serverError(sendErr.message());
                }
                grpc:Error? completeErr = sc->complete();
        if completeErr is grpc:Error {
            return serverError(completeErr.message());
        }
                UserStreamResponse?|grpc:Error resp = sc->receiveUserStreamResponse();
                if resp is grpc:Error {
                    return serverError(resp.message());
                }
        if resp is () {
                    return serverError("No response from server.");
                }
                return resp;
    }
}
