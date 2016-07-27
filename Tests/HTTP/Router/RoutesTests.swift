import XCTest
@testable import Quark

class RoutesTests : XCTestCase {
    private func checkRoute(routes: Routes, method: S4.Method, path: String, request: Request, response: Response) throws {
        if routes.routes.count != 1 {
            XCTFail("Should've created exactly one route.")
        }

        guard let route = routes.routes.first else {
            return XCTFail("Should've created exactly one route.")
        }

        if route.actions.count != 1 {
            XCTFail("Should've created exactly one function.")
        }

        guard let (routeMethod, routeResponder) = route.actions.first else {
            return XCTFail("Should've created exactly one function.")
        }

        XCTAssertEqual(route.path, path)
        XCTAssertEqual(routeMethod, method)
        let routeResponse = try routeResponder.respond(to: request)
        XCTAssertEqual(routeResponse.status, response.status)
    }

    private func checkSimpleRoute(method: S4.Method, function: (Routes) -> ((String, [Middleware], Respond) -> Void), check: (Request) -> Void) throws {
        let routes = Routes(staticFilesPath: "", fileType: File.self)

        let path = "/path"
        let request = Request(method: method)
        let response = Response(status: .ok)

        function(routes)(path, []) { request in
            check(request)
            return response
        }

        try checkRoute(
            routes: routes,
            method: method,
            path: path,
            request: request,
            response: response
        )
    }

    func testSimpleRoutes() throws {
        func check(method: S4.Method) -> (Request) -> Void {
            return { request in
                XCTAssertEqual(request.method, method)
            }
        }

        try checkSimpleRoute(
            method: .get,
            function: Routes.get,
            check: check(method: .get)
        )

        try checkSimpleRoute(
            method: .head,
            function: Routes.head,
            check: check(method: .head)
        )

        try checkSimpleRoute(
            method: .post,
            function: Routes.post,
            check: check(method: .post)
        )

        try checkSimpleRoute(
            method: .put,
            function: Routes.put,
            check: check(method: .put)
        )

        try checkSimpleRoute(
            method: .patch,
            function: Routes.patch,
            check: check(method: .patch)
        )

        try checkSimpleRoute(
            method: .delete,
            function: Routes.delete,
            check: check(method: .delete)
        )

        try checkSimpleRoute(
            method: .options,
            function: Routes.options,
            check: check(method: .options)
        )
    }

    private func checkRouteWithOnePathParameter<A : PathParameterConvertible>(method: S4.Method, parameter: A, function: (Routes) -> ((String, [Middleware], (Request, A) throws -> Response) -> Void), check: (Request, A) -> Void) throws {
        let routes = Routes(staticFilesPath: "", fileType: File.self)

        let path = "/:a"
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

        function(routes)(path, []) { request, a in
            check(request, a)
            return response
        }

        try checkRoute(
            routes: routes,
            method: method,
            path: path,
            request: request,
            response: response
        )
    }

    func testRoutesWithOnePathParameter() throws {
        let parameter = "yo"

        func check(method: S4.Method) -> (Request, String) -> Void {
            return { request, a in
                XCTAssertEqual(request.method, method)
                XCTAssertEqual(a, parameter)
            }
        }

        try checkRouteWithOnePathParameter(
            method: .get,
            parameter: parameter,
            function: Routes.get,
            check: check(method: .get)
        )

        try checkRouteWithOnePathParameter(
            method: .head,
            parameter: parameter,
            function: Routes.head,
            check: check(method: .head)
        )

        try checkRouteWithOnePathParameter(
            method: .post,
            parameter: parameter,
            function: Routes.post,
            check: check(method: .post)
        )

        try checkRouteWithOnePathParameter(
            method: .put,
            parameter: parameter,
            function: Routes.put,
            check: check(method: .put)
        )

        try checkRouteWithOnePathParameter(
            method: .patch,
            parameter: parameter,
            function: Routes.patch,
            check: check(method: .patch)
        )

        try checkRouteWithOnePathParameter(
            method: .delete,
            parameter: parameter,
            function: Routes.delete,
            check: check(method: .delete)
        )

        try checkRouteWithOnePathParameter(
            method: .options,
            parameter: parameter,
            function: Routes.options,
            check: check(method: .options)
        )
    }

