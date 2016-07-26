import XCTest
@testable import Quark

class RoutesTests : XCTestCase {
    private func checkSimpleRoute(method: S4.Method, action: (Routes) -> ((String, [Middleware], Respond) -> Void)) throws {
        let routes = Routes(staticFilesPath: "", fileType: File.self)

        let path = "path"
        let middleware: [Middleware] = []
        let resquest = Request(method: method)
        let response = Response(status: .ok)

        action(routes)(path, middleware) { request in
            return response
        }

        if routes.routes.count != 1 {
            XCTFail("Should've created exactly one route.")
        }

        guard let route = routes.routes.first else {
            return XCTFail("Should've created exactly one route.")
        }

        if route.actions.count != 1 {
            XCTFail("Should've created exactly one action.")
        }

        guard let (method, routeResponder) = route.actions.first else {
            return XCTFail("Should've created exactly one action.")
        }

        XCTAssertEqual(route.path, path)
        XCTAssertEqual(method, method)
        let routeResponse = try routeResponder.respond(to: resquest)
        XCTAssertEqual(routeResponse.status, response.status)
    }

    func testSimpleRoutes() throws {
        try checkSimpleRoute(method: .get, action: Routes.get)
        try checkSimpleRoute(method: .head, action: Routes.head)
        try checkSimpleRoute(method: .post, action: Routes.post)
        try checkSimpleRoute(method: .put, action: Routes.put)
        try checkSimpleRoute(method: .patch, action: Routes.patch)
        try checkSimpleRoute(method: .delete, action: Routes.delete)
        try checkSimpleRoute(method: .options, action: Routes.options)
    }

    private func checkRouteWithOnePathParameter<A : PathParameterConvertible>(method: S4.Method, parameter: A, action: (Routes) -> ((String, [Middleware], (Request, A) throws -> Response) -> Void)) throws {
        let routes = Routes(staticFilesPath: "", fileType: File.self)

        let path = "/:a"
        let middleware: [Middleware] = []
        var request = Request(
            method: method,
            uri: URI(path:
                "/" + parameter.pathParameter
            )
        )
        let response = Response(status: .ok)

        // We don't have a RouteMatcher so we have to add the parameter manually
        request.pathParameters = [
            "a": parameter.pathParameter,
        ]

        action(routes)(path, middleware) { request, a in
            XCTAssertEqual(a.pathParameter, parameter.pathParameter)
            return response
        }

        if routes.routes.count != 1 {
            XCTFail("Should've created exactly one route.")
        }

        guard let route = routes.routes.first else {
            return XCTFail("Should've created exactly one route.")
        }

        if route.actions.count != 1 {
            XCTFail("Should've created exactly one action.")
        }

        guard let (method, routeResponder) = route.actions.first else {
            return XCTFail("Should've created exactly one action.")
        }

        XCTAssertEqual(route.path, path)
        XCTAssertEqual(method, method)

        let routeResponse = try routeResponder.respond(to: request)
        XCTAssertEqual(routeResponse.status, response.status)
    }

    func testRoutesWithOnePathParameter() throws {
        try checkRouteWithOnePathParameter(method: .get, parameter: "parameter", action: Routes.get)
        try checkRouteWithOnePathParameter(method: .head, parameter: "parameter", action: Routes.head)
        try checkRouteWithOnePathParameter(method: .post, parameter: "parameter", action: Routes.post)
        try checkRouteWithOnePathParameter(method: .put, parameter: "parameter", action: Routes.put)
        try checkRouteWithOnePathParameter(method: .patch, parameter: "parameter", action: Routes.patch)
        try checkRouteWithOnePathParameter(method: .delete, parameter: "parameter", action: Routes.delete)
        try checkRouteWithOnePathParameter(method: .options, parameter: "parameter", action: Routes.options)
    }

