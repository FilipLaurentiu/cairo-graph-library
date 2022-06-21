from starkware.cairo.common.dict_access import DictAccess
from starkware.cairo.common.default_dict import default_dict_new
from starkware.cairo.common.dict import dict_write, dict_read
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.hash import hash2
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.alloc import alloc

struct HashSet:
    member element_map : DictAccess*
    member entries_len : felt
    member keys : felt*
    member values : felt*
end

func new_{hash_ptr : HashBuiltin*}(values_len : felt, values : felt*) -> (instance : HashSet*):
    alloc_locals
    let (element_map_ptr : DictAccess*) = default_dict_new(0)
    let keys : felt* = alloc()
    let values : felt* = alloc()
    local new_instance : HashSet* = new HashSet(element_map_ptr, 0, keys, values)

    _init_element_map{hash_set_ptr=new_instance}(values_len, values)

    return (new_instance)
end

func _init_element_map{hash_set_ptr : HashSet*, hash_ptr : HashBuiltin*}(
    array_len : felt, array : felt*
):
    if array_len == 0:
        return ()
    end

    add(array[array_len - 1])
    return _init_element_map(array_len - 1, array + 1)
end

func add{hash_set_ptr : HashSet*, hash_ptr : HashBuiltin*}(value : felt) -> (updated : HashSet*):
    let element_map_ptr : DictAccess* = hash_set_ptr.element_map
    let (key : felt) = hash2(value, 0)
    dict_write{dict_ptr=element_map_ptr}(key, value)

    let new_entries_len : felt = hash_set_ptr.entries_len + 1
    assert [hash_set_ptr.keys + new_entries_len] = key
    assert [hash_set_ptr.values + new_entries_len] = value

    tempvar updated : HashSet* = new HashSet(
        hash_set_ptr.element_map,
        new_entries_len,
        hash_set_ptr.keys,
        hash_set_ptr.values
        )
    return (updated)
end

func clear{hash_map_ptr : HashSet*, hash_ptr : HashBuiltin*}() -> (updated : HashSet*):
    let (empty_array : felt*) = alloc()
    let (new_hash_set_ptr : HashSet*) = new_(0, empty_array)
    return (new_hash_set_ptr)
end

func has{hash_set_ptr : HashSet*, hash_ptr : HashBuiltin*}(value : felt) -> (yes_no : felt):
    let element_map_ptr : DictAccess* = hash_set_ptr.element_map
    let (hash : felt) = hash2(value, 0)
    let (stored_value : felt) = dict_read{dict_ptr=element_map_ptr}(hash)
    if stored_value == value:
        return (TRUE)
    else:
        return (FALSE)
    end
end

func delete{hash_set_ptr : HashSet*}(key : felt):
    let element_map_ptr : DictAccess* = hash_set_ptr.element_map
    dict_write{dict_ptr=element_map_ptr}(key, 0)
    return ()
end

func size{hash_set_ptr : HashSet*}() -> (size : felt):
    let size : felt = hash_set_ptr.entries_len
    return (size)
end

func keys{hash_set_ptr : HashSet*}() -> (res_len : felt, res : felt*):
    let keys_array : felt* = hash_set_ptr.keys
    return (hash_set_ptr.entries_len, keys_array)
end

func values{hash_set_ptr : HashSet*}() -> (res_len : felt, res : felt*):
    let values_array : felt* = hash_set_ptr.values
    return (hash_set_ptr.entries_len, values_array)
end

func entries{hash_set_ptr : HashSet*}() -> (entries_len : felt, entries : felt*):
    alloc_locals
    tempvar entries_len = hash_set_ptr.entries_len
    let keys : felt* = hash_set_ptr.keys
    let entries : felt* = alloc()

    _get_entries(entries_len, keys, entries)
    return (entries_len, entries)
end

func _get_entries{hash_set_ptr : HashSet*}(keys_len : felt, keys : felt*, entries : felt*):
    if keys_len == 0:
        return ()
    end
    let element_map_ptr : DictAccess* = hash_set_ptr.element_map
    tempvar key = [keys]
    let (value : felt) = dict_read{dict_ptr=element_map_ptr}(key)
    assert [entries] = value

    return _get_entries(keys_len - 1, keys + 1, entries)
end