    private func checkRouteWithTwoPathParameters<A : PathParameterConvertible>(method: S4.Method, parameter: A, function: (Routes) -> ((String, [Middleware], (Request, A, A) throws -> Response) -> Void), check: (Request, A, A) -> Void) throws {
        let routes = Routes(staticFilesPath: "", fileType: File.self)

        let path = "/:a/:b"
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

        function(routes)(path, []) { request, a, b in
            check(request, a, b)
            return response
        }

        try checkRoute(
            routes: routes,
            method: method,
            path: path,
            request: request,
            response: response
        )
    }

    func testRoutesWithTwoPathParameters() throws {
        let parameter = "yo"

        func check(method: S4.Method) -> (Request, String, String) -> Void {
            return { request, a, b in
                XCTAssertEqual(request.method, method)
                XCTAssertEqual(a, parameter)
                XCTAssertEqual(b, parameter)
            }
        }

        try checkRouteWithTwoPathParameters(
            method: .get,
            parameter: parameter,
            function: Routes.get,
            check: check(method: .get)
        )

        try checkRouteWithTwoPathParameters(
            method: .head,
            parameter: parameter,
            function: Routes.head,
            check: check(method: .head)
        )

        try checkRouteWithTwoPathParameters(
            method: .post,
            parameter: parameter,
            function: Routes.post,
            check: check(method: .post)
        )

        try checkRouteWithTwoPathParameters(
            method: .put,
            parameter: parameter,
            function: Routes.put,
            check: check(method: .put)
        )

        try checkRouteWithTwoPathParameters(
            method: .patch,
            parameter: parameter,
            function: Routes.patch,
            check: check(method: .patch)
        )

        try checkRouteWithTwoPathParameters(
            method: .delete,
            parameter: parameter,
            function: Routes.delete,
            check: check(method: .delete)
        )

        try checkRouteWithTwoPathParameters(
            method: .options,
            parameter: parameter,
            function: Routes.options,
            check: check(method: .options)
        )
    }

    private func checkRoutesWithThreePathParameters<A : PathParameterConvertible>(method: S4.Method, parameter: A, function: (Routes) -> ((String, [Middleware], (Request, A, A, A) throws -> Response) -> Void), check: (Request, A, A, A) -> Void) throws {
        let routes = Routes(staticFilesPath: "", fileType: File.self)

        let path = "/:a/:b/:c"
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

        function(routes)(path, []) { request, a, b, c in
            check(request, a, b, c)
            return response
        }

        try checkRoute(
            routes: routes,
            method: method,
            path: path,
            request: request,
            response: response
        )
    }

    func testRoutesWithThreePathParameters() throws {
        let parameter = "yo"

        func check(method: S4.Method) -> (Request, String, String, String) -> Void {
            return { request, a, b, c in
                XCTAssertEqual(request.method, method)
                XCTAssertEqual(a, parameter)
                XCTAssertEqual(b, parameter)
                XCTAssertEqual(c, parameter)
            }
        }

        try checkRoutesWithThreePathParameters(
            method: .get,
            parameter: parameter,
            function: Routes.get,
            check: check(method: .get)
        )

        try checkRoutesWithThreePathParameters(
            method: .head,
            parameter: parameter,
            function: Routes.head,
            check: check(method: .head)
        )

        try checkRoutesWithThreePathParameters(
            method: .post,
            parameter: parameter,
            function: Routes.post,
            check: check(method: .post)
        )

        try checkRoutesWithThreePathParameters(
            method: .put,
            parameter: parameter,
            function: Routes.put,
            check: check(method: .put)
        )

        try checkRoutesWithThreePathParameters(
            method: .patch,
            parameter: parameter,
            function: Routes.patch,
            check: check(method: .patch)
        )

        try checkRoutesWithThreePathParameters(
            method: .delete,
            parameter: parameter,
            function: Routes.delete,
            check: check(method: .delete)
        )

        try checkRoutesWithThreePathParameters(
            method: .options,
            parameter: parameter,
            function: Routes.options,
            check: check(method: .options)
        )
    }

