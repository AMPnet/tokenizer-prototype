%lang starknet

from evm.array import validate_array
from evm.calls import calldataload, calldatasize, caller
from evm.exec_env import ExecutionEnvironment
from evm.hashing import uint256_pedersen
from evm.memory import uint256_mload, uint256_mstore
from evm.uint256 import (
    is_eq, is_gt, is_lt, is_zero, slt, u256_add, u256_div, u256_mul, u256_shl, u256_shr)
from evm.yul_api import log2, log3, timestamp, warp_call, warp_return
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin
from starkware.cairo.common.default_dict import default_dict_finalize, default_dict_new
from starkware.cairo.common.dict_access import DictAccess
from starkware.cairo.common.registers import get_fp_and_pc
from starkware.cairo.common.uint256 import Uint256, uint256_and, uint256_or, uint256_sub

func sload{pedersen_ptr : HashBuiltin*, range_check_ptr, syscall_ptr : felt*}(key : Uint256) -> (
        value : Uint256):
    let (value) = evm_storage.read(key)
    return (value)
end

func sstore{pedersen_ptr : HashBuiltin*, range_check_ptr, syscall_ptr : felt*}(
        key : Uint256, value : Uint256):
    evm_storage.write(key, value)
    return ()
end

func __warp_identity_Uint256(arg0 : Uint256) -> (arg0 : Uint256):
    return (arg0)
end

func __warp_constant_0() -> (res : Uint256):
    return (Uint256(low=0, high=0))
end

@storage_var
func evm_storage(arg0 : Uint256) -> (res : Uint256):
end

@constructor
func constructor{
        bitwise_ptr : BitwiseBuiltin*, pedersen_ptr : HashBuiltin*, range_check_ptr,
        syscall_ptr : felt*}(calldata_size, calldata_len, calldata : felt*):
    alloc_locals
    validate_array(calldata_size, calldata_len, calldata)
    let (__fp__, _) = get_fp_and_pc()
    local exec_env_ : ExecutionEnvironment = ExecutionEnvironment(calldata_size=calldata_size, calldata_len=calldata_len, calldata=calldata, returndata_size=0, returndata_len=0, returndata=cast(0, felt*), to_returndata_size=0, to_returndata_len=0, to_returndata=cast(0, felt*))
    let exec_env : ExecutionEnvironment* = &exec_env_
    let (memory_dict) = default_dict_new(0)
    let memory_dict_start = memory_dict
    let msize = 0
    with exec_env, memory_dict, msize:
        __constructor_meat()
    end
    default_dict_finalize(memory_dict_start, memory_dict, 0)
    return ()
end

@external
func __main{
        bitwise_ptr : BitwiseBuiltin*, pedersen_ptr : HashBuiltin*, range_check_ptr,
        syscall_ptr : felt*}(calldata_size, calldata_len, calldata : felt*) -> (
        returndata_size, returndata_len, returndata : felt*):
    alloc_locals
    validate_array(calldata_size, calldata_len, calldata)
    let (__fp__, _) = get_fp_and_pc()
    local exec_env_ : ExecutionEnvironment = ExecutionEnvironment(calldata_size=calldata_size, calldata_len=calldata_len, calldata=calldata, returndata_size=0, returndata_len=0, returndata=cast(0, felt*), to_returndata_size=0, to_returndata_len=0, to_returndata=cast(0, felt*))
    let exec_env : ExecutionEnvironment* = &exec_env_
    let (memory_dict) = default_dict_new(0)
    let memory_dict_start = memory_dict
    let msize = 0
    let termination_token = 0
    with exec_env, memory_dict, msize, termination_token:
        __main_meat()
    end
    default_dict_finalize(memory_dict_start, memory_dict, 0)
    return (exec_env.to_returndata_size, exec_env.to_returndata_len, exec_env.to_returndata)
end

func __warp_loop_body_0{
        bitwise_ptr : BitwiseBuiltin*, exec_env : ExecutionEnvironment*, memory_dict : DictAccess*,
        msize, range_check_ptr}(_2 : Uint256, dst : Uint256, src : Uint256) -> (dst : Uint256):
    alloc_locals
    let (__warp_subexpr_0 : Uint256) = calldataload(src)
    uint256_mstore(offset=dst, value=__warp_subexpr_0)
    let (dst : Uint256) = u256_add(dst, _2)
    return (dst)
end

func __warp_loop_0{
        bitwise_ptr : BitwiseBuiltin*, exec_env : ExecutionEnvironment*, memory_dict : DictAccess*,
        msize, range_check_ptr}(_2 : Uint256, dst : Uint256, src : Uint256, srcEnd : Uint256) -> (
        dst : Uint256, src : Uint256):
    alloc_locals
    let (__warp_subexpr_1 : Uint256) = is_lt(src, srcEnd)
    let (__warp_subexpr_0 : Uint256) = is_zero(__warp_subexpr_1)
    if __warp_subexpr_0.low + __warp_subexpr_0.high != 0:
        return (dst, src)
    end
    let (dst : Uint256) = __warp_loop_body_0(_2, dst, src)
    let (src : Uint256) = u256_add(src, _2)
    let (dst : Uint256, src : Uint256) = __warp_loop_0(_2, dst, src, srcEnd)
    return (dst, src)
end

func require_helper_stringliteral_fe80{range_check_ptr}(condition : Uint256) -> ():
    alloc_locals
    let (__warp_subexpr_0 : Uint256) = is_zero(condition)
    if __warp_subexpr_0.low + __warp_subexpr_0.high != 0:
        assert 0 = 1
        jmp rel 0
    else:
        return ()
    end
end

func memory_array_index_access_address_dyn{
        bitwise_ptr : BitwiseBuiltin*, memory_dict : DictAccess*, msize, range_check_ptr}(
        baseRef : Uint256, index : Uint256) -> (addr : Uint256):
    alloc_locals
    let (__warp_subexpr_2 : Uint256) = uint256_mload(baseRef)
    let (__warp_subexpr_1 : Uint256) = is_lt(index, __warp_subexpr_2)
    let (__warp_subexpr_0 : Uint256) = is_zero(__warp_subexpr_1)
    if __warp_subexpr_0.low + __warp_subexpr_0.high != 0:
        assert 0 = 1
        jmp rel 0
    end
    let (__warp_subexpr_4 : Uint256) = u256_shl(Uint256(low=5, high=0), index)
    let (__warp_subexpr_3 : Uint256) = u256_add(baseRef, __warp_subexpr_4)
    let (addr : Uint256) = u256_add(__warp_subexpr_3, Uint256(low=32, high=0))
    return (addr)
end

func require_helper_stringliteral_ee61{range_check_ptr}(condition : Uint256) -> ():
    alloc_locals
    let (__warp_subexpr_0 : Uint256) = is_zero(condition)
    if __warp_subexpr_0.low + __warp_subexpr_0.high != 0:
        assert 0 = 1
        jmp rel 0
    else:
        return ()
    end
end

func mapping_index_access_mapping_address_bool_of_address{
        bitwise_ptr : BitwiseBuiltin*, memory_dict : DictAccess*, msize,
        pedersen_ptr : HashBuiltin*, range_check_ptr}(key : Uint256) -> (dataSlot : Uint256):
    alloc_locals
    uint256_mstore(offset=Uint256(low=0, high=0), value=key)
    uint256_mstore(offset=Uint256(low=32, high=0), value=Uint256(low=1, high=0))
    let (dataSlot : Uint256) = uint256_pedersen(Uint256(low=0, high=0), Uint256(low=64, high=0))
    return (dataSlot)
end

func update_storage_value_offsett_bool_to_bool{
        bitwise_ptr : BitwiseBuiltin*, pedersen_ptr : HashBuiltin*, range_check_ptr,
        syscall_ptr : felt*}(slot : Uint256) -> ():
    alloc_locals
    let (__warp_subexpr_2 : Uint256) = sload(slot)
    let (__warp_subexpr_1 : Uint256) = uint256_and(
        __warp_subexpr_2,
        Uint256(low=340282366920938463463374607431768211200, high=340282366920938463463374607431768211455))
    let (__warp_subexpr_0 : Uint256) = uint256_or(__warp_subexpr_1, Uint256(low=1, high=0))
    sstore(key=slot, value=__warp_subexpr_0)
    return ()
end

func __warp_loop_body_1{
        bitwise_ptr : BitwiseBuiltin*, memory_dict : DictAccess*, msize,
        pedersen_ptr : HashBuiltin*, range_check_ptr, syscall_ptr : felt*}(
        __warp_break_1 : Uint256, var_callers_mpos : Uint256, var_i : Uint256) -> (
        __warp_break_1 : Uint256):
    alloc_locals
    let (__warp_subexpr_2 : Uint256) = uint256_mload(var_callers_mpos)
    let (__warp_subexpr_1 : Uint256) = is_lt(var_i, __warp_subexpr_2)
    let (__warp_subexpr_0 : Uint256) = is_zero(__warp_subexpr_1)
    if __warp_subexpr_0.low + __warp_subexpr_0.high != 0:
        let __warp_break_1 : Uint256 = Uint256(low=1, high=0)
        return (__warp_break_1)
    end
    let (__warp_subexpr_6 : Uint256) = memory_array_index_access_address_dyn(
        var_callers_mpos, var_i)
    let (__warp_subexpr_5 : Uint256) = uint256_mload(__warp_subexpr_6)
    let (__warp_subexpr_4 : Uint256) = is_zero(__warp_subexpr_5)
    let (__warp_subexpr_3 : Uint256) = is_zero(__warp_subexpr_4)
    require_helper_stringliteral_ee61(__warp_subexpr_3)
    let (__warp_subexpr_9 : Uint256) = memory_array_index_access_address_dyn(
        var_callers_mpos, var_i)
    let (__warp_subexpr_8 : Uint256) = uint256_mload(__warp_subexpr_9)
    let (__warp_subexpr_7 : Uint256) = mapping_index_access_mapping_address_bool_of_address(
        __warp_subexpr_8)
    update_storage_value_offsett_bool_to_bool(__warp_subexpr_7)
    return (__warp_break_1)
end

func increment_uint256_deployment{range_check_ptr}(value : Uint256) -> (
        ret__warp_mangled : Uint256):
    alloc_locals
    let (__warp_subexpr_0 : Uint256) = is_eq(
        value,
        Uint256(low=340282366920938463463374607431768211455, high=340282366920938463463374607431768211455))
    if __warp_subexpr_0.low + __warp_subexpr_0.high != 0:
        assert 0 = 1
        jmp rel 0
    end
    let (ret__warp_mangled : Uint256) = u256_add(value, Uint256(low=1, high=0))
    return (ret__warp_mangled)
end

