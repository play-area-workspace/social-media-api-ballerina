import ballerina/http;
import ballerina/sql;
import ballerina/time;
import ballerinax/mysql;
import ballerinax/mysql.driver as _;

type User record {|
    readonly int id;
    string name;

    @sql:Column {name: "birth_date"}
    time:Date birthDate;

    @sql:Column {name: "mobile_number"}
    string mobileNumber;
|};

type NewUser record {|
    string name;
    time:Date birthDate;
    string mobileNumber;
|};

type ErrorDetails record {
    string message;
    string details;
    time:Utc timeStamp;
};

type UserNotFound record {|
    *http:NotFound;
    ErrorDetails body;
|};

type DatabaseConfig record {|
    string host;
    string user;
    string password;
    string database;
    int port;
|};

configurable DatabaseConfig databaseConfig = ?;

mysql:Client socialMediaDb = check new (...databaseConfig);

service /social\-media on new http:Listener(9090) {

    // social-media/users
    resource function get users() returns User[]|error {
        stream<User, sql:Error?> userStream = socialMediaDb->query(`SELECT * FROM users`);
        return from var user in userStream
            select user;
    }

    resource function get users/[int id]() returns User|UserNotFound|error {
        User|sql:Error user = socialMediaDb->queryRow(`SELECT * FROM users WHERE id = ${id}`);
        if user is sql:NoRowsError {
            UserNotFound userNotFound = {
                body: {message: string `id:${id}`, details: string `user/${id}`, timeStamp: time:utcNow()}
            };
            return userNotFound;
        }

        return user;
    }

    resource function post users(NewUser newUser) returns http:Created|error {
        sql:ExecutionResult|sql:Error result = socialMediaDb->execute(`
        INSERT INTO users(birth_date, name, mobile_number)
        VALUES (${newUser.birthDate}, ${newUser.name}, ${newUser.mobileNumber});
        `);

        return http:CREATED;
    }
}