    private func checkRoutesWithFourPathParameters<A : PathParameterConvertible>(method: S4.Method, parameter: A, function: (Routes) -> ((String, [Middleware], (Request, A, A, A, A) throws -> Response) -> Void), check: (Request, A, A, A, A) -> Void) throws {
        let routes = Routes(staticFilesPath: "", fileType: File.self)

        let path = "/:a/:b/:c/:d"
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

        function(routes)(path, []) { request, a, b, c, d in
            check(request, a, b, c, d)
            return response
        }

        try checkRoute(
            routes: routes,
            method: method,
            path: path,
            request: request,
            response: response
        )
    }

    func testRoutesWithFourPathParameters() throws {
        let parameter = "yo"

        func check(method: S4.Method) -> (Request, String, String, String, String) -> Void {
            return { request, a, b, c, d in
                XCTAssertEqual(request.method, method)
                XCTAssertEqual(a.pathParameter, parameter)
                XCTAssertEqual(b.pathParameter, parameter)
                XCTAssertEqual(c.pathParameter, parameter)
                XCTAssertEqual(d.pathParameter, parameter)
            }
        }

        try checkRoutesWithFourPathParameters(
            method: .get,
            parameter: parameter,
            function: Routes.get,
            check: check(method: .get)
        )

        try checkRoutesWithFourPathParameters(
            method: .head,
            parameter: parameter,
            function: Routes.head,
            check: check(method: .head)
        )

        try checkRoutesWithFourPathParameters(
            method: .post,
            parameter: parameter,
            function: Routes.post,
            check: check(method: .post)
        )

        try checkRoutesWithFourPathParameters(
            method: .put,
            parameter: parameter,
            function: Routes.put,
            check: check(method: .put)
        )

        try checkRoutesWithFourPathParameters(
            method: .patch,
            parameter: parameter,
            function: Routes.patch,
            check: check(method: .patch)
        )

        try checkRoutesWithFourPathParameters(
            method: .delete,
            parameter: parameter,
            function: Routes.delete,
            check: check(method: .delete)
        )

        try checkRoutesWithFourPathParameters(
            method: .options,
            parameter: parameter,
            function: Routes.options,
            check: check(method: .options)
        )
    }

    private func checkRoutesWithContent<T : protocol<StructuredDataInitializable, StructuredDataRepresentable>>(method: S4.Method, content: T, function: (Routes) -> ((String, [Middleware], T.Type, (Request, T) throws -> Response) -> Void), check: (Request, T) -> Void) throws {
        let routes = Routes(staticFilesPath: "", fileType: File.self)

        let path = "/path"
        var request = Request(method: method)
        let response = Response(status: .ok)

        request.content = content.structuredData

        function(routes)(path, [], T.self) { request, t in
            check(request, t)
            return response
        }

        try checkRoute(
            routes: routes,
            method: method,
            path: path,
            request: request,
            response: response
        )
    }

    func testRoutesWithContent() throws {
        let content = 42

        func check(method: S4.Method) -> (Request, Int) -> Void {
            return { request, t in
                XCTAssertEqual(request.method, method)
                XCTAssertEqual(t, content)
            }
        }

        try checkRoutesWithContent(
            method: .get,
            content: content,
            function: Routes.get,
            check: check(method: .get)
        )

        try checkRoutesWithContent(
            method: .head,
            content: content,
            function: Routes.head,
            check: check(method: .head)
        )

        try checkRoutesWithContent(
            method: .post,
            content: content,
            function: Routes.post,
            check: check(method: .post)
        )

        try checkRoutesWithContent(
            method: .put,
            content: content,
            function: Routes.put,
            check: check(method: .put)
        )

        try checkRoutesWithContent(
            method: .patch,
            content: content,
            function: Routes.patch,
            check: check(method: .patch)
        )

        try checkRoutesWithContent(
            method: .delete,
            content: content,
            function: Routes.delete,
            check: check(method: .delete)
        )

        try checkRoutesWithContent(
            method: .options,
            content: content,
            function: Routes.options,
            check: check(method: .options)
        )
    }

