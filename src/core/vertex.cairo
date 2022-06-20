from starkware.cairo.common.bool import TRUE, FALSE

struct Vertex:
    member id : felt
end


func hashKey{vertex : Vertex}() -> (key : felt):
    tempvar res = 'Vertex' + vertex.id # TODO: string concatenation
    return (res)
end

func equals{vertex : Vertex}(other : Vertex) -> (yes_no : felt):
    if vertex.id == other.id:
        return (TRUE)
    else:
        return (FALSE)
    end
end
