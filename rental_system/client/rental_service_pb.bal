import ballerina/grpc;
import ballerina/protobuf;

public const string RENTAL_SERVICE_DESC = "0A1472656E74616C5F736572766963652E70726F746F120672656E74616C22F6010A0850726F7065727479121E0A0A70726F70657274794964180120012809520A70726F7065727479496412160A06686F737449641802200128095206686F7374496412120A046E616D6518032001280952046E616D65121A0A086C6F636174696F6E18042001280952086C6F636174696F6E12220A0C70726F706572747954797065180520012809520C70726F70657274795479706512240A0D70726963655065724E69676874180620012801520D70726963655065724E6967687412160A06737461747573180720012809520673746174757312200A0B6465736372697074696F6E180820012809520B6465736372697074696F6E225C0A045573657212160A06757365724964180120012809520675736572496412120A046E616D6518022001280952046E616D6512140A05656D61696C1803200128095205656D61696C12120A04726F6C651804200128095204726F6C6522DD010A0F50726F70657274795265717565737412160A06686F737449641801200128095206686F7374496412120A046E616D6518022001280952046E616D65121A0A086C6F636174696F6E18032001280952086C6F636174696F6E12220A0C70726F706572747954797065180420012809520C70726F70657274795479706512240A0D70726963655065724E69676874180520012801520D70726963655065724E6967687412160A06737461747573180620012809520673746174757312200A0B6465736372697074696F6E180720012809520B6465736372697074696F6E22740A1050726F7065727479526573706F6E736512180A077375636365737318012001280852077375636365737312180A076D65737361676518022001280952076D657373616765122C0A0870726F706572747918032001280B32102E72656E74616C2E50726F7065727479520870726F7065727479224B0A0B557365725265717565737412120A046E616D6518012001280952046E616D6512140A05656D61696C1802200128095205656D61696C12120A04726F6C651803200128095204726F6C652286010A125573657253747265616D526573706F6E736512180A077375636365737318012001280852077375636365737312220A0C757365727343726561746564180220012805520C75736572734372656174656412180A076D65737361676518032001280952076D65737361676512180A0775736572496473180420032809520775736572496473228D020A1555706461746550726F706572747952657175657374121E0A0A70726F70657274794964180120012809520A70726F7065727479496412160A06686F737449641802200128095206686F7374496412170A046E616D65180320012809480052046E616D6588010112250A0B6465736372697074696F6E1804200128094801520B6465736372697074696F6E88010112290A0D70726963655065724E696768741805200128014802520D70726963655065724E69676874880101121B0A067374617475731806200128094803520673746174757388010142070A055F6E616D65420E0A0C5F6465736372697074696F6E42100A0E5F70726963655065724E6967687442090A075F737461747573224F0A1552656D6F766550726F706572747952657175657374121E0A0A70726F70657274794964180120012809520A70726F7065727479496412160A06686F737449641802200128095206686F7374496422740A0C50726F70657274794C69737412180A077375636365737318012001280852077375636365737312180A076D65737361676518022001280952076D65737361676512300A0A70726F7065727469657318032003280B32102E72656E74616C2E50726F7065727479520A70726F70657274696573226B0A154C69737450726F7065727469657352657175657374121A0A086C6F636174696F6E18012001280952086C6F636174696F6E121A0A086D696E507269636518022001280152086D696E5072696365121A0A086D6178507269636518032001280152086D6178507269636522370A1553656172636850726F706572747952657175657374121E0A0A70726F70657274794964180120012809520A70726F7065727479496422740A1653656172636850726F7065727479526573706F6E736512140A05666F756E641801200128085205666F756E6412160A067374617475731802200128095206737461747573122C0A0870726F706572747918032001280B32102E72656E74616C2E50726F7065727479520870726F70657274792285010A13426F6F6B50726F706572747952657175657374121E0A0A70726F70657274794964180120012809520A70726F7065727479496412180A076775657374496418022001280952076775657374496412180A07636865636B496E1803200128095207636865636B496E121A0A08636865636B4F75741804200128095208636865636B4F757422680A14426F6F6B50726F7065727479526573706F6E736512180A077375636365737318012001280852077375636365737312180A076D65737361676518022001280952076D657373616765121C0A097265717565737449641803200128095209726571756573744964224F0A15436F6E6669726D426F6F6B696E6752657175657374121C0A09726571756573744964180120012809520972657175657374496412180A076775657374496418022001280952076775657374496422A0010A16436F6E6669726D426F6F6B696E67526573706F6E736512180A077375636365737318012001280852077375636365737312180A076D65737361676518022001280952076D657373616765121C0A09626F6F6B696E6749641803200128095209626F6F6B696E67496412160A066E696768747318042001280552066E6967687473121C0A09746F74616C436F73741805200128015209746F74616C436F737432E0040A0D52656E74616C5365727669636512400A0B61646450726F706572747912172E72656E74616C2E50726F7065727479526571756573741A182E72656E74616C2E50726F7065727479526573706F6E736512400A0B637265617465557365727312132E72656E74616C2E55736572526571756573741A1A2E72656E74616C2E5573657253747265616D526573706F6E7365280112490A0E75706461746550726F7065727479121D2E72656E74616C2E55706461746550726F7065727479526571756573741A182E72656E74616C2E50726F7065727479526573706F6E736512450A0E72656D6F766550726F7065727479121D2E72656E74616C2E52656D6F766550726F7065727479526571756573741A142E72656E74616C2E50726F70657274794C697374124C0A176C697374417661696C61626C6550726F70657274696573121D2E72656E74616C2E4C69737450726F70657274696573526571756573741A102E72656E74616C2E50726F70657274793001124F0A0E73656172636850726F7065727479121D2E72656E74616C2E53656172636850726F7065727479526571756573741A1E2E72656E74616C2E53656172636850726F7065727479526573706F6E736512490A0C626F6F6B50726F7065727479121B2E72656E74616C2E426F6F6B50726F7065727479526571756573741A1C2E72656E74616C2E426F6F6B50726F7065727479526573706F6E7365124F0A0E636F6E6669726D426F6F6B696E67121D2E72656E74616C2E436F6E6669726D426F6F6B696E67526571756573741A1E2E72656E74616C2E436F6E6669726D426F6F6B696E67526573706F6E7365620670726F746F33";

