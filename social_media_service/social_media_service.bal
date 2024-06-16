import ballerina/http;
import ballerina/sql;
import ballerinax/mysql;
import ballerinax/mysql.driver as _;
import ballerina/time;

type User record {|
    readonly int id;
    string name;

    @sql:Column {name:"birth_date"}
    time:Date birthDate;

    @sql:Column {name:"mobile_number"}
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

mysql:Client socialMediaDb = check new("localhost","social_media_user","dummypassword","social_media_database",3307);

// jdbc:Client socialMediaDb = new({
//     url: "jdbc:mysql://localhost:3307/social_media_database",
//     username: "social_media_user",
//     password: "dummypassword"
// });


service /social\-media on new http:Listener(9090) {

    // social-media/users
    resource function get users() returns User[]|error {
        stream<User, sql:Error?> userStream = socialMediaDb->query(`SELECT * FROM users`);
        return from var user in userStream select user;
    }

    resource function get users/[int id]() returns User|UserNotFound|error {
        User|sql:Error user = socialMediaDb->queryRow(`SELECT * FROM users WHERE id = ${id}`);
        if user is sql:NoRowsError{
            UserNotFound userNotFound = {
                body:{message: string `id:${id}`, details: string `user/${id}`, timeStamp: time:utcNow()}
            };
            return userNotFound;
        }

        return user;

        // User? user = users[id];
        // if user is(){
        //     UserNotFound userNotFound = {
        //         body: {message: string `id: ${id}`, details: string `users/${id}`, timeStamp: time:utcNow()}
        //     };
        //     return userNotFound;
        // }
        // return user;
    }

    resource function post users(NewUser newUser) returns http:Created|error{
        sql:ExecutionResult|sql:Error result = socialMediaDb->execute(`
        INSERT INTO users(birth_date, name, mobile_number)
        VALUES (${newUser.birthDate}, ${newUser.name}, ${newUser.mobileNumber});
        `);
        
        // users.add({id:users.length()+1,...newUser});
        return http:CREATED;        
    }
}
