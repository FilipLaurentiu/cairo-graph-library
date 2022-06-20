%builtins range_check

from starkware.cairo.common.dict_access import DictAccess
from starkware.cairo.common.dict import dict_write, dict_read, dict_update
from starkware.cairo.common.default_dict import default_dict_new
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.memcpy import memcpy

struct HashMap:
    member key_map : DictAccess*
    member value_map : DictAccess*
    member entries_len : felt
    member keys : felt*
    member values : felt*
end

struct KeyValue:
    member key : felt
    member value : felt
end

func new_(array_len : felt, array : KeyValue*) -> (instance : HashMap*):
    alloc_locals
    let (key_map_ptr : DictAccess*) = default_dict_new(0)
    let (value_map_ptr : DictAccess*) = default_dict_new(0)
    let keys : felt* = alloc()
    let values : felt* = alloc()
    local hash_map_res : HashMap* = new HashMap(key_map_ptr, value_map_ptr, 0, keys, values)

    _init_value_map{hash_map_ptr=hash_map_res}(array_len, array)

    return (hash_map_res)
end

func _init_value_map{hash_map_ptr : HashMap*}(array_len : felt, array : KeyValue*):
    if array_len == 0:
        return ()
    end
    set(array.key, array.value)
    return _init_value_map(array_len, array + 1)
end

func get{hash_map_ptr : HashMap*}(key : felt) -> (res : felt):
    let dict_access_ptr : DictAccess* = hash_map_ptr.value_map
    let (value : felt) = dict_read{dict_ptr=dict_access_ptr}(key)
    return (value)
end

func has{hash_map_ptr : HashMap*}(key : felt) -> (yes_no : felt):
    let (value : felt) = get(key)
    if value == 0:
        return (FALSE)
    else:
        return (TRUE)
    end
end

func set{hash_map_ptr : HashMap*}(key : felt, value : felt):
    let dict_access_ptr : DictAccess* = hash_map_ptr.value_map

    dict_write{dict_ptr=dict_access_ptr}(key, value)

    let new_entries_len : felt = hash_map_ptr.entries_len + 1
    assert [hash_map_ptr.keys + new_entries_len] = key
    assert [hash_map_ptr.values + new_entries_len] = value
    return ()
end

func delete{hash_map_ptr : HashMap*}(key : felt):
    alloc_locals
    let (value_to_be_removed : felt) = get(key)
    set(key, 0)

    let entries_len = hash_map_ptr.entries_len
    let (_, new_keys_array : felt*) = _find_and_replace(entries_len, hash_map_ptr.keys, 0, key)
    let (_, new_values_array : felt*) = _find_and_replace(
        entries_len, hash_map_ptr.values, 0, value_to_be_removed
    )

    tempvar new_hash_map_ptr : HashMap* = new HashMap(
        hash_map_ptr.key_map,
        hash_map_ptr.value_map,
        entries_len - 1,
        new_keys_array,
        new_values_array
        )
    hash_map_ptr = new_hash_map_ptr
    return ()
end

func _find_and_replace(array_len : felt, array : felt*, current_index : felt, value : felt) -> (
    arr_len : felt, arr : felt*
):
    if array_len == 0:
        return (array_len, array)
    end

    tempvar current_value = [array]
    if current_value == value:
        let (new_arr_len, new_arr : felt*) = _remove_at(array_len, array, current_index)
        return (new_arr_len, new_arr)
    end

    return _find_and_replace(array_len, array + 1, current_index + 1, value)
end

func _remove_at(arr_len : felt, arr : felt*, index : felt) -> (arr_len : felt, arr : felt*):
    alloc_locals
    let new_arr : felt* = alloc()
    memcpy(new_arr, arr, index)
    memcpy(new_arr + index, arr + index + 1, arr_len - index - 1)
    return (arr_len - 1, new_arr)
end

func clear{hash_map_ptr : HashMap*}():
    let (value_map_ptr : DictAccess*) = default_dict_new(0)
    hash_map_ptr.value_map = value_map_ptr
    return ()
end