func __warp_loop_1{
        bitwise_ptr : BitwiseBuiltin*, memory_dict : DictAccess*, msize,
        pedersen_ptr : HashBuiltin*, range_check_ptr, syscall_ptr : felt*}(
        var_callers_mpos : Uint256, var_i : Uint256) -> (var_i : Uint256):
    alloc_locals
    let __warp_break_1 : Uint256 = Uint256(low=0, high=0)
    let (__warp_subexpr_0 : Uint256) = is_zero(Uint256(low=1, high=0))
    if __warp_subexpr_0.low + __warp_subexpr_0.high != 0:
        return (var_i)
    end
    let (__warp_break_1 : Uint256) = __warp_loop_body_1(__warp_break_1, var_callers_mpos, var_i)
    if __warp_break_1.low + __warp_break_1.high != 0:
        return (var_i)
    end
    let (var_i : Uint256) = increment_uint256_deployment(var_i)
    let (var_i : Uint256) = __warp_loop_1(var_callers_mpos, var_i)
    return (var_i)
end

func update_storage_value_offsett_address_to_address{
        pedersen_ptr : HashBuiltin*, range_check_ptr, syscall_ptr : felt*}(value : Uint256) -> ():
    alloc_locals
    sstore(key=Uint256(low=2, high=0), value=value)
    return ()
end

func update_storage_value_offsett_address_to_address_1474{
        pedersen_ptr : HashBuiltin*, range_check_ptr, syscall_ptr : felt*}(value : Uint256) -> ():
    alloc_locals
    sstore(key=Uint256(low=3, high=0), value=value)
    return ()
end

func constructor_FaucetService{
        bitwise_ptr : BitwiseBuiltin*, memory_dict : DictAccess*, msize,
        pedersen_ptr : HashBuiltin*, range_check_ptr, syscall_ptr : felt*}(
        var_masterOwner : Uint256, var_callers_mpos : Uint256, var_rewardPerApprove : Uint256,
        var_balanceThresholdForReward : Uint256) -> ():
    alloc_locals
    let (__warp_subexpr_0 : Uint256) = is_zero(var_masterOwner)
    if __warp_subexpr_0.low + __warp_subexpr_0.high != 0:
        assert 0 = 1
        jmp rel 0
    end
    let (__warp_subexpr_2 : Uint256) = is_zero(var_rewardPerApprove)
    let (__warp_subexpr_1 : Uint256) = is_zero(__warp_subexpr_2)
    require_helper_stringliteral_fe80(__warp_subexpr_1)
    let var_i : Uint256 = Uint256(low=0, high=0)
    let (var_i : Uint256) = __warp_loop_1(var_callers_mpos, var_i)
    sstore(key=Uint256(low=0, high=0), value=var_masterOwner)
    update_storage_value_offsett_address_to_address(var_rewardPerApprove)
    update_storage_value_offsett_address_to_address_1474(var_balanceThresholdForReward)
    return ()
end

func __constructor_meat{
        bitwise_ptr : BitwiseBuiltin*, exec_env : ExecutionEnvironment*, memory_dict : DictAccess*,
        msize, pedersen_ptr : HashBuiltin*, range_check_ptr, syscall_ptr : felt*}() -> ():
    alloc_locals
    let (__warp_subexpr_0 : Uint256) = __warp_identity_Uint256(Uint256(low=128, high=0))
    uint256_mstore(offset=Uint256(low=64, high=0), value=__warp_subexpr_0)
    let (__warp_subexpr_1 : Uint256) = __warp_constant_0()
    if __warp_subexpr_1.low + __warp_subexpr_1.high != 0:
        assert 0 = 1
        jmp rel 0
    end
    let (__warp_subexpr_3 : Uint256) = calldatasize()
    let (__warp_subexpr_2 : Uint256) = slt(__warp_subexpr_3, Uint256(low=128, high=0))
    if __warp_subexpr_2.low + __warp_subexpr_2.high != 0:
        assert 0 = 1
        jmp rel 0
    end
    let (offset : Uint256) = calldataload(Uint256(low=32, high=0))
    let (__warp_subexpr_4 : Uint256) = is_gt(offset, Uint256(low=18446744073709551615, high=0))
    if __warp_subexpr_4.low + __warp_subexpr_4.high != 0:
        assert 0 = 1
        jmp rel 0
    end
    let (__warp_subexpr_8 : Uint256) = calldatasize()
    let (__warp_subexpr_7 : Uint256) = u256_add(offset, Uint256(low=31, high=0))
    let (__warp_subexpr_6 : Uint256) = slt(__warp_subexpr_7, __warp_subexpr_8)
    let (__warp_subexpr_5 : Uint256) = is_zero(__warp_subexpr_6)
    if __warp_subexpr_5.low + __warp_subexpr_5.high != 0:
        assert 0 = 1
        jmp rel 0
    end
    let (_4 : Uint256) = calldataload(offset)
    let (__warp_subexpr_9 : Uint256) = is_gt(_4, Uint256(low=18446744073709551615, high=0))
    if __warp_subexpr_9.low + __warp_subexpr_9.high != 0:
        assert 0 = 1
        jmp rel 0
    end
    let (_5 : Uint256) = u256_shl(Uint256(low=5, high=0), _4)
    let (memPtr : Uint256) = uint256_mload(Uint256(low=64, high=0))
    let (__warp_subexpr_11 : Uint256) = u256_add(_5, Uint256(low=63, high=0))
    let (__warp_subexpr_10 : Uint256) = uint256_and(
        __warp_subexpr_11,
        Uint256(low=340282366920938463463374607431768211424, high=340282366920938463463374607431768211455))
    let (newFreePtr : Uint256) = u256_add(memPtr, __warp_subexpr_10)
    let (__warp_subexpr_14 : Uint256) = is_lt(newFreePtr, memPtr)
    let (__warp_subexpr_13 : Uint256) = is_gt(newFreePtr, Uint256(low=18446744073709551615, high=0))
    let (__warp_subexpr_12 : Uint256) = uint256_or(__warp_subexpr_13, __warp_subexpr_14)
    if __warp_subexpr_12.low + __warp_subexpr_12.high != 0:
        assert 0 = 1
        jmp rel 0
    end
    uint256_mstore(offset=Uint256(low=64, high=0), value=newFreePtr)
    uint256_mstore(offset=memPtr, value=_4)
    let (dst : Uint256) = u256_add(memPtr, Uint256(low=32, high=0))
    let (__warp_subexpr_15 : Uint256) = u256_add(offset, _5)
    let (srcEnd : Uint256) = u256_add(__warp_subexpr_15, Uint256(low=32, high=0))
    let (__warp_subexpr_17 : Uint256) = calldatasize()
    let (__warp_subexpr_16 : Uint256) = is_gt(srcEnd, __warp_subexpr_17)
    if __warp_subexpr_16.low + __warp_subexpr_16.high != 0:
        assert 0 = 1
        jmp rel 0
    end
    let (src : Uint256) = u256_add(offset, Uint256(low=32, high=0))
    let (dst : Uint256, src : Uint256) = __warp_loop_0(Uint256(low=32, high=0), dst, src, srcEnd)
    let (__warp_subexpr_20 : Uint256) = calldataload(Uint256(low=96, high=0))
    let (__warp_subexpr_19 : Uint256) = calldataload(Uint256(low=64, high=0))
    let (__warp_subexpr_18 : Uint256) = calldataload(Uint256(low=0, high=0))
    constructor_FaucetService(__warp_subexpr_18, memPtr, __warp_subexpr_19, __warp_subexpr_20)
    return ()
end

func abi_decode_uint256{
        bitwise_ptr : BitwiseBuiltin*, exec_env : ExecutionEnvironment*, range_check_ptr}(
        dataEnd : Uint256) -> (value0 : Uint256):
    alloc_locals
    let (__warp_subexpr_1 : Uint256) = u256_add(
        dataEnd,
        Uint256(low=340282366920938463463374607431768211452, high=340282366920938463463374607431768211455))
    let (__warp_subexpr_0 : Uint256) = slt(__warp_subexpr_1, Uint256(low=32, high=0))
    if __warp_subexpr_0.low + __warp_subexpr_0.high != 0:
        assert 0 = 1
        jmp rel 0
    end
    let (value0 : Uint256) = calldataload(Uint256(low=4, high=0))
    return (value0)
end

func require_helper_stringliteral_c7ba{range_check_ptr}(condition : Uint256) -> ():
    alloc_locals
    let (__warp_subexpr_0 : Uint256) = is_zero(condition)
    if __warp_subexpr_0.low + __warp_subexpr_0.high != 0:
        assert 0 = 1
        jmp rel 0
    else:
        return ()
    end
end

func abi_encode_uint256_uint256_uint256{memory_dict : DictAccess*, msize, range_check_ptr}(
        headStart : Uint256, value0 : Uint256, value1 : Uint256, value2 : Uint256) -> (
        tail : Uint256):
    alloc_locals
    let (tail : Uint256) = u256_add(headStart, Uint256(low=96, high=0))
    uint256_mstore(offset=headStart, value=value0)
    let (__warp_subexpr_0 : Uint256) = u256_add(headStart, Uint256(low=32, high=0))
    uint256_mstore(offset=__warp_subexpr_0, value=value1)
    let (__warp_subexpr_1 : Uint256) = u256_add(headStart, Uint256(low=64, high=0))
    uint256_mstore(offset=__warp_subexpr_1, value=value2)
    return (tail)
end

func modifier_isMasterOwner_265{
        bitwise_ptr : BitwiseBuiltin*, memory_dict : DictAccess*, msize,
        pedersen_ptr : HashBuiltin*, range_check_ptr, syscall_ptr : felt*}(
        var_newRewardAmount : Uint256) -> ():
    alloc_locals
    let (__warp_subexpr_2 : Uint256) = sload(Uint256(low=0, high=0))
    let (__warp_subexpr_1 : Uint256) = caller()
    let (__warp_subexpr_0 : Uint256) = is_eq(__warp_subexpr_1, __warp_subexpr_2)
    require_helper_stringliteral_c7ba(__warp_subexpr_0)
    let (__warp_subexpr_3 : Uint256) = is_zero(var_newRewardAmount)
    if __warp_subexpr_3.low + __warp_subexpr_3.high != 0:
        assert 0 = 1
        jmp rel 0
    end
    let (_1 : Uint256) = sload(Uint256(low=2, high=0))
    sstore(key=Uint256(low=2, high=0), value=var_newRewardAmount)
    let (_2 : Uint256) = uint256_mload(Uint256(low=64, high=0))
    let (__warp_subexpr_7 : Uint256) = timestamp()
    let (__warp_subexpr_6 : Uint256) = abi_encode_uint256_uint256_uint256(
        _2, _1, var_newRewardAmount, __warp_subexpr_7)
    let (__warp_subexpr_5 : Uint256) = caller()
    let (__warp_subexpr_4 : Uint256) = uint256_sub(__warp_subexpr_6, _2)
    log2(
        _2,
        __warp_subexpr_4,
        Uint256(low=117835796517503045363758807112809158519, high=154075382369021983663323892198450954360),
        __warp_subexpr_5)
    return ()
