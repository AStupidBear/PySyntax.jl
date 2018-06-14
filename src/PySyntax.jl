module PySyntax

using PyCall

export @py

function traverse!{T}(arg::T)::T
    return arg
end

function traverse!(expr::Expr)

    # (x::String:y::String) => slice(x, y)
    if expr.head == :(:)
        expr.head = :(call)
        if length(expr.args) == 2
            push!(expr.args, :nothing)
        end
        unshift!(expr.args, :(pybuiltin("slice")))
    end

    for (i, arg) in enumerate(expr.args)
        if arg  == :(:)
            expr.args[i] = :(pybuiltin("slice")(nothing, nothing, nothing))
        end
        traverse!(expr.args[i])
    end

    # df.loc => df[:loc]
    if expr.head == :(.)
        expr.head = :(ref)
    end

    return expr
end

macro py(expr::Expr)
    traverse!(expr)
    return expr
end

macro py(expr::Symbol)
    return expr
end

Base.getindex(x::PyObject, idxs...) = pycall(x[:__getitem__], PyObject, tuple(idxs...))
Base.setindex!(x::PyObject, value, idxs...) = pycall(x[:__setitem__], PyObject, tuple(idxs...), value)

end # module
