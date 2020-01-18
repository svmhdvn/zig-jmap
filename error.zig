const types = @import("types");

const jmap_error = struct {
    request_level: struct {
        const ProblemDetails = struct {
            /// A URI reference [RFC3986] that identifies the problem type.
            type: []const u8,

            /// A short, human-readable summary of the problem type.
            title: []const u8,

            /// The HTTP status code [RFC7231, 6] generated by the origin server for
            /// this occurrence of the problem.
            status: types.UnsignedInt,

            /// A human-readable explanation specific to this occurrence of the problem.
            detail: []u8,

            /// A URI reference that identifies the specific occurrence of the problem.
            instance: []u8,
        };

        const ErrorTemplate = struct {
            uri: []const u8,
            desc: []const u8,
            status: types.UnsignedInt,
        };

        // TODO verify status codes of the following errors
        const unknown_capability = ErrorTemplate{
            .uri = "urn:ietf:params:jmap:error:unknownCapability",
            .desc = "The client included a capability in the \"using\" " ++
                "property of the request that the server does not support.",
            .status = 400,
        };

        const not_json = ErrorTemplate{
            .uri = "urn:ietf:params:jmap:error:notJSON",
            .desc = "The content type of the request was not \"application/json\" or the " ++
                "request did not parse as I-JSON.",
            .status = 400,
        };

        const not_request = ErrorTemplate{
            .uri = "urn:ietf:params:jmap:error:notRequest",
            .desc = "The request parsed as JSON but did not match the type signature of " ++
                "the Request object.",
            .status = 400,
        };

        // TODO add extra property to the error
        const limit = ErrorTemplate{
            .uri = "urn:ietf:params:jmap:error:limit",
            .desc = "The request was not processed as it would have exceeded one of the " ++
                "request limits defined on the capability object, such as " ++
                "maxSizeRequest, maxCallsInRequest, or maxConcurrentRequests.",
            .status = 400,
        };

        fn createError(template: ErrorTemplate, detail: []u8, instance: []u8) ProblemDetails {
            return ProblemDetails{
                .type = template.uri,
                .title = template.desc,
                .status = template.status,
                .detail = detail,
                .instance = instance,
            };
        }
    },

    method_level: struct {
        const ErrorTemplate = struct {
            name: []const u8,
            desc: []const u8,
        };

        const server_unavailable = ErrorTemplate{
            .name = "serverUnavailable",
            .desc = "Some internal server resource was temporarily unavailable.",
        };

        const server_fail = ErrorTemplate{
            .name = "serverFail",
            .desc = "An unexpected or unknown error occurred during the processing of the " ++
                "call.  The method call made no changes to the server's state.",
        };

        const server_partial_fail = ErrorTemplate{
            .name = "serverPartialFail",
            .desc = "Some, but not all, expected changes described by the method occurred.  The " ++
                "client MUST resynchronise impacted data to determine server state.",
        };

        const unknown_method = ErrorTemplate{
            .name = "unknownMethod",
            .desc = "The server does not recognise this method name.",
        };

        const invalid_arguments = ErrorTemplate{
            .name = "invalidArguments",
            .desc = "One of the arguments is of the wrong type or is otherwise invalid, or " ++
                "a required argument is missing.",
        };

        const invalid_result_reference = ErrorTemplate{
            .name = "invalidResultReference",
            .desc = "The method used a result reference for one of its arguments, but this " ++
                "failed to resolve.",
        };

        const forbidden = ErrorTemplate{
            .name = "forbidden",
            .desc = "The method and arguments are valid, but executing the method would " ++
                "violate an Access Control List (ACL) or other permissions policy.",
        };

        const account_not_found = ErrorTemplate{
            .name = "accountNotFound",
            .desc = "The accountId does not correspond to a valid account.",
        };

        const account_not_supported_by_method = ErrorTemplate{
            .name = "accountNotSupportedByMethod",
            .desc = "The accountId given corresponds to a valid account, but the account does " ++
                "not support this method or data type.",
        };

        const account_read_only = ErrorTemplate{
            .name = "accountReadOnly",
            .desc = "This method modifies state, but the account is read-only.",
        };
    },
};