end

func abi_decode{range_check_ptr}(dataEnd : Uint256) -> ():
    alloc_locals
    let (__warp_subexpr_1 : Uint256) = u256_add(
        dataEnd,
        Uint256(low=340282366920938463463374607431768211452, high=340282366920938463463374607431768211455))
    let (__warp_subexpr_0 : Uint256) = slt(__warp_subexpr_1, Uint256(low=0, high=0))
    if __warp_subexpr_0.low + __warp_subexpr_0.high != 0:
        assert 0 = 1
        jmp rel 0
    else:
        return ()
    end
end

func abi_encode_uint256{memory_dict : DictAccess*, msize, range_check_ptr}(
        headStart : Uint256, value0 : Uint256) -> (tail : Uint256):
    alloc_locals
    let (tail : Uint256) = u256_add(headStart, Uint256(low=32, high=0))
    uint256_mstore(offset=headStart, value=value0)
    return (tail)
end

func copy_literal_to_memory_34cbde018cc85df09c7836603e02c1477be200a8496f18ab8d94c0f076bb70b3{
        bitwise_ptr : BitwiseBuiltin*, memory_dict : DictAccess*, msize, range_check_ptr}() -> (
        memPtr : Uint256):
    alloc_locals
    let (memPtr_1 : Uint256) = uint256_mload(Uint256(low=64, high=0))
    let (newFreePtr : Uint256) = u256_add(memPtr_1, Uint256(low=64, high=0))
    let (__warp_subexpr_2 : Uint256) = is_lt(newFreePtr, memPtr_1)
    let (__warp_subexpr_1 : Uint256) = is_gt(newFreePtr, Uint256(low=18446744073709551615, high=0))
    let (__warp_subexpr_0 : Uint256) = uint256_or(__warp_subexpr_1, __warp_subexpr_2)
    if __warp_subexpr_0.low + __warp_subexpr_0.high != 0:
        assert 0 = 1
        jmp rel 0
    end
    uint256_mstore(offset=Uint256(low=64, high=0), value=newFreePtr)
    uint256_mstore(offset=memPtr_1, value=Uint256(low=6, high=0))
    let memPtr : Uint256 = memPtr_1
    let (__warp_subexpr_3 : Uint256) = u256_add(memPtr_1, Uint256(low=32, high=0))
    uint256_mstore(
        offset=__warp_subexpr_3, value=Uint256(low=0, high=65371994664951694719768928261314183168))
    return (memPtr)
end

func __warp_loop_body_2{
        bitwise_ptr : BitwiseBuiltin*, memory_dict : DictAccess*, msize, range_check_ptr}(
        _1 : Uint256, headStart : Uint256, i : Uint256, value0 : Uint256) -> ():
    alloc_locals
    let (__warp_subexpr_4 : Uint256) = u256_add(value0, i)
    let (__warp_subexpr_3 : Uint256) = u256_add(__warp_subexpr_4, _1)
    let (__warp_subexpr_2 : Uint256) = u256_add(headStart, i)
    let (__warp_subexpr_1 : Uint256) = uint256_mload(__warp_subexpr_3)
    let (__warp_subexpr_0 : Uint256) = u256_add(__warp_subexpr_2, Uint256(low=64, high=0))
    uint256_mstore(offset=__warp_subexpr_0, value=__warp_subexpr_1)
    return ()
end

func __warp_loop_2{
        bitwise_ptr : BitwiseBuiltin*, memory_dict : DictAccess*, msize, range_check_ptr}(
        _1 : Uint256, headStart : Uint256, i : Uint256, length : Uint256, value0 : Uint256) -> (
        i : Uint256):
    alloc_locals
    let (__warp_subexpr_1 : Uint256) = is_lt(i, length)
    let (__warp_subexpr_0 : Uint256) = is_zero(__warp_subexpr_1)
    if __warp_subexpr_0.low + __warp_subexpr_0.high != 0:
        return (i)
    end
    __warp_loop_body_2(_1, headStart, i, value0)
    let (i : Uint256) = u256_add(i, _1)
    let (i : Uint256) = __warp_loop_2(_1, headStart, i, length, value0)
    return (i)
end

func __warp_block_0{memory_dict : DictAccess*, msize, range_check_ptr}(
        headStart : Uint256, length : Uint256) -> ():
    alloc_locals
    let (__warp_subexpr_1 : Uint256) = u256_add(headStart, length)
    let (__warp_subexpr_0 : Uint256) = u256_add(__warp_subexpr_1, Uint256(low=64, high=0))
    uint256_mstore(offset=__warp_subexpr_0, value=Uint256(low=0, high=0))
    return ()
end

func __warp_if_0{memory_dict : DictAccess*, msize, range_check_ptr}(
        __warp_subexpr_1 : Uint256, headStart : Uint256, length : Uint256) -> ():
    alloc_locals
    if __warp_subexpr_1.low + __warp_subexpr_1.high != 0:
        __warp_block_0(headStart, length)
        return ()
    else:
        return ()
    end
end

func abi_encode_string{
        bitwise_ptr : BitwiseBuiltin*, memory_dict : DictAccess*, msize, range_check_ptr}(
        headStart : Uint256, value0 : Uint256) -> (tail : Uint256):
    alloc_locals
    uint256_mstore(offset=headStart, value=Uint256(low=32, high=0))
    let (length : Uint256) = uint256_mload(value0)
    let (__warp_subexpr_0 : Uint256) = u256_add(headStart, Uint256(low=32, high=0))
    uint256_mstore(offset=__warp_subexpr_0, value=length)
    let i : Uint256 = Uint256(low=0, high=0)
    let (i : Uint256) = __warp_loop_2(Uint256(low=32, high=0), headStart, i, length, value0)
    let (__warp_subexpr_1 : Uint256) = is_gt(i, length)
    __warp_if_0(__warp_subexpr_1, headStart, length)
    let (__warp_subexpr_4 : Uint256) = u256_add(length, Uint256(low=31, high=0))
    let (__warp_subexpr_3 : Uint256) = uint256_and(
        __warp_subexpr_4,
        Uint256(low=340282366920938463463374607431768211424, high=340282366920938463463374607431768211455))
    let (__warp_subexpr_2 : Uint256) = u256_add(headStart, __warp_subexpr_3)
    let (tail : Uint256) = u256_add(__warp_subexpr_2, Uint256(low=64, high=0))
    return (tail)
end

func copy_literal_to_memory_2a0e4b5b88a71ee6b806854ef01e593c0fa6ef7a48f87d5cebb9d4d229570ed8{
        bitwise_ptr : BitwiseBuiltin*, memory_dict : DictAccess*, msize, range_check_ptr}() -> (
        memPtr : Uint256):
    alloc_locals
    let (memPtr_1 : Uint256) = uint256_mload(Uint256(low=64, high=0))
    let (newFreePtr : Uint256) = u256_add(memPtr_1, Uint256(low=64, high=0))
    let (__warp_subexpr_2 : Uint256) = is_lt(newFreePtr, memPtr_1)
    let (__warp_subexpr_1 : Uint256) = is_gt(newFreePtr, Uint256(low=18446744073709551615, high=0))
    let (__warp_subexpr_0 : Uint256) = uint256_or(__warp_subexpr_1, __warp_subexpr_2)
    if __warp_subexpr_0.low + __warp_subexpr_0.high != 0:
        assert 0 = 1
        jmp rel 0
    end
    uint256_mstore(offset=Uint256(low=64, high=0), value=newFreePtr)
    uint256_mstore(offset=memPtr_1, value=Uint256(low=15, high=0))
    let memPtr : Uint256 = memPtr_1
    let (__warp_subexpr_3 : Uint256) = u256_add(memPtr_1, Uint256(low=32, high=0))
    uint256_mstore(
        offset=__warp_subexpr_3, value=Uint256(low=0, high=93551993417132320755661250146694738176))
    return (memPtr)
end

func getter_fun_allowedCallers{
        bitwise_ptr : BitwiseBuiltin*, memory_dict : DictAccess*, msize,
        pedersen_ptr : HashBuiltin*, range_check_ptr, syscall_ptr : felt*}(key : Uint256) -> (
        ret__warp_mangled : Uint256):
    alloc_locals
    uint256_mstore(offset=Uint256(low=0, high=0), value=key)
    uint256_mstore(offset=Uint256(low=32, high=0), value=Uint256(low=1, high=0))
    let (__warp_subexpr_1 : Uint256) = uint256_pedersen(
        Uint256(low=0, high=0), Uint256(low=64, high=0))
    let (__warp_subexpr_0 : Uint256) = sload(__warp_subexpr_1)
    let (ret__warp_mangled : Uint256) = uint256_and(__warp_subexpr_0, Uint256(low=255, high=0))
    return (ret__warp_mangled)
end

func abi_encode_bool{memory_dict : DictAccess*, msize, range_check_ptr}(
        headStart : Uint256, value0 : Uint256) -> (tail : Uint256):
    alloc_locals
    let (tail : Uint256) = u256_add(headStart, Uint256(low=32, high=0))
    let (__warp_subexpr_1 : Uint256) = is_zero(value0)
    let (__warp_subexpr_0 : Uint256) = is_zero(__warp_subexpr_1)
    uint256_mstore(offset=headStart, value=__warp_subexpr_0)
    return (tail)
end