    private func checkRouteWithTwoPathParameters<A : PathParameterConvertible>(method: S4.Method, parameter: A, action: (Routes) -> ((String, [Middleware], (Request, A, A) throws -> Response) -> Void)) throws {
        let routes = Routes(staticFilesPath: "", fileType: File.self)

        let path = "/:a/:b"
        let middleware: [Middleware] = []
        var request = Request(
            method: method,
            uri: URI(path:
                "/" + parameter.pathParameter +
                "/" + parameter.pathParameter
            )
        )
        let response = Response(status: .ok)

        // We don't have a RouteMatcher so we have to add the parameter manually
        request.pathParameters = [
            "a": parameter.pathParameter,
            "b": parameter.pathParameter,
        ]

        action(routes)(path, middleware) { request, a, b in
            XCTAssertEqual(a.pathParameter, parameter.pathParameter)
            XCTAssertEqual(b.pathParameter, parameter.pathParameter)
            return response
        }

        if routes.routes.count != 1 {
            XCTFail("Should've created exactly one route.")
        }

        guard let route = routes.routes.first else {
            return XCTFail("Should've created exactly one route.")
        }

        if route.actions.count != 1 {
            XCTFail("Should've created exactly one action.")
        }

        guard let (method, routeResponder) = route.actions.first else {
            return XCTFail("Should've created exactly one action.")
        }

        XCTAssertEqual(route.path, path)
        XCTAssertEqual(method, method)

        let routeResponse = try routeResponder.respond(to: request)
        XCTAssertEqual(routeResponse.status, response.status)
    }

    func testRoutesWithTwoPathParameters() throws {
        try checkRouteWithTwoPathParameters(method: .get, parameter: "parameter", action: Routes.get)
        try checkRouteWithTwoPathParameters(method: .head, parameter: "parameter", action: Routes.head)
        try checkRouteWithTwoPathParameters(method: .post, parameter: "parameter", action: Routes.post)
        try checkRouteWithTwoPathParameters(method: .put, parameter: "parameter", action: Routes.put)
        try checkRouteWithTwoPathParameters(method: .patch, parameter: "parameter", action: Routes.patch)
        try checkRouteWithTwoPathParameters(method: .delete, parameter: "parameter", action: Routes.delete)
        try checkRouteWithTwoPathParameters(method: .options, parameter: "parameter", action: Routes.options)
    }

    private func checkRoutesWithThreePathParameters<A : PathParameterConvertible>(method: S4.Method, parameter: A, action: (Routes) -> ((String, [Middleware], (Request, A, A, A) throws -> Response) -> Void)) throws {
        let routes = Routes(staticFilesPath: "", fileType: File.self)

        let path = "/:a/:b/:c"
        let middleware: [Middleware] = []
        var request = Request(
            method: method,
            uri: URI(path:
                "/" + parameter.pathParameter +
                "/" + parameter.pathParameter +
                "/" + parameter.pathParameter
            )
        )
        let response = Response(status: .ok)

        // We don't have a RouteMatcher so we have to add the parameter manually
        request.pathParameters = [
            "a": parameter.pathParameter,
            "b": parameter.pathParameter,
            "c": parameter.pathParameter,
        ]

        action(routes)(path, middleware) { request, a, b, c in
            XCTAssertEqual(a.pathParameter, parameter.pathParameter)
            XCTAssertEqual(b.pathParameter, parameter.pathParameter)
            XCTAssertEqual(c.pathParameter, parameter.pathParameter)
            return response
        }

        if routes.routes.count != 1 {
            XCTFail("Should've created exactly one route.")
        }

        guard let route = routes.routes.first else {
            return XCTFail("Should've created exactly one route.")
        }

        if route.actions.count != 1 {
            XCTFail("Should've created exactly one action.")
        }

        guard let (method, routeResponder) = route.actions.first else {
            return XCTFail("Should've created exactly one action.")
        }

        XCTAssertEqual(route.path, path)
        XCTAssertEqual(method, method)

        let routeResponse = try routeResponder.respond(to: request)
        XCTAssertEqual(routeResponse.status, response.status)
    }

