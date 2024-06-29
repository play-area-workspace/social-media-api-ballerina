import ballerina/http;
import ballerina/test;
import ballerinax/mysql;

@test:Mock {
    functionName: "initSocialMediaDb"
}
function initMockSocialMediaDb() returns mysql:Client|error => test:mock(mysql:Client);

@test:Config {}
function testUsersById() returns error? {
    User userExpected = {id: 6, name: "Kasun", birthDate: {year: 2000, month: 5, day: 20}, mobileNumber: "0714245369"};
    test:prepare(socialMediaDb).when("queryRow").thenReturn(userExpected);

    http:Client socialMediaEndpoint = check new ("http://localhost:9090/social-media");
    User userActual = check socialMediaEndpoint->/users/[userExpected.id.toString()];

    test:assertEquals(userActual, userExpected);
}