func abi_decode_array_address_payable_dyn_calldata{
        bitwise_ptr : BitwiseBuiltin*, exec_env : ExecutionEnvironment*, range_check_ptr}(
        dataEnd : Uint256) -> (value0 : Uint256, value1 : Uint256):
    alloc_locals
    let (__warp_subexpr_1 : Uint256) = u256_add(
        dataEnd,
        Uint256(low=340282366920938463463374607431768211452, high=340282366920938463463374607431768211455))
    let (__warp_subexpr_0 : Uint256) = slt(__warp_subexpr_1, Uint256(low=32, high=0))
    if __warp_subexpr_0.low + __warp_subexpr_0.high != 0:
        assert 0 = 1
        jmp rel 0
    end
    let (offset : Uint256) = calldataload(Uint256(low=4, high=0))
    let (__warp_subexpr_2 : Uint256) = is_gt(offset, Uint256(low=18446744073709551615, high=0))
    if __warp_subexpr_2.low + __warp_subexpr_2.high != 0:
        assert 0 = 1
        jmp rel 0
    end
    let (__warp_subexpr_5 : Uint256) = u256_add(offset, Uint256(low=35, high=0))
    let (__warp_subexpr_4 : Uint256) = slt(__warp_subexpr_5, dataEnd)
    let (__warp_subexpr_3 : Uint256) = is_zero(__warp_subexpr_4)
    if __warp_subexpr_3.low + __warp_subexpr_3.high != 0:
        assert 0 = 1
        jmp rel 0
    end
    let (__warp_subexpr_6 : Uint256) = u256_add(Uint256(low=4, high=0), offset)
    let (length : Uint256) = calldataload(__warp_subexpr_6)
    let (__warp_subexpr_7 : Uint256) = is_gt(length, Uint256(low=18446744073709551615, high=0))
    if __warp_subexpr_7.low + __warp_subexpr_7.high != 0:
        assert 0 = 1
        jmp rel 0
    end
    let (__warp_subexpr_11 : Uint256) = u256_shl(Uint256(low=5, high=0), length)
    let (__warp_subexpr_10 : Uint256) = u256_add(offset, __warp_subexpr_11)
    let (__warp_subexpr_9 : Uint256) = u256_add(__warp_subexpr_10, Uint256(low=36, high=0))
    let (__warp_subexpr_8 : Uint256) = is_gt(__warp_subexpr_9, dataEnd)
    if __warp_subexpr_8.low + __warp_subexpr_8.high != 0:
        assert 0 = 1
        jmp rel 0
    end
    let (value0 : Uint256) = u256_add(offset, Uint256(low=36, high=0))
    let value1 : Uint256 = length
    return (value0, value1)
end

func checked_mul_uint256{bitwise_ptr : BitwiseBuiltin*, range_check_ptr}(
        x : Uint256, y : Uint256) -> (product : Uint256):
    alloc_locals
    let (__warp_subexpr_4 : Uint256) = u256_div(
        Uint256(low=340282366920938463463374607431768211455, high=340282366920938463463374607431768211455),
        x)
    let (__warp_subexpr_3 : Uint256) = is_zero(x)
    let (__warp_subexpr_2 : Uint256) = is_gt(y, __warp_subexpr_4)
    let (__warp_subexpr_1 : Uint256) = is_zero(__warp_subexpr_3)
    let (__warp_subexpr_0 : Uint256) = uint256_and(__warp_subexpr_1, __warp_subexpr_2)
    if __warp_subexpr_0.low + __warp_subexpr_0.high != 0:
        assert 0 = 1
        jmp rel 0
    end
    let (product : Uint256) = u256_mul(x, y)
    return (product)
end

func require_helper_stringliteral_4bba{range_check_ptr}(condition : Uint256) -> ():
    alloc_locals
    let (__warp_subexpr_0 : Uint256) = is_zero(condition)
    if __warp_subexpr_0.low + __warp_subexpr_0.high != 0:
        assert 0 = 1
        jmp rel 0
    else:
        return ()
    end
end

func calldata_array_index_access_address_payable_dyn_calldata{range_check_ptr}(
        base_ref : Uint256, length : Uint256, index : Uint256) -> (addr : Uint256):
    alloc_locals
    let (__warp_subexpr_1 : Uint256) = is_lt(index, length)
    let (__warp_subexpr_0 : Uint256) = is_zero(__warp_subexpr_1)
    if __warp_subexpr_0.low + __warp_subexpr_0.high != 0:
        assert 0 = 1
        jmp rel 0
    end
    let (__warp_subexpr_2 : Uint256) = u256_shl(Uint256(low=5, high=0), index)
    let (addr : Uint256) = u256_add(base_ref, __warp_subexpr_2)
    return (addr)
end

func __warp_if_1(_4 : Uint256, __warp_subexpr_1 : Uint256) -> (_4 : Uint256):
    alloc_locals
    if __warp_subexpr_1.low + __warp_subexpr_1.high != 0:
        let _4 : Uint256 = Uint256(low=2300, high=0)
        return (_4)
    else:
        return (_4)
    end
end

func __warp_block_1{
        bitwise_ptr : BitwiseBuiltin*, exec_env : ExecutionEnvironment*, memory_dict : DictAccess*,
        msize, pedersen_ptr : HashBuiltin*, range_check_ptr, syscall_ptr : felt*}(
        _1 : Uint256, _2 : Uint256, var_i : Uint256, var_wallets_length : Uint256,
        var_wallets_offset : Uint256) -> ():
    alloc_locals
    let (__warp_subexpr_0 : Uint256) = calldata_array_index_access_address_payable_dyn_calldata(
        var_wallets_offset, var_wallets_length, var_i)
    let (returnValue : Uint256) = calldataload(__warp_subexpr_0)
    let (_3 : Uint256) = sload(_2)
    let _4 : Uint256 = _1
    let (__warp_subexpr_1 : Uint256) = is_zero(_3)
    let (_4 : Uint256) = __warp_if_1(_4, __warp_subexpr_1)
    let (__warp_subexpr_3 : Uint256) = warp_call(_4, returnValue, _3, _1, _1, _1, _1)
    let (__warp_subexpr_2 : Uint256) = is_zero(__warp_subexpr_3)
    if __warp_subexpr_2.low + __warp_subexpr_2.high != 0:
        assert 0 = 1
        jmp rel 0
    end
    let (__warp_subexpr_4 : Uint256) = calldata_array_index_access_address_payable_dyn_calldata(
        var_wallets_offset, var_wallets_length, var_i)
    let (returnValue_1 : Uint256) = calldataload(__warp_subexpr_4)
    let (_5 : Uint256) = sload(_2)
    let (_6 : Uint256) = uint256_mload(Uint256(low=64, high=0))
    let (__warp_subexpr_7 : Uint256) = abi_encode_uint256(_6, _5)
    let (__warp_subexpr_6 : Uint256) = caller()
    let (__warp_subexpr_5 : Uint256) = uint256_sub(__warp_subexpr_7, _6)
    log3(
        _6,
        __warp_subexpr_5,
        Uint256(low=67857168057183061434811153466507652766, high=293548557951542090128779045687447968405),
        __warp_subexpr_6,
        returnValue_1)
    return ()
end

func __warp_if_2{
        bitwise_ptr : BitwiseBuiltin*, exec_env : ExecutionEnvironment*, memory_dict : DictAccess*,
        msize, pedersen_ptr : HashBuiltin*, range_check_ptr, syscall_ptr : felt*}(
        _1 : Uint256, _2 : Uint256, __warp_subexpr_2 : Uint256, var_i : Uint256,
        var_wallets_length : Uint256, var_wallets_offset : Uint256) -> ():
    alloc_locals
    if __warp_subexpr_2.low + __warp_subexpr_2.high != 0:
        __warp_block_1(_1, _2, var_i, var_wallets_length, var_wallets_offset)
        return ()
    else:
        return ()
    end
end

func __warp_loop_body_3{
        bitwise_ptr : BitwiseBuiltin*, exec_env : ExecutionEnvironment*, memory_dict : DictAccess*,
        msize, pedersen_ptr : HashBuiltin*, range_check_ptr, syscall_ptr : felt*,
        termination_token}(
        _1 : Uint256, _2 : Uint256, var_i : Uint256, var_wallets_length : Uint256,
        var_wallets_offset : Uint256) -> ():
    alloc_locals
    let (__warp_subexpr_1 : Uint256) = calldata_array_index_access_address_payable_dyn_calldata(
        var_wallets_offset, var_wallets_length, var_i)
    let (__warp_subexpr_0 : Uint256) = calldataload(__warp_subexpr_1)
    let (expr_2 : Uint256) = balance(__warp_subexpr_0)
    if termination_token == 1:
        return ()
    end
    let (__warp_subexpr_4 : Uint256) = sload(Uint256(low=3, high=0))
    let (__warp_subexpr_3 : Uint256) = is_gt(expr_2, __warp_subexpr_4)
    let (__warp_subexpr_2 : Uint256) = is_zero(__warp_subexpr_3)
    __warp_if_2(_1, _2, __warp_subexpr_2, var_i, var_wallets_length, var_wallets_offset)
    return ()
end

func increment_uint256{range_check_ptr}(value : Uint256) -> (ret__warp_mangled : Uint256):
    alloc_locals
    let (__warp_subexpr_0 : Uint256) = is_eq(
        value,
        Uint256(low=340282366920938463463374607431768211455, high=340282366920938463463374607431768211455))
    if __warp_subexpr_0.low + __warp_subexpr_0.high != 0:
        assert 0 = 1
        jmp rel 0
    end
    let (ret__warp_mangled : Uint256) = u256_add(value, Uint256(low=1, high=0))
    return (ret__warp_mangled)
end

func __warp_loop_3{
        bitwise_ptr : BitwiseBuiltin*, exec_env : ExecutionEnvironment*, memory_dict : DictAccess*,
        msize, pedersen_ptr : HashBuiltin*, range_check_ptr, syscall_ptr : felt*,
        termination_token}(
        _1 : Uint256, _2 : Uint256, var_i : Uint256, var_wallets_length : Uint256,
        var_wallets_offset : Uint256) -> (var_i : Uint256):
    alloc_locals
    let (__warp_subexpr_1 : Uint256) = is_lt(var_i, var_wallets_length)
    let (__warp_subexpr_0 : Uint256) = is_zero(__warp_subexpr_1)
    if __warp_subexpr_0.low + __warp_subexpr_0.high != 0:
        return (var_i)
    end
    __warp_loop_body_3(_1, _2, var_i, var_wallets_length, var_wallets_offset)
    if termination_token == 1:
        return (Uint256(0, 0))
    end
    let (var_i : Uint256) = increment_uint256(var_i)
    let (var_i : Uint256) = __warp_loop_3(_1, _2, var_i, var_wallets_length, var_wallets_offset)
    return (var_i)
end

func __warp_block_2{
        bitwise_ptr : BitwiseBuiltin*, memory_dict : DictAccess*, msize,
        pedersen_ptr : HashBuiltin*, range_check_ptr, syscall_ptr : felt*}() -> (expr : Uint256):
    alloc_locals
    let (__warp_subexpr_0 : Uint256) = caller()
    uint256_mstore(offset=Uint256(low=0, high=0), value=__warp_subexpr_0)
    uint256_mstore(offset=Uint256(low=32, high=0), value=Uint256(low=1, high=0))
    let (__warp_subexpr_2 : Uint256) = uint256_pedersen(
        Uint256(low=0, high=0), Uint256(low=64, high=0))
    let (__warp_subexpr_1 : Uint256) = sload(__warp_subexpr_2)
    let (expr : Uint256) = uint256_and(__warp_subexpr_1, Uint256(low=255, high=0))
    return (expr)
end

func __warp_if_3{
        bitwise_ptr : BitwiseBuiltin*, memory_dict : DictAccess*, msize,
        pedersen_ptr : HashBuiltin*, range_check_ptr, syscall_ptr : felt*}(
        __warp_subexpr_2 : Uint256, expr : Uint256) -> (expr : Uint256):
    alloc_locals
    if __warp_subexpr_2.low + __warp_subexpr_2.high != 0:
        let (expr : Uint256) = __warp_block_2()
        return (expr)
    else:
        return (expr)
    end
