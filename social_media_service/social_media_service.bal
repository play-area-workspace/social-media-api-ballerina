import ballerina/http;
import ballerina/lang.regexp;
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

type Post record {|
    int id;
    string description;
    string tags;
    string category;

    @sql:Column {name: "created_date"}
    time:Date createdDate;
|};

type NewPost record {|
    string description;
    string tags;
    string category;

    @sql:Column {name: "created_date"}
    time:Date createdDate;
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

type Meta record {|
    string[] tags;
    string category;
    time:Date created_date;
|};

type PostWithMeta record {|
    int id;
    string description;
    Meta meta;
|};

type PostForbidden record {|
    *http:Forbidden;
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
http:Client sentimentEndPoint = check new ("http://localhost:9099/text-processing");

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

    resource function get users/[int id]/posts() returns PostWithMeta[]|UserNotFound|error? {
        User|sql:Error user = socialMediaDb->queryRow(`SELECT * FROM users WHERE id = ${id}`);
        if user is sql:NoRowsError {
            UserNotFound userNotFound = {
                body: {message: string `id:${id}`, details: string `users/${id}`, timeStamp: time:utcNow()}
            };
            return userNotFound;
        }

        stream<Post, sql:Error?> postStream = socialMediaDb->query(`SELECT id,description,category,created_date,tags FROM posts WHERE user_id = ${id}`);
        Post[]|error posts = from Post post in postStream
            select post;
        return postToPostWithMeta(check posts);
    }

    resource function post users/[int id]/posts(NewPost newPost) returns http:Created|UserNotFound|PostForbidden|error? {
        User user = check socialMediaDb->queryRow(`SELECT FROM users WHERE id = ${id}`);
        if user is sql:NoRowsError {
            ErrorDetails errorDetails = {message: string `id: ${id}`, details: string `users/${id}/posts`, timeStamp: time:utcNow()}
            UserNotFound userNotFound = {
                body: errorDetails
            };
            return userNotFound;
        }

        if user is error {
            return user;
        }

        _ = check socialMediaDb->execute(`
            INSERT INTO posts(description, category, created_date, tags, user_id) 
            VALUES (${newPost.description}, ${newPost.category}, CURDATE(), ${newPost.tags}, ${id});`);

        return http:CREATED;
    }
}

function postToPostWithMeta(Post[] post) returns PostWithMeta[] => from var postItem in post
    select {
        id: postItem.id,
        description: postItem.description,
        meta: {
            tags: regexp:split(re `,`, postItem.tags),
            category: postItem.category,
            created_date: postItem.createdDate
        }
    };

type Probability record {
    decimal neg;
    decimal neutral;
    decimal pos;
};

type Sentiment record {
    Probability probability;
    string label;
};
