import ballerina/http;
import ballerina/time;

type User record {|
    readonly int id;
    string name;
    time:Date birthDate;
    string mobileNumber;
|};

table<User> key(id) users = table [
   	{id: 1, name: "Rocky", birthDate: {year: 2000, month: 4, day: 20}, mobileNumber: "0774563352"},
    {id: 2, name: "Parker", birthDate: {year: 1998, month: 5, day: 13}, mobileNumber: "0713463152"}
];


service /social\-media on new http:Listener(9090) {

    // social-media/user
    resource function get user() returns User[]|error {
        return users.toArray();
    }
}