end

func modifier_isAllowed{
        bitwise_ptr : BitwiseBuiltin*, exec_env : ExecutionEnvironment*, memory_dict : DictAccess*,
        msize, pedersen_ptr : HashBuiltin*, range_check_ptr, syscall_ptr : felt*,
        termination_token}(var_wallets_offset : Uint256, var_wallets_length : Uint256) -> ():
    alloc_locals
    let (__warp_subexpr_1 : Uint256) = sload(Uint256(low=0, high=0))
    let (__warp_subexpr_0 : Uint256) = caller()
    let (expr : Uint256) = is_eq(__warp_subexpr_0, __warp_subexpr_1)
    let (__warp_subexpr_2 : Uint256) = is_zero(expr)
    let (expr : Uint256) = __warp_if_3(__warp_subexpr_2, expr)
    let (__warp_subexpr_3 : Uint256) = is_zero(expr)
    if __warp_subexpr_3.low + __warp_subexpr_3.high != 0:
        assert 0 = 1
        jmp rel 0
    end
    let (expr_1 : Uint256) = balance(Uint256(low=0, high=0))
    if termination_token == 1:
        return ()
    end
    let (__warp_subexpr_7 : Uint256) = sload(Uint256(low=2, high=0))
    let (__warp_subexpr_6 : Uint256) = checked_mul_uint256(__warp_subexpr_7, var_wallets_length)
    let (__warp_subexpr_5 : Uint256) = is_lt(expr_1, __warp_subexpr_6)
    let (__warp_subexpr_4 : Uint256) = is_zero(__warp_subexpr_5)
    require_helper_stringliteral_4bba(__warp_subexpr_4)
    let var_i : Uint256 = Uint256(low=0, high=0)
    let (var_i : Uint256) = __warp_loop_3(
        Uint256(low=0, high=0),
        Uint256(low=2, high=0),
        var_i,
        var_wallets_length,
        var_wallets_offset)
    return ()
end

func __warp_if_4(_2 : Uint256, __warp_subexpr_3 : Uint256) -> (_2 : Uint256):
    alloc_locals
    if __warp_subexpr_3.low + __warp_subexpr_3.high != 0:
        let _2 : Uint256 = Uint256(low=2300, high=0)
        return (_2)
    else:
        return (_2)
    end
end

func modifier_isMasterOwner_400{
        bitwise_ptr : BitwiseBuiltin*, exec_env : ExecutionEnvironment*, memory_dict : DictAccess*,
        msize, pedersen_ptr : HashBuiltin*, range_check_ptr, syscall_ptr : felt*,
        termination_token}() -> ():
    alloc_locals
    let (__warp_subexpr_2 : Uint256) = sload(Uint256(low=0, high=0))
    let (__warp_subexpr_1 : Uint256) = caller()
    let (__warp_subexpr_0 : Uint256) = is_eq(__warp_subexpr_1, __warp_subexpr_2)
    require_helper_stringliteral_c7ba(__warp_subexpr_0)
    let (expr : Uint256) = balance(Uint256(low=0, high=0))
    if termination_token == 1:
        return ()
    end
    let _2 : Uint256 = Uint256(low=0, high=0)
    let (__warp_subexpr_3 : Uint256) = is_zero(expr)
    let (_2 : Uint256) = __warp_if_4(_2, __warp_subexpr_3)
    let (__warp_subexpr_6 : Uint256) = caller()
    let (__warp_subexpr_5 : Uint256) = warp_call(
        _2,
        __warp_subexpr_6,
        expr,
        Uint256(low=0, high=0),
        Uint256(low=0, high=0),
        Uint256(low=0, high=0),
        Uint256(low=0, high=0))
    let (__warp_subexpr_4 : Uint256) = is_zero(__warp_subexpr_5)
    if __warp_subexpr_4.low + __warp_subexpr_4.high != 0:
        assert 0 = 1
        jmp rel 0
    end
    let (_3 : Uint256) = uint256_mload(Uint256(low=64, high=0))
    uint256_mstore(offset=_3, value=expr)
    let (__warp_subexpr_8 : Uint256) = timestamp()
    let (__warp_subexpr_7 : Uint256) = u256_add(_3, Uint256(low=32, high=0))
    uint256_mstore(offset=__warp_subexpr_7, value=__warp_subexpr_8)
    let (__warp_subexpr_9 : Uint256) = caller()
    log2(
        _3,
        Uint256(low=64, high=0),
        Uint256(low=321472280472614475666783800382816643293, high=173983944120768536973010240975869965471),
        __warp_subexpr_9)
    return ()
end

func abi_decode_addresst_bool{
        bitwise_ptr : BitwiseBuiltin*, exec_env : ExecutionEnvironment*, range_check_ptr}(
        dataEnd : Uint256) -> (value0 : Uint256, value1 : Uint256):
    alloc_locals
    let (__warp_subexpr_1 : Uint256) = u256_add(
        dataEnd,
        Uint256(low=340282366920938463463374607431768211452, high=340282366920938463463374607431768211455))
    let (__warp_subexpr_0 : Uint256) = slt(__warp_subexpr_1, Uint256(low=64, high=0))
    if __warp_subexpr_0.low + __warp_subexpr_0.high != 0:
        assert 0 = 1
        jmp rel 0
    end
    let (value0 : Uint256) = calldataload(Uint256(low=4, high=0))
    let (value : Uint256) = calldataload(Uint256(low=36, high=0))
    let (__warp_subexpr_5 : Uint256) = is_zero(value)
    let (__warp_subexpr_4 : Uint256) = is_zero(__warp_subexpr_5)
    let (__warp_subexpr_3 : Uint256) = is_eq(value, __warp_subexpr_4)
    let (__warp_subexpr_2 : Uint256) = is_zero(__warp_subexpr_3)
    if __warp_subexpr_2.low + __warp_subexpr_2.high != 0:
        assert 0 = 1
        jmp rel 0
    end
    let value1 : Uint256 = value
    return (value0, value1)
end

func abi_encode_bool_uint256{memory_dict : DictAccess*, msize, range_check_ptr}(
        headStart : Uint256, value0 : Uint256, value1 : Uint256) -> (tail : Uint256):
    alloc_locals
    let (tail : Uint256) = u256_add(headStart, Uint256(low=64, high=0))
    let (__warp_subexpr_1 : Uint256) = is_zero(value0)
    let (__warp_subexpr_0 : Uint256) = is_zero(__warp_subexpr_1)
    uint256_mstore(offset=headStart, value=__warp_subexpr_0)
    let (__warp_subexpr_2 : Uint256) = u256_add(headStart, Uint256(low=32, high=0))
    uint256_mstore(offset=__warp_subexpr_2, value=value1)
    return (tail)
end

func modifier_isMasterOwner_324{
        bitwise_ptr : BitwiseBuiltin*, memory_dict : DictAccess*, msize,
        pedersen_ptr : HashBuiltin*, range_check_ptr, syscall_ptr : felt*}(
        var_caller : Uint256, var_approved : Uint256) -> ():
    alloc_locals
    let (__warp_subexpr_2 : Uint256) = sload(Uint256(low=0, high=0))
    let (__warp_subexpr_1 : Uint256) = caller()
    let (__warp_subexpr_0 : Uint256) = is_eq(__warp_subexpr_1, __warp_subexpr_2)
    require_helper_stringliteral_c7ba(__warp_subexpr_0)
    let (__warp_subexpr_3 : Uint256) = is_zero(var_caller)
    if __warp_subexpr_3.low + __warp_subexpr_3.high != 0:
        assert 0 = 1
        jmp rel 0
    end
    uint256_mstore(offset=Uint256(low=0, high=0), value=var_caller)
    uint256_mstore(offset=Uint256(low=32, high=0), value=Uint256(low=1, high=0))
    let (_1 : Uint256) = uint256_pedersen(Uint256(low=0, high=0), Uint256(low=64, high=0))
    let (__warp_subexpr_4 : Uint256) = sload(_1)
    let (value : Uint256) = uint256_and(
        __warp_subexpr_4,
        Uint256(low=340282366920938463463374607431768211200, high=340282366920938463463374607431768211455))
    let (__warp_subexpr_8 : Uint256) = is_zero(var_approved)
    let (__warp_subexpr_7 : Uint256) = is_zero(__warp_subexpr_8)
    let (__warp_subexpr_6 : Uint256) = uint256_and(__warp_subexpr_7, Uint256(low=255, high=0))
    let (__warp_subexpr_5 : Uint256) = uint256_or(value, __warp_subexpr_6)
    sstore(key=_1, value=__warp_subexpr_5)
    let (_2 : Uint256) = uint256_mload(Uint256(low=64, high=0))
    let (__warp_subexpr_12 : Uint256) = timestamp()
    let (__warp_subexpr_11 : Uint256) = abi_encode_bool_uint256(_2, var_approved, __warp_subexpr_12)
    let (__warp_subexpr_10 : Uint256) = caller()
    let (__warp_subexpr_9 : Uint256) = uint256_sub(__warp_subexpr_11, _2)
    log3(
        _2,
        __warp_subexpr_9,
        Uint256(low=197334318544044161973255708624041810639, high=98759201896163788583687580314193086885),
        __warp_subexpr_10,
        var_caller)
    return ()
end

func modifier_isMasterOwner_297{
        bitwise_ptr : BitwiseBuiltin*, memory_dict : DictAccess*, msize,
        pedersen_ptr : HashBuiltin*, range_check_ptr, syscall_ptr : felt*}(
        var_newBalanceThresholdForReward : Uint256) -> ():
    alloc_locals
    let (__warp_subexpr_2 : Uint256) = sload(Uint256(low=0, high=0))
    let (__warp_subexpr_1 : Uint256) = caller()
    let (__warp_subexpr_0 : Uint256) = is_eq(__warp_subexpr_1, __warp_subexpr_2)
    require_helper_stringliteral_c7ba(__warp_subexpr_0)
    let (_1 : Uint256) = sload(Uint256(low=3, high=0))
    sstore(key=Uint256(low=3, high=0), value=var_newBalanceThresholdForReward)
    let (_2 : Uint256) = uint256_mload(Uint256(low=64, high=0))
    let (__warp_subexpr_6 : Uint256) = timestamp()
    let (__warp_subexpr_5 : Uint256) = abi_encode_uint256_uint256_uint256(
        _2, _1, var_newBalanceThresholdForReward, __warp_subexpr_6)
    let (__warp_subexpr_4 : Uint256) = caller()
    let (__warp_subexpr_3 : Uint256) = uint256_sub(__warp_subexpr_5, _2)
    log2(
        _2,
        __warp_subexpr_3,
        Uint256(low=150756940589245429289839683246483415508, high=187741437610997273860744544177306904774),
        __warp_subexpr_4)
    return ()
