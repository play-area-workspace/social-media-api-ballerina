import ballerina/http;
import ballerina/time;

type User record {|
    int id;
    string name;
    time:Date birthDate;
    string mobileNumber;
|};

service /social\-media on new http:Listener(9090) {

    // social-media/users
    resource function get user() returns User[]|error {
        User joe = {id: 1, name: "Joe", birthDate: {year: 2000, month: 4, day: 20}, mobileNumber: "0774563352"};
        User parker = {id: 1, name: "Parker", birthDate: {year: 1998, month: 5, day: 13}, mobileNumber: "0713463152"};
        return [joe, parker];
    }
}
