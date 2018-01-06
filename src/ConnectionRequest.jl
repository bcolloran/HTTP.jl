module ConnectionRequest

import ..Layer, ..request
using ..URIs
using ..Messages
using ..ConnectionPool
using MbedTLS.SSLContext
import ..@debug, ..DEBUG_LEVEL


"""
    request(ConnectionPoolLayer, ::URI, ::Request, body) -> HTTP.Response

Retrieve an `IO` connection from the [`HTTP.ConnectionPool`](@ref).

Close the connection if the request throws an exception.
Otherwise leave it open so that it can be reused.
"""

abstract type ConnectionPoolLayer{Next <: Layer} <: Layer end
export ConnectionPoolLayer

function request(::Type{ConnectionPoolLayer{Next}}, uri::URI, req, body;
                 connectionpool::Bool=true, socket_type::Type=TCPSocket,
                 kw...) where Next

    SocketType = sockettype(uri, socket_type)
    if connectionpool
        SocketType = ConnectionPool.Transaction{SocketType}
    end
    io = getconnection(SocketType, uri.host, uri.port; kw...)

    try
        r = request(Next, io, req, body; kw...)
        if !connectionpool
            close(io)
        end
        return r
    catch e
        @debug 1 "❗️  ConnectionLayer $e. Closing: $io"
        close(io)
        rethrow(e)
    end
end


sockettype(uri::URI, default) = uri.scheme in ("wss", "https") ? SSLContext :
                                                                 default


end # module ConnectionRequest