    private func checkRoutesWithOnePathParameterAndContent<A : PathParameterConvertible, T : protocol<StructuredDataInitializable, StructuredDataRepresentable>>(method: S4.Method, parameter: A, content: T, function: (Routes) -> ((String, [Middleware], T.Type, (Request, A, T) throws -> Response) -> Void), check: (Request, A, T) -> Void) throws {
        let routes = Routes(staticFilesPath: "", fileType: File.self)

        let path = "/:a"
        var request = Request(
            method: method,
            uri: URI(path:
                "/" + parameter.pathParameter
            )
        )
        let response = Response(status: .ok)

        // We don't have a RouteMatcher so we have to set pathParameters manually
        request.pathParameters = [
            "a": parameter.pathParameter,
        ]

        // We don't have content negotiation middleware we have to set content manually
        request.content = content.structuredData

        function(routes)(path, [], T.self) { request, a, t in
            check(request, a, t)
            return response
        }

        try checkRoute(
            routes: routes,
            method: method,
            path: path,
            request: request,
            response: response
        )
    }

    func testRoutesWithOnePathParameterAndContent() throws {
        let parameter = "yo"
        let content = 42

        func check(method: S4.Method) -> (Request, String, Int) -> Void {
            return { request, a, t in
                XCTAssertEqual(request.method, method)
                XCTAssertEqual(a, parameter)
                XCTAssertEqual(t, content)
            }
        }

        try checkRoutesWithOnePathParameterAndContent(
            method: .get,
            parameter: parameter,
            content: content,
            function: Routes.get,
            check: check(method: .get)
        )

        try checkRoutesWithOnePathParameterAndContent(
            method: .head,
            parameter: parameter,
            content: content,
            function: Routes.head,
            check: check(method: .head)
        )

        try checkRoutesWithOnePathParameterAndContent(
            method: .post,
            parameter: parameter,
            content: content,
            function: Routes.post,
            check: check(method: .post)
        )

        try checkRoutesWithOnePathParameterAndContent(
            method: .put,
            parameter: parameter,
            content: content,
            function: Routes.put,
            check: check(method: .put)
        )

        try checkRoutesWithOnePathParameterAndContent(
            method: .patch,
            parameter: parameter,
            content: content,
            function: Routes.patch,
            check: check(method: .patch)
        )

        try checkRoutesWithOnePathParameterAndContent(
            method: .delete,
            parameter: parameter,
            content: content,
            function: Routes.delete,
            check: check(method: .delete)
        )

        try checkRoutesWithOnePathParameterAndContent(
            method: .options,
            parameter: parameter,
            content: content,
            function: Routes.options,
            check: check(method: .options)
        )
    }

    private func checkRoutesWithTwoPathParametersAndContent<A : PathParameterConvertible, T : protocol<StructuredDataInitializable, StructuredDataRepresentable>>(method: S4.Method, parameter: A, content: T, function: (Routes) -> ((String, [Middleware], T.Type, (Request, A, A, T) throws -> Response) -> Void), check: (Request, A, A, T) -> Void) throws {
        let routes = Routes(staticFilesPath: "", fileType: File.self)

        let path = "/:a/:b"
        var request = Request(
            method: method,
            uri: URI(path:
                "/" + parameter.pathParameter +
                "/" + parameter.pathParameter
            )
        )
        let response = Response(status: .ok)

        // We don't have a RouteMatcher so we have to set pathParameters manually
        request.pathParameters = [
            "a": parameter.pathParameter,
            "b": parameter.pathParameter,
        ]

        // We don't have content negotiation middleware we have to set content manually
        request.content = content.structuredData

        function(routes)(path, [], T.self) { request, a, b, t in
            check(request, a, b, t)
            return response
        }

        try checkRoute(
            routes: routes,
            method: method,
            path: path,
            request: request,
            response: response
        )
    }

