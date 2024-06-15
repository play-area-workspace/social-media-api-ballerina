import ballerina/http;
import ballerina/time;
import ballerina/sql;
import ballerinax/mysql;

type User record {|
    readonly int id;
    string name;
    time:Date birthDate;
    string mobileNumber;
|};

type NewUser record{|
    string name;
    time:Date birthDate;
    string mobileNumber;
|};

table<User> key(id) users = table [
   	{id: 1, name: "Rocky", birthDate: {year: 2000, month: 4, day: 20}, mobileNumber: "0774563352"},
    {id: 2, name: "Parker", birthDate: {year: 1998, month: 5, day: 13}, mobileNumber: "0713463152"}
];

type ErrorDetails record {
    string message;
    string details;
    time:Utc timeStamp;
};

type UserNotFound record {|
    *http:NotFound;
    ErrorDetails body;
|};

mysql:Client socialMediaDb = check new("localhost","social_media_user","dummypassword","social_media_database",3306);


service /social\-media on new http:Listener(9090) {

    // social-media/users
    resource function get users() returns User[]|error {
        return users.toArray();
    }

    resource function get users/[int id]() returns User|UserNotFound|error {
        User? user = users[id];
        if user is(){
            UserNotFound userNotFound = {
                body: {message: string `id: ${id}`, details: string `users/${id}`, timeStamp: time:utcNow()}
            };
            return userNotFound;
        }
        return user;
    }

    resource function post users(NewUser newUser) returns http:Created|error{
        users.add({id:users.length()+1,...newUser});
        return http:CREATED;        
    }
}
