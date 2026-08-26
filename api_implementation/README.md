// when running the API with 'bal run' if a error occurs with the HTTP instance of ballrierina
//run command 'bal clean', then 'bal run' afterwards.
// note when the http service is running, you should send http requests with another terminal without closing the current terminal

//to get books in terminal
curl http://localhost:8080/api/books

// to get a specific book in terminal
curl http://localhost:8080/api/books/1

// to add a new book NB: in powershell curl is an alias for Invoke-RestMethod- i used it here because using curl kept producing errors
Invoke-RestMethod -Uri "http://localhost:8080/api/books" -Method Post -ContentType "application/json" -Body '{"id": "3", "title": "Ballerina in Action", "author": "WSO2"}'

//yet to implement/translate this into a sql server