public isolated client class RentalServiceClient {
    *grpc:AbstractClientEndpoint;

    private final grpc:Client grpcClient;

    public isolated function init(string url, *grpc:ClientConfiguration config) returns grpc:Error? {
        self.grpcClient = check new (url, config);
        check self.grpcClient.initStub(self, RENTAL_SERVICE_DESC);
    }

    isolated remote function addProperty(PropertyRequest|ContextPropertyRequest req) returns PropertyResponse|grpc:Error {
        map<string|string[]> headers = {};
        PropertyRequest message;
        if req is ContextPropertyRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("rental.RentalService/addProperty", message, headers);
        [anydata, map<string|string[]>] [result, _] = payload;
        return <PropertyResponse>result;
    }

    isolated remote function addPropertyContext(PropertyRequest|ContextPropertyRequest req) returns ContextPropertyResponse|grpc:Error {
        map<string|string[]> headers = {};
        PropertyRequest message;
        if req is ContextPropertyRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("rental.RentalService/addProperty", message, headers);
        [anydata, map<string|string[]>] [result, respHeaders] = payload;
        return {content: <PropertyResponse>result, headers: respHeaders};
    }

    isolated remote function updateProperty(UpdatePropertyRequest|ContextUpdatePropertyRequest req) returns PropertyResponse|grpc:Error {
        map<string|string[]> headers = {};
        UpdatePropertyRequest message;
        if req is ContextUpdatePropertyRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("rental.RentalService/updateProperty", message, headers);
        [anydata, map<string|string[]>] [result, _] = payload;
        return <PropertyResponse>result;
    }

    isolated remote function updatePropertyContext(UpdatePropertyRequest|ContextUpdatePropertyRequest req) returns ContextPropertyResponse|grpc:Error {
        map<string|string[]> headers = {};
        UpdatePropertyRequest message;
        if req is ContextUpdatePropertyRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("rental.RentalService/updateProperty", message, headers);
        [anydata, map<string|string[]>] [result, respHeaders] = payload;
        return {content: <PropertyResponse>result, headers: respHeaders};
    }

    isolated remote function removeProperty(RemovePropertyRequest|ContextRemovePropertyRequest req) returns PropertyList|grpc:Error {
        map<string|string[]> headers = {};
        RemovePropertyRequest message;
        if req is ContextRemovePropertyRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("rental.RentalService/removeProperty", message, headers);
        [anydata, map<string|string[]>] [result, _] = payload;
        return <PropertyList>result;
    }

    isolated remote function removePropertyContext(RemovePropertyRequest|ContextRemovePropertyRequest req) returns ContextPropertyList|grpc:Error {
        map<string|string[]> headers = {};
        RemovePropertyRequest message;
        if req is ContextRemovePropertyRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("rental.RentalService/removeProperty", message, headers);
        [anydata, map<string|string[]>] [result, respHeaders] = payload;
        return {content: <PropertyList>result, headers: respHeaders};
    }

    isolated remote function searchProperty(SearchPropertyRequest|ContextSearchPropertyRequest req) returns SearchPropertyResponse|grpc:Error {
        map<string|string[]> headers = {};
        SearchPropertyRequest message;
        if req is ContextSearchPropertyRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("rental.RentalService/searchProperty", message, headers);
        [anydata, map<string|string[]>] [result, _] = payload;
        return <SearchPropertyResponse>result;
    }

    isolated remote function searchPropertyContext(SearchPropertyRequest|ContextSearchPropertyRequest req) returns ContextSearchPropertyResponse|grpc:Error {
        map<string|string[]> headers = {};
        SearchPropertyRequest message;
        if req is ContextSearchPropertyRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("rental.RentalService/searchProperty", message, headers);
        [anydata, map<string|string[]>] [result, respHeaders] = payload;
        return {content: <SearchPropertyResponse>result, headers: respHeaders};
    }

    isolated remote function bookProperty(BookPropertyRequest|ContextBookPropertyRequest req) returns BookPropertyResponse|grpc:Error {
        map<string|string[]> headers = {};
        BookPropertyRequest message;
        if req is ContextBookPropertyRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("rental.RentalService/bookProperty", message, headers);
        [anydata, map<string|string[]>] [result, _] = payload;
        return <BookPropertyResponse>result;
    }

    isolated remote function bookPropertyContext(BookPropertyRequest|ContextBookPropertyRequest req) returns ContextBookPropertyResponse|grpc:Error {
        map<string|string[]> headers = {};
        BookPropertyRequest message;
        if req is ContextBookPropertyRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("rental.RentalService/bookProperty", message, headers);
        [anydata, map<string|string[]>] [result, respHeaders] = payload;
        return {content: <BookPropertyResponse>result, headers: respHeaders};
    }

    isolated remote function confirmBooking(ConfirmBookingRequest|ContextConfirmBookingRequest req) returns ConfirmBookingResponse|grpc:Error {
        map<string|string[]> headers = {};
        ConfirmBookingRequest message;
        if req is ContextConfirmBookingRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("rental.RentalService/confirmBooking", message, headers);
        [anydata, map<string|string[]>] [result, _] = payload;
        return <ConfirmBookingResponse>result;
    }

    isolated remote function confirmBookingContext(ConfirmBookingRequest|ContextConfirmBookingRequest req) returns ContextConfirmBookingResponse|grpc:Error {
        map<string|string[]> headers = {};
        ConfirmBookingRequest message;
        if req is ContextConfirmBookingRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("rental.RentalService/confirmBooking", message, headers);
        [anydata, map<string|string[]>] [result, respHeaders] = payload;
        return {content: <ConfirmBookingResponse>result, headers: respHeaders};
    }

    isolated remote function createUsers() returns CreateUsersStreamingClient|grpc:Error {
        grpc:StreamingClient sClient = check self.grpcClient->executeClientStreaming("rental.RentalService/createUsers");
        return new CreateUsersStreamingClient(sClient);
    }

    isolated remote function listAvailableProperties(ListPropertiesRequest|ContextListPropertiesRequest req) returns stream<Property, grpc:Error?>|grpc:Error {
        map<string|string[]> headers = {};
        ListPropertiesRequest message;
        if req is ContextListPropertiesRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeServerStreaming("rental.RentalService/listAvailableProperties", message, headers);
        [stream<anydata, grpc:Error?>, map<string|string[]>] [result, _] = payload;
        PropertyStream outputStream = new PropertyStream(result);
        return new stream<Property, grpc:Error?>(outputStream);
    }

    isolated remote function listAvailablePropertiesContext(ListPropertiesRequest|ContextListPropertiesRequest req) returns ContextPropertyStream|grpc:Error {
        map<string|string[]> headers = {};
        ListPropertiesRequest message;
        if req is ContextListPropertiesRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeServerStreaming("rental.RentalService/listAvailableProperties", message, headers);
        [stream<anydata, grpc:Error?>, map<string|string[]>] [result, respHeaders] = payload;
        PropertyStream outputStream = new PropertyStream(result);
        return {content: new stream<Property, grpc:Error?>(outputStream), headers: respHeaders};
    }
}