end

func modifier_isMasterOwner{
        bitwise_ptr : BitwiseBuiltin*, memory_dict : DictAccess*, msize,
        pedersen_ptr : HashBuiltin*, range_check_ptr, syscall_ptr : felt*}(
        var_newOwner : Uint256) -> ():
    alloc_locals
    let (_1 : Uint256) = sload(Uint256(low=0, high=0))
    let (__warp_subexpr_1 : Uint256) = caller()
    let (__warp_subexpr_0 : Uint256) = is_eq(__warp_subexpr_1, _1)
    require_helper_stringliteral_c7ba(__warp_subexpr_0)
    let (__warp_subexpr_2 : Uint256) = is_zero(var_newOwner)
    if __warp_subexpr_2.low + __warp_subexpr_2.high != 0:
        assert 0 = 1
        jmp rel 0
    end
    sstore(key=Uint256(low=0, high=0), value=var_newOwner)
    let (_2 : Uint256) = uint256_mload(Uint256(low=64, high=0))
    let (__warp_subexpr_3 : Uint256) = timestamp()
    uint256_mstore(offset=_2, value=__warp_subexpr_3)
    log3(
        _2,
        Uint256(low=32, high=0),
        Uint256(low=230669026159494402027822416099169173507, high=242135861350133036116339968414182417480),
        _1,
        var_newOwner)
    return ()
end

func fun{
        bitwise_ptr : BitwiseBuiltin*, memory_dict : DictAccess*, msize, range_check_ptr,
        syscall_ptr : felt*}() -> ():
    alloc_locals
    let (_1 : Uint256) = uint256_mload(Uint256(low=64, high=0))
    uint256_mstore(offset=_1, value=Uint256(low=0, high=0))
    let (__warp_subexpr_1 : Uint256) = timestamp()
    let (__warp_subexpr_0 : Uint256) = u256_add(_1, Uint256(low=32, high=0))
    uint256_mstore(offset=__warp_subexpr_0, value=__warp_subexpr_1)
    let (__warp_subexpr_2 : Uint256) = caller()
    log2(
        _1,
        Uint256(low=64, high=0),
        Uint256(low=106369056379431792383213524942452674320, high=155266492153869684469500224513231734778),
        __warp_subexpr_2)
    return ()
end

func __warp_block_6{
        bitwise_ptr : BitwiseBuiltin*, exec_env : ExecutionEnvironment*, memory_dict : DictAccess*,
        msize, pedersen_ptr : HashBuiltin*, range_check_ptr, syscall_ptr : felt*,
        termination_token}() -> ():
    alloc_locals
    let (__warp_subexpr_1 : Uint256) = calldatasize()
    let (__warp_subexpr_0 : Uint256) = abi_decode_uint256(__warp_subexpr_1)
    modifier_isMasterOwner_265(__warp_subexpr_0)
    let (__warp_subexpr_2 : Uint256) = uint256_mload(Uint256(low=64, high=0))
    warp_return(__warp_subexpr_2, Uint256(low=0, high=0))
    return ()
end

func __warp_block_8{
        bitwise_ptr : BitwiseBuiltin*, exec_env : ExecutionEnvironment*, memory_dict : DictAccess*,
        msize, pedersen_ptr : HashBuiltin*, range_check_ptr, syscall_ptr : felt*,
        termination_token}() -> ():
    alloc_locals
    let (__warp_subexpr_0 : Uint256) = calldatasize()
    abi_decode(__warp_subexpr_0)
    let (ret__warp_mangled : Uint256) = sload(Uint256(low=2, high=0))
    let (memPos : Uint256) = uint256_mload(Uint256(low=64, high=0))
    let (__warp_subexpr_2 : Uint256) = abi_encode_uint256(memPos, ret__warp_mangled)
    let (__warp_subexpr_1 : Uint256) = uint256_sub(__warp_subexpr_2, memPos)
    warp_return(memPos, __warp_subexpr_1)
    return ()
end

func __warp_block_10{
        bitwise_ptr : BitwiseBuiltin*, exec_env : ExecutionEnvironment*, memory_dict : DictAccess*,
        msize, range_check_ptr, termination_token}() -> ():
    alloc_locals
    let (__warp_subexpr_0 : Uint256) = calldatasize()
    abi_decode(__warp_subexpr_0)
    let (
        ret_mpos : Uint256) = copy_literal_to_memory_34cbde018cc85df09c7836603e02c1477be200a8496f18ab8d94c0f076bb70b3(
        )
    let (memPos_1 : Uint256) = uint256_mload(Uint256(low=64, high=0))
    let (__warp_subexpr_2 : Uint256) = abi_encode_string(memPos_1, ret_mpos)
    let (__warp_subexpr_1 : Uint256) = uint256_sub(__warp_subexpr_2, memPos_1)
    warp_return(memPos_1, __warp_subexpr_1)
    return ()
end

func __warp_block_12{
        bitwise_ptr : BitwiseBuiltin*, exec_env : ExecutionEnvironment*, memory_dict : DictAccess*,
        msize, range_check_ptr, termination_token}() -> ():
    alloc_locals
    let (__warp_subexpr_0 : Uint256) = calldatasize()
    abi_decode(__warp_subexpr_0)
    let (
        ret_mpos_1 : Uint256) = copy_literal_to_memory_2a0e4b5b88a71ee6b806854ef01e593c0fa6ef7a48f87d5cebb9d4d229570ed8(
        )
    let (memPos_2 : Uint256) = uint256_mload(Uint256(low=64, high=0))
    let (__warp_subexpr_2 : Uint256) = abi_encode_string(memPos_2, ret_mpos_1)
    let (__warp_subexpr_1 : Uint256) = uint256_sub(__warp_subexpr_2, memPos_2)
    warp_return(memPos_2, __warp_subexpr_1)
    return ()
end

func __warp_block_14{
        bitwise_ptr : BitwiseBuiltin*, exec_env : ExecutionEnvironment*, memory_dict : DictAccess*,
        msize, pedersen_ptr : HashBuiltin*, range_check_ptr, syscall_ptr : felt*,
        termination_token}() -> ():
    alloc_locals
    let (__warp_subexpr_0 : Uint256) = calldatasize()
    abi_decode(__warp_subexpr_0)
    let (ret_1 : Uint256) = sload(Uint256(low=3, high=0))
    let (memPos_3 : Uint256) = uint256_mload(Uint256(low=64, high=0))
    let (__warp_subexpr_2 : Uint256) = abi_encode_uint256(memPos_3, ret_1)
    let (__warp_subexpr_1 : Uint256) = uint256_sub(__warp_subexpr_2, memPos_3)
    warp_return(memPos_3, __warp_subexpr_1)
    return ()
end

func __warp_block_16{
        bitwise_ptr : BitwiseBuiltin*, exec_env : ExecutionEnvironment*, memory_dict : DictAccess*,
        msize, pedersen_ptr : HashBuiltin*, range_check_ptr, syscall_ptr : felt*,
        termination_token}() -> ():
    alloc_locals
    let (__warp_subexpr_1 : Uint256) = calldatasize()
    let (__warp_subexpr_0 : Uint256) = abi_decode_uint256(__warp_subexpr_1)
    let (ret_2 : Uint256) = getter_fun_allowedCallers(__warp_subexpr_0)
    let (memPos_4 : Uint256) = uint256_mload(Uint256(low=64, high=0))
    let (__warp_subexpr_3 : Uint256) = abi_encode_bool(memPos_4, ret_2)
    let (__warp_subexpr_2 : Uint256) = uint256_sub(__warp_subexpr_3, memPos_4)
    warp_return(memPos_4, __warp_subexpr_2)
    return ()
end

func __warp_block_18{
        bitwise_ptr : BitwiseBuiltin*, exec_env : ExecutionEnvironment*, memory_dict : DictAccess*,
        msize, pedersen_ptr : HashBuiltin*, range_check_ptr, syscall_ptr : felt*,
        termination_token}() -> ():
    alloc_locals
    let (__warp_subexpr_0 : Uint256) = calldatasize()
    let (param : Uint256, param_1 : Uint256) = abi_decode_array_address_payable_dyn_calldata(
        __warp_subexpr_0)
    modifier_isAllowed(param, param_1)
    if termination_token == 1:
        return ()
    end
    let (__warp_subexpr_1 : Uint256) = uint256_mload(Uint256(low=64, high=0))
    warp_return(__warp_subexpr_1, Uint256(low=0, high=0))
    return ()
end

func __warp_block_20{
        bitwise_ptr : BitwiseBuiltin*, exec_env : ExecutionEnvironment*, memory_dict : DictAccess*,
        msize, pedersen_ptr : HashBuiltin*, range_check_ptr, syscall_ptr : felt*,
        termination_token}() -> ():
    alloc_locals
    let (__warp_subexpr_0 : Uint256) = calldatasize()
    abi_decode(__warp_subexpr_0)
    modifier_isMasterOwner_400()
    if termination_token == 1:
        return ()
    end
    let (__warp_subexpr_1 : Uint256) = uint256_mload(Uint256(low=64, high=0))
    warp_return(__warp_subexpr_1, Uint256(low=0, high=0))
    return ()
end

func __warp_block_22{
        bitwise_ptr : BitwiseBuiltin*, exec_env : ExecutionEnvironment*, memory_dict : DictAccess*,
        msize, pedersen_ptr : HashBuiltin*, range_check_ptr, syscall_ptr : felt*,
        termination_token}() -> ():
    alloc_locals
    let (__warp_subexpr_0 : Uint256) = calldatasize()
    let (param_2 : Uint256, param_3 : Uint256) = abi_decode_addresst_bool(__warp_subexpr_0)
    modifier_isMasterOwner_324(param_2, param_3)
    let (__warp_subexpr_1 : Uint256) = uint256_mload(Uint256(low=64, high=0))
    warp_return(__warp_subexpr_1, Uint256(low=0, high=0))
    return ()
end

func __warp_block_24{
        bitwise_ptr : BitwiseBuiltin*, exec_env : ExecutionEnvironment*, memory_dict : DictAccess*,
        msize, pedersen_ptr : HashBuiltin*, range_check_ptr, syscall_ptr : felt*,
        termination_token}() -> ():
    alloc_locals
    let (__warp_subexpr_1 : Uint256) = calldatasize()
    let (__warp_subexpr_0 : Uint256) = abi_decode_uint256(__warp_subexpr_1)
    modifier_isMasterOwner_297(__warp_subexpr_0)
    let (__warp_subexpr_2 : Uint256) = uint256_mload(Uint256(low=64, high=0))
    warp_return(__warp_subexpr_2, Uint256(low=0, high=0))
    return ()
