use cairo_lib::utils::types::bytes::{Bytes, BytesTryIntoU256};
use array::ArrayTrait;
use traits::{TryInto};
use option::OptionTrait;

fn helper_test_bytes_try_into_u256(bytes: Bytes, expected: u256) {
    let res: Option<u256> = bytes.try_into();
    assert(res.is_some(), 'Conversion failed');
    assert(res.unwrap() == expected, 'Conversion wrong value');
}

#[test]
#[available_gas(999999999)]
fn test_bytes_try_into_u256() {
    let mut arr = ArrayTrait::new();
    // Empty
    helper_test_bytes_try_into_u256(arr.span(), 0);

    arr.append(1);
    helper_test_bytes_try_into_u256(arr.span(), 1);

    arr.append(0);
    helper_test_bytes_try_into_u256(arr.span(), 256);

    arr.append(0);
    helper_test_bytes_try_into_u256(arr.span(), 65536);

    arr.append(0);
    helper_test_bytes_try_into_u256(arr.span(), 16777216);

    let mut arr = ArrayTrait::new();
    let mut i: usize = 0;
    loop {
        if i == 32 {
            break ();
        }
        arr.append(255);
        i += 1;
    };
    // Max value
    helper_test_bytes_try_into_u256(
        arr.span(), 115792089237316195423570985008687907853269984665640564039457584007913129639935
    );

    let mut arr = array![1, 2, 3, 4, 5, 6];
    helper_test_bytes_try_into_u256(arr.span(), 1108152157446);
}