public isolated client class CreateUsersStreamingClient {
    private final grpc:StreamingClient sClient;

    isolated function init(grpc:StreamingClient sClient) {
        self.sClient = sClient;
    }

    isolated remote function sendUserRequest(UserRequest message) returns grpc:Error? {
        return self.sClient->send(message);
    }

    isolated remote function sendContextUserRequest(ContextUserRequest message) returns grpc:Error? {
        return self.sClient->send(message);
    }

    isolated remote function receiveUserStreamResponse() returns UserStreamResponse|grpc:Error? {
        var response = check self.sClient->receive();
        if response is () {
            return response;
        } else {
            [anydata, map<string|string[]>] [payload, _] = response;
            return <UserStreamResponse>payload;
        }
    }

    isolated remote function receiveContextUserStreamResponse() returns ContextUserStreamResponse|grpc:Error? {
        var response = check self.sClient->receive();
        if response is () {
            return response;
        } else {
            [anydata, map<string|string[]>] [payload, headers] = response;
            return {content: <UserStreamResponse>payload, headers: headers};
        }
    }

    isolated remote function sendError(grpc:Error response) returns grpc:Error? {
        return self.sClient->sendError(response);
    }

    isolated remote function complete() returns grpc:Error? {
        return self.sClient->complete();
    }
}