    func testRoutesWithTwoPathParametersAndContent() throws {
        let parameter = "yo"
        let content = 42

        func check(method: S4.Method) -> (Request, String, String, Int) -> Void {
            return { request, a, b, t in
                XCTAssertEqual(request.method, method)
                XCTAssertEqual(a, parameter)
                XCTAssertEqual(b, parameter)
                XCTAssertEqual(t, content)
            }
        }

        try checkRoutesWithTwoPathParametersAndContent(
            method: .get,
            parameter: parameter,
            content: content,
            function: Routes.get,
            check: check(method: .get)
        )

        try checkRoutesWithTwoPathParametersAndContent(
            method: .head,
            parameter: parameter,
            content: content,
            function: Routes.head,
            check: check(method: .head)
        )

        try checkRoutesWithTwoPathParametersAndContent(
            method: .post,
            parameter: parameter,
            content: content,
            function: Routes.post,
            check: check(method: .post)
        )

        try checkRoutesWithTwoPathParametersAndContent(
            method: .put,
            parameter: parameter,
            content: content,
            function: Routes.put,
            check: check(method: .put)
        )

        try checkRoutesWithTwoPathParametersAndContent(
            method: .patch,
            parameter: parameter,
            content: content,
            function: Routes.patch,
            check: check(method: .patch)
        )

        try checkRoutesWithTwoPathParametersAndContent(
            method: .delete,
            parameter: parameter,
            content: content,
            function: Routes.delete,
            check: check(method: .delete)
        )

        try checkRoutesWithTwoPathParametersAndContent(
            method: .options,
            parameter: parameter,
            content: content,
            function: Routes.options,
            check: check(method: .options)
        )
    }

    private func checkRoutesWithThreePathParametersAndContent<A : PathParameterConvertible, T : protocol<StructuredDataInitializable, StructuredDataRepresentable>>(method: S4.Method, parameter: A, content: T, function: (Routes) -> ((String, [Middleware], T.Type, (Request, A, A, A, T) throws -> Response) -> Void), check: (Request, A, A, A, T) -> Void) throws {
        let routes = Routes(staticFilesPath: "", fileType: File.self)

        let path = "/:a/:b/:c"
        var request = Request(
            method: method,
            uri: URI(path:
                "/" + parameter.pathParameter +
                "/" + parameter.pathParameter +
                "/" + parameter.pathParameter
            )
        )
        let response = Response(status: .ok)

        // We don't have a RouteMatcher so we have to set pathParameters manually
        request.pathParameters = [
            "a": parameter.pathParameter,
            "b": parameter.pathParameter,
            "c": parameter.pathParameter,
        ]

        // We don't have content negotiation middleware we have to set content manually
        request.content = content.structuredData

        function(routes)(path, [], T.self) { request, a, b, c, t in
            check(request, a, b, c, t)
            return response
        }

        try checkRoute(
            routes: routes,
            method: method,
            path: path,
            request: request,
            response: response
        )
    }

    func testRoutesWithThreePathParametersAndContent() throws {
        let parameter = "yo"
        let content = 42

        func check(method: S4.Method) -> (Request, String, String, String, Int) -> Void {
            return { request, a, b, c, t in
                XCTAssertEqual(request.method, method)
                XCTAssertEqual(a, parameter)
                XCTAssertEqual(b, parameter)
                XCTAssertEqual(c, parameter)
                XCTAssertEqual(t, content)
            }
        }

        try checkRoutesWithThreePathParametersAndContent(
            method: .get,
            parameter: parameter,
            content: content,
            function: Routes.get,
            check: check(method: .get)
        )

        try checkRoutesWithThreePathParametersAndContent(
            method: .head,
            parameter: parameter,
            content: content,
            function: Routes.head,
            check: check(method: .head)
        )

        try checkRoutesWithThreePathParametersAndContent(
            method: .post,
            parameter: parameter,
            content: content,
            function: Routes.post,
            check: check(method: .post)
        )

        try checkRoutesWithThreePathParametersAndContent(
            method: .put,
            parameter: parameter,
            content: content,
            function: Routes.put,
            check: check(method: .put)
        )

        try checkRoutesWithThreePathParametersAndContent(
            method: .patch,
            parameter: parameter,
            content: content,
            function: Routes.patch,
            check: check(method: .patch)
        )

        try checkRoutesWithThreePathParametersAndContent(
            method: .delete,
            parameter: parameter,
            content: content,
            function: Routes.delete,
            check: check(method: .delete)
        )

        try checkRoutesWithThreePathParametersAndContent(
            method: .options,
            parameter: parameter,
            content: content,
            function: Routes.options,
            check: check(method: .options)
        )
    }

