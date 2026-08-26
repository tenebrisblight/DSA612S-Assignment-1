import ballerina/http; // make sure to type '/https' not '/io' or else there will be issues with dependencies being undefined.

// Define a record for the modelling
type Book record{|
readonly string id; // read only means the data structure is immutable
string title;
string author;
|};

// In-memory data store using a map
table<Book> key(id) bookTable = table [
    {id: "1", title: "Data Structures and Analytics", author: "Mr HK"},
    {id: "2", title: "Data Analytics", author: "Mr KC"}
];

//attach an HTTP service listener to port 8080
service /api on new http:Listener(8080)  {

    //GET /api/books - Retrieve all books
    resource function get books() returns Book[] {
        return bookTable.toArray();
    }

    //GET /api/books/[id] - retrive a specific book by path parameter
    resource function get books/[string id]() returns Book|http:NotFound {
        Book? book = bookTable[id];
        if book is () {
            return http:NOT_FOUND;
        }
        return book;
    }

    //POST /api/books - Create a new book entry from JSON payload
    resource function post books(@http:Payload Book newBook) returns http:Created|http:Conflict{
        if bookTable.hasKey(newBook.id){
            return http:CONFLICT;
        }
        bookTable.add(newBook);
        return http:CREATED;
    }
}