end

func __warp_block_26{
        bitwise_ptr : BitwiseBuiltin*, exec_env : ExecutionEnvironment*, memory_dict : DictAccess*,
        msize, pedersen_ptr : HashBuiltin*, range_check_ptr, syscall_ptr : felt*,
        termination_token}() -> ():
    alloc_locals
    let (__warp_subexpr_0 : Uint256) = calldatasize()
    abi_decode(__warp_subexpr_0)
    let (ret_3 : Uint256) = sload(Uint256(low=0, high=0))
    let (memPos_5 : Uint256) = uint256_mload(Uint256(low=64, high=0))
    let (__warp_subexpr_2 : Uint256) = abi_encode_uint256(memPos_5, ret_3)
    let (__warp_subexpr_1 : Uint256) = uint256_sub(__warp_subexpr_2, memPos_5)
    warp_return(memPos_5, __warp_subexpr_1)
    return ()
end

func __warp_block_28{
        bitwise_ptr : BitwiseBuiltin*, exec_env : ExecutionEnvironment*, memory_dict : DictAccess*,
        msize, pedersen_ptr : HashBuiltin*, range_check_ptr, syscall_ptr : felt*,
        termination_token}() -> ():
    alloc_locals
    let (__warp_subexpr_1 : Uint256) = calldatasize()
    let (__warp_subexpr_0 : Uint256) = abi_decode_uint256(__warp_subexpr_1)
    modifier_isMasterOwner(__warp_subexpr_0)
    let (__warp_subexpr_2 : Uint256) = uint256_mload(Uint256(low=64, high=0))
    warp_return(__warp_subexpr_2, Uint256(low=0, high=0))
    return ()
end

func __warp_block_30{
        bitwise_ptr : BitwiseBuiltin*, exec_env : ExecutionEnvironment*, memory_dict : DictAccess*,
        msize, range_check_ptr, termination_token}() -> ():
    alloc_locals
    let (__warp_subexpr_0 : Uint256) = calldatasize()
    abi_decode(__warp_subexpr_0)
    let (
        ret_mpos_2 : Uint256) = copy_literal_to_memory_2a0e4b5b88a71ee6b806854ef01e593c0fa6ef7a48f87d5cebb9d4d229570ed8(
        )
    let (memPos_6 : Uint256) = uint256_mload(Uint256(low=64, high=0))
    let (__warp_subexpr_2 : Uint256) = abi_encode_string(memPos_6, ret_mpos_2)
    let (__warp_subexpr_1 : Uint256) = uint256_sub(__warp_subexpr_2, memPos_6)
    warp_return(memPos_6, __warp_subexpr_1)
    return ()
end

func __warp_block_32{
        bitwise_ptr : BitwiseBuiltin*, exec_env : ExecutionEnvironment*, memory_dict : DictAccess*,
        msize, range_check_ptr, termination_token}() -> ():
    alloc_locals
    let (__warp_subexpr_0 : Uint256) = calldatasize()
    abi_decode(__warp_subexpr_0)
    let (
        ret_mpos_3 : Uint256) = copy_literal_to_memory_34cbde018cc85df09c7836603e02c1477be200a8496f18ab8d94c0f076bb70b3(
        )
    let (memPos_7 : Uint256) = uint256_mload(Uint256(low=64, high=0))
    let (__warp_subexpr_2 : Uint256) = abi_encode_string(memPos_7, ret_mpos_3)
    let (__warp_subexpr_1 : Uint256) = uint256_sub(__warp_subexpr_2, memPos_7)
    warp_return(memPos_7, __warp_subexpr_1)
    return ()
end

func __warp_if_5{
        bitwise_ptr : BitwiseBuiltin*, exec_env : ExecutionEnvironment*, memory_dict : DictAccess*,
        msize, range_check_ptr, termination_token}(__warp_subexpr_0 : Uint256) -> ():
    alloc_locals
    if __warp_subexpr_0.low + __warp_subexpr_0.high != 0:
        __warp_block_32()
        return ()
    else:
        return ()
    end
end

func __warp_block_31{
        bitwise_ptr : BitwiseBuiltin*, exec_env : ExecutionEnvironment*, memory_dict : DictAccess*,
        msize, range_check_ptr, termination_token}(match_var : Uint256) -> ():
    alloc_locals
    let (__warp_subexpr_0 : Uint256) = is_eq(match_var, Uint256(low=4288785780, high=0))
    __warp_if_5(__warp_subexpr_0)
    return ()
end

func __warp_if_6{
        bitwise_ptr : BitwiseBuiltin*, exec_env : ExecutionEnvironment*, memory_dict : DictAccess*,
        msize, range_check_ptr, termination_token}(
        __warp_subexpr_0 : Uint256, match_var : Uint256) -> ():
    alloc_locals
    if __warp_subexpr_0.low + __warp_subexpr_0.high != 0:
        __warp_block_30()
        return ()
    else:
        __warp_block_31(match_var)
        return ()
    end
end

func __warp_block_29{
        bitwise_ptr : BitwiseBuiltin*, exec_env : ExecutionEnvironment*, memory_dict : DictAccess*,
        msize, range_check_ptr, termination_token}(match_var : Uint256) -> ():
    alloc_locals
    let (__warp_subexpr_0 : Uint256) = is_eq(match_var, Uint256(low=4120792933, high=0))
    __warp_if_6(__warp_subexpr_0, match_var)
    return ()
end

func __warp_if_7{
        bitwise_ptr : BitwiseBuiltin*, exec_env : ExecutionEnvironment*, memory_dict : DictAccess*,
        msize, pedersen_ptr : HashBuiltin*, range_check_ptr, syscall_ptr : felt*,
        termination_token}(__warp_subexpr_0 : Uint256, match_var : Uint256) -> ():
    alloc_locals
    if __warp_subexpr_0.low + __warp_subexpr_0.high != 0:
        __warp_block_28()
        return ()
    else:
        __warp_block_29(match_var)
        return ()
    end
end

func __warp_block_27{
        bitwise_ptr : BitwiseBuiltin*, exec_env : ExecutionEnvironment*, memory_dict : DictAccess*,
        msize, pedersen_ptr : HashBuiltin*, range_check_ptr, syscall_ptr : felt*,
        termination_token}(match_var : Uint256) -> ():
    alloc_locals
    let (__warp_subexpr_0 : Uint256) = is_eq(match_var, Uint256(low=4076725131, high=0))
    __warp_if_7(__warp_subexpr_0, match_var)
    return ()
end

func __warp_if_8{
        bitwise_ptr : BitwiseBuiltin*, exec_env : ExecutionEnvironment*, memory_dict : DictAccess*,
        msize, pedersen_ptr : HashBuiltin*, range_check_ptr, syscall_ptr : felt*,
        termination_token}(__warp_subexpr_0 : Uint256, match_var : Uint256) -> ():
    alloc_locals
    if __warp_subexpr_0.low + __warp_subexpr_0.high != 0:
        __warp_block_26()
        return ()
    else:
        __warp_block_27(match_var)
        return ()
    end
end

func __warp_block_25{
        bitwise_ptr : BitwiseBuiltin*, exec_env : ExecutionEnvironment*, memory_dict : DictAccess*,
        msize, pedersen_ptr : HashBuiltin*, range_check_ptr, syscall_ptr : felt*,
        termination_token}(match_var : Uint256) -> ():
    alloc_locals
    let (__warp_subexpr_0 : Uint256) = is_eq(match_var, Uint256(low=3877641597, high=0))
    __warp_if_8(__warp_subexpr_0, match_var)
    return ()
end

func __warp_if_9{
        bitwise_ptr : BitwiseBuiltin*, exec_env : ExecutionEnvironment*, memory_dict : DictAccess*,
        msize, pedersen_ptr : HashBuiltin*, range_check_ptr, syscall_ptr : felt*,
        termination_token}(__warp_subexpr_0 : Uint256, match_var : Uint256) -> ():
    alloc_locals
    if __warp_subexpr_0.low + __warp_subexpr_0.high != 0:
        __warp_block_24()
        return ()
    else:
        __warp_block_25(match_var)
        return ()
    end
end

func __warp_block_23{
        bitwise_ptr : BitwiseBuiltin*, exec_env : ExecutionEnvironment*, memory_dict : DictAccess*,
        msize, pedersen_ptr : HashBuiltin*, range_check_ptr, syscall_ptr : felt*,
        termination_token}(match_var : Uint256) -> ():
    alloc_locals
    let (__warp_subexpr_0 : Uint256) = is_eq(match_var, Uint256(low=3725179599, high=0))
    __warp_if_9(__warp_subexpr_0, match_var)
    return ()
end

func __warp_if_10{
        bitwise_ptr : BitwiseBuiltin*, exec_env : ExecutionEnvironment*, memory_dict : DictAccess*,
        msize, pedersen_ptr : HashBuiltin*, range_check_ptr, syscall_ptr : felt*,
        termination_token}(__warp_subexpr_0 : Uint256, match_var : Uint256) -> ():
    alloc_locals
    if __warp_subexpr_0.low + __warp_subexpr_0.high != 0:
        __warp_block_22()
        return ()
    else:
        __warp_block_23(match_var)
        return ()
    end
end

func __warp_block_21{
        bitwise_ptr : BitwiseBuiltin*, exec_env : ExecutionEnvironment*, memory_dict : DictAccess*,
        msize, pedersen_ptr : HashBuiltin*, range_check_ptr, syscall_ptr : felt*,
        termination_token}(match_var : Uint256) -> ():
    alloc_locals
    let (__warp_subexpr_0 : Uint256) = is_eq(match_var, Uint256(low=2609249910, high=0))
    __warp_if_10(__warp_subexpr_0, match_var)
    return ()
end

func __warp_if_11{
        bitwise_ptr : BitwiseBuiltin*, exec_env : ExecutionEnvironment*, memory_dict : DictAccess*,
        msize, pedersen_ptr : HashBuiltin*, range_check_ptr, syscall_ptr : felt*,
        termination_token}(__warp_subexpr_0 : Uint256, match_var : Uint256) -> ():
    alloc_locals
    if __warp_subexpr_0.low + __warp_subexpr_0.high != 0:
        __warp_block_20()
        return ()
    else:
        __warp_block_21(match_var)
        return ()
    end
end

func __warp_block_19{
        bitwise_ptr : BitwiseBuiltin*, exec_env : ExecutionEnvironment*, memory_dict : DictAccess*,
        msize, pedersen_ptr : HashBuiltin*, range_check_ptr, syscall_ptr : felt*,
        termination_token}(match_var : Uint256) -> ():
    alloc_locals
    let (__warp_subexpr_0 : Uint256) = is_eq(match_var, Uint256(low=2261886623, high=0))
    __warp_if_11(__warp_subexpr_0, match_var)
    return ()
end