    private func checkRoutesWithFourPathParametersAndContent<A : PathParameterConvertible, T : protocol<StructuredDataInitializable, StructuredDataRepresentable>>(method: S4.Method, parameter: A, content: T, function: (Routes) -> ((String, [Middleware], T.Type, (Request, A, A, A, A, T) throws -> Response) -> Void), check: (Request, A, A, A, A, T) -> Void) throws {
        let routes = Routes(staticFilesPath: "", fileType: File.self)

        let path = "/:a/:b/:c/:d"
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

        // We don't have a RouteMatcher so we have to set pathParameters manually
        request.pathParameters = [
            "a": parameter.pathParameter,
            "b": parameter.pathParameter,
            "c": parameter.pathParameter,
            "d": parameter.pathParameter,
        ]

        // We don't have content negotiation middleware we have to set content manually
        request.content = content.structuredData

        function(routes)(path, [], T.self) { request, a, b, c, d, t in
            check(request, a, b, c, d, t)
            return response
        }

        try checkRoute(
            routes: routes,
            method: method,
            path: path,
            request: request,
            response: response
        )
    }

    func testRoutesWithFourPathParametersAndContent() throws {
        let parameter = "yo"
        let content = 42

        func check(method: S4.Method) -> (Request, String, String, String, String, Int) -> Void {
            return { request, a, b, c, d, t in
                XCTAssertEqual(request.method, method)
                XCTAssertEqual(a, parameter)
                XCTAssertEqual(b, parameter)
                XCTAssertEqual(c, parameter)
                XCTAssertEqual(d, parameter)
                XCTAssertEqual(t, content)
            }
        }

        try checkRoutesWithFourPathParametersAndContent(
            method: .get,
            parameter: parameter,
            content: content,
            function: Routes.get,
            check: check(method: .get)
        )

        try checkRoutesWithFourPathParametersAndContent(
            method: .head,
            parameter: parameter,
            content: content,
            function: Routes.head,
            check: check(method: .head)
        )

        try checkRoutesWithFourPathParametersAndContent(
            method: .post,
            parameter: parameter,
            content: content,
            function: Routes.post,
            check: check(method: .post)
        )

        try checkRoutesWithFourPathParametersAndContent(
            method: .put,
            parameter: parameter,
            content: content,
            function: Routes.put,
            check: check(method: .put)
        )

        try checkRoutesWithFourPathParametersAndContent(
            method: .patch,
            parameter: parameter,
            content: content,
            function: Routes.patch,
            check: check(method: .patch)
        )

        try checkRoutesWithFourPathParametersAndContent(
            method: .delete,
            parameter: parameter,
            content: content,
            function: Routes.delete,
            check: check(method: .delete)
        )

        try checkRoutesWithFourPathParametersAndContent(
            method: .options,
            parameter: parameter,
            content: content,
            function: Routes.options,
            check: check(method: .options)
        )
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
            ("testRoutesWithContent", testRoutesWithContent),
            ("testRoutesWithOnePathParameterAndContent", testRoutesWithOnePathParameterAndContent),
            ("testRoutesWithTwoPathParametersAndContent", testRoutesWithTwoPathParametersAndContent),
            ("testRoutesWithThreePathParametersAndContent", testRoutesWithThreePathParametersAndContent),
            ("testRoutesWithFourPathParametersAndContent", testRoutesWithFourPathParametersAndContent),
        ]
    }
}