    func testRoutesWithThreePathParameters() throws {
        try checkRoutesWithThreePathParameters(method: .get, parameter: "parameter", action: Routes.get)
        try checkRoutesWithThreePathParameters(method: .head, parameter: "parameter", action: Routes.head)
        try checkRoutesWithThreePathParameters(method: .post, parameter: "parameter", action: Routes.post)
        try checkRoutesWithThreePathParameters(method: .put, parameter: "parameter", action: Routes.put)
        try checkRoutesWithThreePathParameters(method: .patch, parameter: "parameter", action: Routes.patch)
        try checkRoutesWithThreePathParameters(method: .delete, parameter: "parameter", action: Routes.delete)
        try checkRoutesWithThreePathParameters(method: .options, parameter: "parameter", action: Routes.options)
    }

    private func checkRoutesWithFourPathParameters<A : PathParameterConvertible>(method: S4.Method, parameter: A, action: (Routes) -> ((String, [Middleware], (Request, A, A, A, A) throws -> Response) -> Void)) throws {
        let routes = Routes(staticFilesPath: "", fileType: File.self)

        let path = "/:a/:b/:c/:d"
        let middleware: [Middleware] = []
        var request = Request(
            method: method,
            uri: URI(path:
                "/" + parameter.pathParameter +
                "/" + parameter.pathParameter +
                "/" + parameter.pathParameter +
                "/" + parameter.pathParameter
            )
        )
        let response = Response(status: .ok)

        // We don't have a RouteMatcher so we have to add the parameter manually
        request.pathParameters = [
            "a": parameter.pathParameter,
            "b": parameter.pathParameter,
            "c": parameter.pathParameter,
            "d": parameter.pathParameter,
        ]

        action(routes)(path, middleware) { request, a, b, c, d in
            XCTAssertEqual(a.pathParameter, parameter.pathParameter)
            XCTAssertEqual(b.pathParameter, parameter.pathParameter)
            XCTAssertEqual(c.pathParameter, parameter.pathParameter)
            XCTAssertEqual(d.pathParameter, parameter.pathParameter)
            return response
        }

        if routes.routes.count != 1 {
            XCTFail("Should've created exactly one route.")
        }

        guard let route = routes.routes.first else {
            return XCTFail("Should've created exactly one route.")
        }

        if route.actions.count != 1 {
            XCTFail("Should've created exactly one action.")
        }

        guard let (method, routeResponder) = route.actions.first else {
            return XCTFail("Should've created exactly one action.")
        }

        XCTAssertEqual(route.path, path)
        XCTAssertEqual(method, method)

        let routeResponse = try routeResponder.respond(to: request)
        XCTAssertEqual(routeResponse.status, response.status)
    }

    func testRoutesWithFourPathParameters() throws {
        try checkRoutesWithFourPathParameters(method: .get, parameter: "parameter", action: Routes.get)
        try checkRoutesWithFourPathParameters(method: .head, parameter: "parameter", action: Routes.head)
        try checkRoutesWithFourPathParameters(method: .post, parameter: "parameter", action: Routes.post)
        try checkRoutesWithFourPathParameters(method: .put, parameter: "parameter", action: Routes.put)
        try checkRoutesWithFourPathParameters(method: .patch, parameter: "parameter", action: Routes.patch)
        try checkRoutesWithFourPathParameters(method: .delete, parameter: "parameter", action: Routes.delete)
        try checkRoutesWithFourPathParameters(method: .options, parameter: "parameter", action: Routes.options)
    }
}

extension RoutesTests {
    static var allTests : [(String, (RoutesTests) -> () throws -> Void)] {
        return [
            ("testSimpleRoutes", testSimpleRoutes),
            ("testRoutesWithOnePathParameter", testRoutesWithOnePathParameter),
            ("testRoutesWithTwoPathParameters", testRoutesWithTwoPathParameters),
            ("testRoutesWithThreePathParameters", testRoutesWithThreePathParameters),
            ("testRoutesWithFourPathParameters", testRoutesWithFourPathParameters),
        ]
    }
}
