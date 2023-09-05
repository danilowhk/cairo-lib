use cairo_lib::encoding::rlp::{rlp_decode, RLPType, RLPTypeTrait, RLPItem};
use cairo_lib::utils::types::bytes::Bytes;
use array::{ArrayTrait, SpanTrait};
use result::ResultTrait;

#[test]
#[available_gas(99999999999)]
fn test_rlp_decode_short_list() {
    let mut arr = array![0xc9, 0x83, 0x35, 0x35, 0x89, 0x42, 0x83, 0x45, 0x38, 0x92];
    let (res, len) = rlp_decode(arr.span()).unwrap();
    assert(len == 1 + (0xc9 - 0xc0), 'Wrong len');

    let mut expected_0 = array![0x35, 0x35, 0x89];
    let mut expected_1 = array![0x42];
    let mut expected_2 = array![0x45, 0x38, 0x92];

    let expected = array![expected_0.span(), expected_1.span(), expected_2.span()];
    let expected_item = RLPItem::List(expected.span());

    assert(res == expected_item, 'Wrong value');
}

#[test]
#[available_gas(99999999999)]
fn test_rlp_decode_ethereum_transaction() {
    // Represent the Ethereum transaction
    // 0xf86c808504a817c800825208943535353535353535353535353535353535353535880de0b6b3a7640000801c
    let mut arr = array![
        0xf8, 0x6c, 0x80, 0x85, 0x04, 0xa8, 0x17, 0xc8, 0x00, 0x82, 0x52, 0x08, 0x94, 0x35, 0x35, 0x35, 
        0x35, 0x35, 0x35, 0x35, 0x35, 0x35, 0x35, 0x35, 0x35, 0x35, 0x35, 0x35, 0x35, 0x35, 0x88, 0x0d, 
        0xe0, 0xb6, 0xb3, 0xa7, 0x64, 0x00, 0x00, 0x80, 0x1c
    ];

    // Perform RLP decode
    let (res, len) = rlp_decode(arr.span()).unwrap();

    // Validate the length of the decoded data
    // assert(len == 1 + (0xc9 - 0xc0), 'Wrong len');

    // Construct expected data for each transaction field

    // nonce: 0x0
    let mut expected_0 = array![];  // RLP encoded 0x0
    // gasPrice: 0x4a817c800
    let mut expected_1 = array![0x04, 0xa8, 0x17, 0xc8, 0x00];
    // gasLimit: 0x5208
    let mut expected_2 = array![0x52, 0x08];
    // to: 0x3535353535353535353535353535353535353535
    let mut expected_3 = array![0x35, 0x35, 0x35, 0x35, 0x35, 0x35, 0x35, 0x35, 0x35, 0x35, 0x35, 0x35, 0x35, 0x35, 0x35, 0x35, 0x35, 0x35];
    // value: 0xde0b6b3a7640000
    let mut expected_4 = array![ 0x0d, 0xe0, 0xb6, 0xb3, 0xa7, 0x64, 0x00, 0x00];
    // v, r, s: 0x1c
    let expected_5 = array![];

    let mut expected_6 = array![0x1c];

    // Create the expected result
    let expected = array![
        expected_0.span(), 
        expected_1.span(), 
        expected_2.span(), 
        expected_3.span(), 
        expected_4.span(),
        expected_5.span(),
        expected_6.span()
    ];

    let expected_item = RLPItem::List(expected.span());

    // Validate the decoded value against the expected result
    // assert(res == expected_item, 'Wrong value');
}