public class PropertyStream {
    private stream<anydata, grpc:Error?> anydataStream;

    public isolated function init(stream<anydata, grpc:Error?> anydataStream) {
        self.anydataStream = anydataStream;
    }

    public isolated function next() returns record {|Property value;|}|grpc:Error? {
        var streamValue = self.anydataStream.next();
        if streamValue is () {
            return streamValue;
        } else if streamValue is grpc:Error {
            return streamValue;
        } else {
            record {|Property value;|} nextRecord = {value: <Property>streamValue.value};
            return nextRecord;
        }
    }

    public isolated function close() returns grpc:Error? {
        return self.anydataStream.close();
    }
}

public isolated client class RentalServicePropertyListCaller {
    private final grpc:Caller caller;

    public isolated function init(grpc:Caller caller) {
        self.caller = caller;
    }

    public isolated function getId() returns int {
        return self.caller.getId();
    }

    isolated remote function sendPropertyList(PropertyList response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendContextPropertyList(ContextPropertyList response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendError(grpc:Error response) returns grpc:Error? {
        return self.caller->sendError(response);
    }

    isolated remote function complete() returns grpc:Error? {
        return self.caller->complete();
    }

    public isolated function isCancelled() returns boolean {
        return self.caller.isCancelled();
    }
}

public isolated client class RentalServicePropertyResponseCaller {
    private final grpc:Caller caller;

    public isolated function init(grpc:Caller caller) {
        self.caller = caller;
    }

    public isolated function getId() returns int {
        return self.caller.getId();
    }

    isolated remote function sendPropertyResponse(PropertyResponse response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendContextPropertyResponse(ContextPropertyResponse response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendError(grpc:Error response) returns grpc:Error? {
        return self.caller->sendError(response);
    }

    isolated remote function complete() returns grpc:Error? {
        return self.caller->complete();
    }

    public isolated function isCancelled() returns boolean {
        return self.caller.isCancelled();
    }
}

public isolated client class RentalServiceSearchPropertyResponseCaller {
    private final grpc:Caller caller;

    public isolated function init(grpc:Caller caller) {
        self.caller = caller;
    }

    public isolated function getId() returns int {
        return self.caller.getId();
    }

    isolated remote function sendSearchPropertyResponse(SearchPropertyResponse response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendContextSearchPropertyResponse(ContextSearchPropertyResponse response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendError(grpc:Error response) returns grpc:Error? {
        return self.caller->sendError(response);
    }

    isolated remote function complete() returns grpc:Error? {
        return self.caller->complete();
    }

    public isolated function isCancelled() returns boolean {
        return self.caller.isCancelled();
    }
}

public isolated client class RentalServiceUserStreamResponseCaller {
    private final grpc:Caller caller;

    public isolated function init(grpc:Caller caller) {
        self.caller = caller;
    }

    public isolated function getId() returns int {
        return self.caller.getId();
    }

    isolated remote function sendUserStreamResponse(UserStreamResponse response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendContextUserStreamResponse(ContextUserStreamResponse response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendError(grpc:Error response) returns grpc:Error? {
        return self.caller->sendError(response);
    }

    isolated remote function complete() returns grpc:Error? {
        return self.caller->complete();
    }

    public isolated function isCancelled() returns boolean {
        return self.caller.isCancelled();
    }
}

public isolated client class RentalServiceConfirmBookingResponseCaller {
    private final grpc:Caller caller;

    public isolated function init(grpc:Caller caller) {
        self.caller = caller;
    }

    public isolated function getId() returns int {
        return self.caller.getId();
    }

    isolated remote function sendConfirmBookingResponse(ConfirmBookingResponse response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendContextConfirmBookingResponse(ContextConfirmBookingResponse response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendError(grpc:Error response) returns grpc:Error? {
        return self.caller->sendError(response);
    }

    isolated remote function complete() returns grpc:Error? {
        return self.caller->complete();
    }

    public isolated function isCancelled() returns boolean {
        return self.caller.isCancelled();
    }
}

public isolated client class RentalServicePropertyCaller {
    private final grpc:Caller caller;

    public isolated function init(grpc:Caller caller) {
        self.caller = caller;
    }

    public isolated function getId() returns int {
        return self.caller.getId();
    }

    isolated remote function sendProperty(Property response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendContextProperty(ContextProperty response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendError(grpc:Error response) returns grpc:Error? {
        return self.caller->sendError(response);
    }

    isolated remote function complete() returns grpc:Error? {
        return self.caller->complete();
    }

    public isolated function isCancelled() returns boolean {
        return self.caller.isCancelled();
    }
}

public isolated client class RentalServiceBookPropertyResponseCaller {
    private final grpc:Caller caller;

    public isolated function init(grpc:Caller caller) {
        self.caller = caller;
    }

    public isolated function getId() returns int {
        return self.caller.getId();
    }

    isolated remote function sendBookPropertyResponse(BookPropertyResponse response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendContextBookPropertyResponse(ContextBookPropertyResponse response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendError(grpc:Error response) returns grpc:Error? {
        return self.caller->sendError(response);
    }

    isolated remote function complete() returns grpc:Error? {
        return self.caller->complete();
    }

    public isolated function isCancelled() returns boolean {
        return self.caller.isCancelled();
    }
}

public type ContextPropertyStream record {|
    stream<Property, error?> content;
    map<string|string[]> headers;
|};

public type ContextUserRequestStream record {|
    stream<UserRequest, error?> content;
    map<string|string[]> headers;
|};

public type ContextBookPropertyRequest record {|
    BookPropertyRequest content;
    map<string|string[]> headers;
|};

public type ContextListPropertiesRequest record {|
    ListPropertiesRequest content;
    map<string|string[]> headers;
|};

public type ContextUpdatePropertyRequest record {|
    UpdatePropertyRequest content;
    map<string|string[]> headers;
|};

public type ContextSearchPropertyResponse record {|
    SearchPropertyResponse content;
    map<string|string[]> headers;
|};

public type ContextUserStreamResponse record {|
    UserStreamResponse content;
    map<string|string[]> headers;
|};

public type ContextConfirmBookingRequest record {|
    ConfirmBookingRequest content;
    map<string|string[]> headers;
|};

public type ContextConfirmBookingResponse record {|
    ConfirmBookingResponse content;
    map<string|string[]> headers;
|};

public type ContextPropertyResponse record {|
    PropertyResponse content;
    map<string|string[]> headers;
|};

public type ContextPropertyList record {|
    PropertyList content;
    map<string|string[]> headers;
|};

public type ContextRemovePropertyRequest record {|
    RemovePropertyRequest content;
    map<string|string[]> headers;
|};

public type ContextSearchPropertyRequest record {|
    SearchPropertyRequest content;
    map<string|string[]> headers;
|};

public type ContextProperty record {|
    Property content;
    map<string|string[]> headers;
|};

public type ContextPropertyRequest record {|
    PropertyRequest content;
    map<string|string[]> headers;
|};

public type ContextUserRequest record {|
    UserRequest content;
    map<string|string[]> headers;
|};

public type ContextBookPropertyResponse record {|
    BookPropertyResponse content;
    map<string|string[]> headers;
|};

@protobuf:Descriptor {value: RENTAL_SERVICE_DESC}
public type BookPropertyRequest record {|
    string propertyId = "";
    string guestId = "";
    string checkIn = "";
    string checkOut = "";
|};

@protobuf:Descriptor {value: RENTAL_SERVICE_DESC}
public type ListPropertiesRequest record {|
    string location = "";
    float minPrice = 0.0;
    float maxPrice = 0.0;
|};

@protobuf:Descriptor {value: RENTAL_SERVICE_DESC}
public type User record {|
    string userId = "";
    string name = "";
    string email = "";
    string role = "";
|};

@protobuf:Descriptor {value: RENTAL_SERVICE_DESC}
public type UpdatePropertyRequest record {|
    string propertyId = "";
    string hostId = "";
    string name?;
    string status?;
    string description?;
    float pricePerNight?;
|};

isolated function isValidUpdatepropertyrequest(UpdatePropertyRequest r) returns boolean {
    int _nameCount = 0;
    if r?.name !is () {
        _nameCount += 1;
    }
    int _statusCount = 0;
    if r?.status !is () {
        _statusCount += 1;
    }
    int _descriptionCount = 0;
    if r?.description !is () {
        _descriptionCount += 1;
    }
    int _pricePerNightCount = 0;
    if r?.pricePerNight !is () {
        _pricePerNightCount += 1;
    }
    if _nameCount > 1 || _statusCount > 1 || _descriptionCount > 1 || _pricePerNightCount > 1 {
        return false;
    }
    return true;
}

isolated function setUpdatePropertyRequest_Name(UpdatePropertyRequest r, string name) {
    r.name = name;
}

isolated function setUpdatePropertyRequest_Status(UpdatePropertyRequest r, string status) {
    r.status = status;
}

isolated function setUpdatePropertyRequest_Description(UpdatePropertyRequest r, string description) {
    r.description = description;
}

isolated function setUpdatePropertyRequest_PricePerNight(UpdatePropertyRequest r, float pricePerNight) {
    r.pricePerNight = pricePerNight;
}

@protobuf:Descriptor {value: RENTAL_SERVICE_DESC}
public type SearchPropertyResponse record {|
    boolean found = false;
    string status = "";
    Property property = {};
|};

@protobuf:Descriptor {value: RENTAL_SERVICE_DESC}
public type UserStreamResponse record {|
    boolean success = false;
    int usersCreated = 0;
    string message = "";
    string[] userIds = [];
|};

@protobuf:Descriptor {value: RENTAL_SERVICE_DESC}
public type ConfirmBookingRequest record {|
    string requestId = "";
    string guestId = "";
|};

@protobuf:Descriptor {value: RENTAL_SERVICE_DESC}
public type ConfirmBookingResponse record {|
    boolean success = false;
    string message = "";
    string bookingId = "";
    int nights = 0;
    float totalCost = 0.0;
|};

@protobuf:Descriptor {value: RENTAL_SERVICE_DESC}
public type PropertyResponse record {|
    boolean success = false;
    string message = "";
    Property property = {};
|};

@protobuf:Descriptor {value: RENTAL_SERVICE_DESC}
public type PropertyList record {|
    boolean success = false;
    string message = "";
    Property[] properties = [];
|};

@protobuf:Descriptor {value: RENTAL_SERVICE_DESC}
public type RemovePropertyRequest record {|
    string propertyId = "";
    string hostId = "";
|};

@protobuf:Descriptor {value: RENTAL_SERVICE_DESC}
public type SearchPropertyRequest record {|
    string propertyId = "";
|};

@protobuf:Descriptor {value: RENTAL_SERVICE_DESC}
public type Property record {|
    string propertyId = "";
    string hostId = "";
    string name = "";
    string location = "";
    string propertyType = "";
    float pricePerNight = 0.0;
    string status = "";
    string description = "";
|};

@protobuf:Descriptor {value: RENTAL_SERVICE_DESC}
public type PropertyRequest record {|
    string hostId = "";
    string name = "";
    string location = "";
    string propertyType = "";
    float pricePerNight = 0.0;
    string status = "";
    string description = "";
|};

@protobuf:Descriptor {value: RENTAL_SERVICE_DESC}
public type UserRequest record {|
    string name = "";
    string email = "";
    string role = "";
|};

@protobuf:Descriptor {value: RENTAL_SERVICE_DESC}
public type BookPropertyResponse record {|
    boolean success = false;
    string message = "";
    string requestId = "";
|};