func __warp_if_12{
        bitwise_ptr : BitwiseBuiltin*, exec_env : ExecutionEnvironment*, memory_dict : DictAccess*,
        msize, pedersen_ptr : HashBuiltin*, range_check_ptr, syscall_ptr : felt*,
        termination_token}(__warp_subexpr_0 : Uint256, match_var : Uint256) -> ():
    alloc_locals
    if __warp_subexpr_0.low + __warp_subexpr_0.high != 0:
        __warp_block_18()
        return ()
    else:
        __warp_block_19(match_var)
        return ()
    end
end

func __warp_block_17{
        bitwise_ptr : BitwiseBuiltin*, exec_env : ExecutionEnvironment*, memory_dict : DictAccess*,
        msize, pedersen_ptr : HashBuiltin*, range_check_ptr, syscall_ptr : felt*,
        termination_token}(match_var : Uint256) -> ():
    alloc_locals
    let (__warp_subexpr_0 : Uint256) = is_eq(match_var, Uint256(low=2259327152, high=0))
    __warp_if_12(__warp_subexpr_0, match_var)
    return ()
end

func __warp_if_13{
        bitwise_ptr : BitwiseBuiltin*, exec_env : ExecutionEnvironment*, memory_dict : DictAccess*,
        msize, pedersen_ptr : HashBuiltin*, range_check_ptr, syscall_ptr : felt*,
        termination_token}(__warp_subexpr_0 : Uint256, match_var : Uint256) -> ():
    alloc_locals
    if __warp_subexpr_0.low + __warp_subexpr_0.high != 0:
        __warp_block_16()
        return ()
    else:
        __warp_block_17(match_var)
        return ()
    end
end

func __warp_block_15{
        bitwise_ptr : BitwiseBuiltin*, exec_env : ExecutionEnvironment*, memory_dict : DictAccess*,
        msize, pedersen_ptr : HashBuiltin*, range_check_ptr, syscall_ptr : felt*,
        termination_token}(match_var : Uint256) -> ():
    alloc_locals
    let (__warp_subexpr_0 : Uint256) = is_eq(match_var, Uint256(low=2066956628, high=0))
    __warp_if_13(__warp_subexpr_0, match_var)
    return ()
end

func __warp_if_14{
        bitwise_ptr : BitwiseBuiltin*, exec_env : ExecutionEnvironment*, memory_dict : DictAccess*,
        msize, pedersen_ptr : HashBuiltin*, range_check_ptr, syscall_ptr : felt*,
        termination_token}(__warp_subexpr_0 : Uint256, match_var : Uint256) -> ():
    alloc_locals
    if __warp_subexpr_0.low + __warp_subexpr_0.high != 0:
        __warp_block_14()
        return ()
    else:
        __warp_block_15(match_var)
        return ()
    end
end

func __warp_block_13{
        bitwise_ptr : BitwiseBuiltin*, exec_env : ExecutionEnvironment*, memory_dict : DictAccess*,
        msize, pedersen_ptr : HashBuiltin*, range_check_ptr, syscall_ptr : felt*,
        termination_token}(match_var : Uint256) -> ():
    alloc_locals
    let (__warp_subexpr_0 : Uint256) = is_eq(match_var, Uint256(low=2002676000, high=0))
    __warp_if_14(__warp_subexpr_0, match_var)
    return ()
end

func __warp_if_15{
        bitwise_ptr : BitwiseBuiltin*, exec_env : ExecutionEnvironment*, memory_dict : DictAccess*,
        msize, pedersen_ptr : HashBuiltin*, range_check_ptr, syscall_ptr : felt*,
        termination_token}(__warp_subexpr_0 : Uint256, match_var : Uint256) -> ():
    alloc_locals
    if __warp_subexpr_0.low + __warp_subexpr_0.high != 0:
        __warp_block_12()
        return ()
    else:
        __warp_block_13(match_var)
        return ()
    end
end

func __warp_block_11{
        bitwise_ptr : BitwiseBuiltin*, exec_env : ExecutionEnvironment*, memory_dict : DictAccess*,
        msize, pedersen_ptr : HashBuiltin*, range_check_ptr, syscall_ptr : felt*,
        termination_token}(match_var : Uint256) -> ():
    alloc_locals
    let (__warp_subexpr_0 : Uint256) = is_eq(match_var, Uint256(low=1489093785, high=0))
    __warp_if_15(__warp_subexpr_0, match_var)
    return ()
end

func __warp_if_16{
        bitwise_ptr : BitwiseBuiltin*, exec_env : ExecutionEnvironment*, memory_dict : DictAccess*,
        msize, pedersen_ptr : HashBuiltin*, range_check_ptr, syscall_ptr : felt*,
        termination_token}(__warp_subexpr_0 : Uint256, match_var : Uint256) -> ():
    alloc_locals
    if __warp_subexpr_0.low + __warp_subexpr_0.high != 0:
        __warp_block_10()
        return ()
    else:
        __warp_block_11(match_var)
        return ()
    end
end

func __warp_block_9{
        bitwise_ptr : BitwiseBuiltin*, exec_env : ExecutionEnvironment*, memory_dict : DictAccess*,
        msize, pedersen_ptr : HashBuiltin*, range_check_ptr, syscall_ptr : felt*,
        termination_token}(match_var : Uint256) -> ():
    alloc_locals
    let (__warp_subexpr_0 : Uint256) = is_eq(match_var, Uint256(low=1425886544, high=0))
    __warp_if_16(__warp_subexpr_0, match_var)
    return ()
end

func __warp_if_17{
        bitwise_ptr : BitwiseBuiltin*, exec_env : ExecutionEnvironment*, memory_dict : DictAccess*,
        msize, pedersen_ptr : HashBuiltin*, range_check_ptr, syscall_ptr : felt*,
        termination_token}(__warp_subexpr_0 : Uint256, match_var : Uint256) -> ():
    alloc_locals
    if __warp_subexpr_0.low + __warp_subexpr_0.high != 0:
        __warp_block_8()
        return ()
    else:
        __warp_block_9(match_var)
        return ()
    end
end

func __warp_block_7{
        bitwise_ptr : BitwiseBuiltin*, exec_env : ExecutionEnvironment*, memory_dict : DictAccess*,
        msize, pedersen_ptr : HashBuiltin*, range_check_ptr, syscall_ptr : felt*,
        termination_token}(match_var : Uint256) -> ():
    alloc_locals
    let (__warp_subexpr_0 : Uint256) = is_eq(match_var, Uint256(low=1259651138, high=0))
    __warp_if_17(__warp_subexpr_0, match_var)
    return ()
end

func __warp_if_18{
        bitwise_ptr : BitwiseBuiltin*, exec_env : ExecutionEnvironment*, memory_dict : DictAccess*,
        msize, pedersen_ptr : HashBuiltin*, range_check_ptr, syscall_ptr : felt*,
        termination_token}(__warp_subexpr_0 : Uint256, match_var : Uint256) -> ():
    alloc_locals
    if __warp_subexpr_0.low + __warp_subexpr_0.high != 0:
        __warp_block_6()
        return ()
    else:
        __warp_block_7(match_var)
        return ()
    end
end

func __warp_block_5{
        bitwise_ptr : BitwiseBuiltin*, exec_env : ExecutionEnvironment*, memory_dict : DictAccess*,
        msize, pedersen_ptr : HashBuiltin*, range_check_ptr, syscall_ptr : felt*,
        termination_token}(match_var : Uint256) -> ():
    alloc_locals
    let (__warp_subexpr_0 : Uint256) = is_eq(match_var, Uint256(low=365083156, high=0))
    __warp_if_18(__warp_subexpr_0, match_var)
    return ()
end

func __warp_block_4{
        bitwise_ptr : BitwiseBuiltin*, exec_env : ExecutionEnvironment*, memory_dict : DictAccess*,
        msize, pedersen_ptr : HashBuiltin*, range_check_ptr, syscall_ptr : felt*,
        termination_token}() -> ():
    alloc_locals
    let (__warp_subexpr_0 : Uint256) = calldataload(Uint256(low=0, high=0))
    let (match_var : Uint256) = u256_shr(Uint256(low=224, high=0), __warp_subexpr_0)
    __warp_block_5(match_var)
    return ()
end

func __warp_block_3{
        bitwise_ptr : BitwiseBuiltin*, exec_env : ExecutionEnvironment*, memory_dict : DictAccess*,
        msize, pedersen_ptr : HashBuiltin*, range_check_ptr, syscall_ptr : felt*,
        termination_token}() -> ():
    alloc_locals
    __warp_block_4()
    return ()
end

func __warp_if_19{
        bitwise_ptr : BitwiseBuiltin*, exec_env : ExecutionEnvironment*, memory_dict : DictAccess*,
        msize, pedersen_ptr : HashBuiltin*, range_check_ptr, syscall_ptr : felt*,
        termination_token}(__warp_subexpr_1 : Uint256) -> ():
    alloc_locals
    if __warp_subexpr_1.low + __warp_subexpr_1.high != 0:
        __warp_block_3()
        return ()
    else:
        return ()
    end
end

func __warp_if_20{
        bitwise_ptr : BitwiseBuiltin*, exec_env : ExecutionEnvironment*, memory_dict : DictAccess*,
        msize, range_check_ptr, syscall_ptr : felt*, termination_token}(
        __warp_subexpr_4 : Uint256) -> ():
    alloc_locals
    if __warp_subexpr_4.low + __warp_subexpr_4.high != 0:
        fun()
        warp_return(Uint256(0, 0), Uint256(0, 0))
        return ()
    else:
        return ()
    end
end

func __main_meat{
        bitwise_ptr : BitwiseBuiltin*, exec_env : ExecutionEnvironment*, memory_dict : DictAccess*,
        msize, pedersen_ptr : HashBuiltin*, range_check_ptr, syscall_ptr : felt*,
        termination_token}() -> ():
    alloc_locals
    let (__warp_subexpr_0 : Uint256) = __warp_identity_Uint256(Uint256(low=128, high=0))
    uint256_mstore(offset=Uint256(low=64, high=0), value=__warp_subexpr_0)
    let (__warp_subexpr_3 : Uint256) = calldatasize()
    let (__warp_subexpr_2 : Uint256) = is_lt(__warp_subexpr_3, Uint256(low=4, high=0))
    let (__warp_subexpr_1 : Uint256) = is_zero(__warp_subexpr_2)
    __warp_if_19(__warp_subexpr_1)
    if termination_token == 1:
        return ()
    end
    let (__warp_subexpr_5 : Uint256) = calldatasize()
    let (__warp_subexpr_4 : Uint256) = is_zero(__warp_subexpr_5)
    __warp_if_20(__warp_subexpr_4)
    if termination_token == 1:
        return ()
    end
    assert 0 = 1
    jmp rel 0
end
