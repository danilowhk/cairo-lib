use result::ResultTrait;
use option::OptionTrait;
use array::{Array, ArrayTrait, Span, SpanTrait};
use clone::Clone;
use traits::{Into, TryInto};
use cairo_lib::utils::types::bytes::{Bytes, BytesTryIntoU256};
use cairo_lib::utils::types::byte::Byte;
use debug::PrintTrait;

// @notice Enum with all possible RLP types
#[derive(Drop, PartialEq)]
enum RLPType {
    String: (),
    StringShort: (),
    StringLong: (),
    ListShort: (),
    ListLong: (),
}

#[generate_trait]
impl RLPTypeImpl of RLPTypeTrait {
    // @notice Returns RLPType from the leading byte
    // @param byte Leading byte
    // @return Result with RLPType
    fn from_byte(byte: Byte) -> Result<RLPType, felt252> {
        if byte <= 0x7f {
            Result::Ok(RLPType::String(()))
        } else if byte <= 0xb7 {
            Result::Ok(RLPType::StringShort(()))
        } else if byte <= 0xbf {
            Result::Ok(RLPType::StringLong(()))
        } else if byte <= 0xf7 {
            Result::Ok(RLPType::ListShort(()))
        } else if byte <= 0xff {
            Result::Ok(RLPType::ListLong(()))
        } else {
            Result::Err('Invalid byte')
        }
    }
}

// @notice Represent a RLP item
#[derive(Drop)]
enum RLPItem {
    Bytes: Bytes,
    // Should be Span<RLPItem> to allow for any depth/recursion, not yet supported by the compiler
    List: Span<Bytes>
}

// @notice RLP decodes a rlp encoded byte array
// @param input RLP encoded bytes
// @return Result with RLPItem and size of the decoded item
fn rlp_decode(input: Bytes) -> Result<(RLPItem, usize), felt252> {
    let prefix = *input.at(0);

    // Unwrap is impossible to panic here
    let rlp_type = RLPTypeTrait::from_byte(prefix).unwrap();
    match rlp_type {
        RLPType::String(()) => {
            let mut arr = array![prefix];
            Result::Ok((RLPItem::Bytes(arr.span()), 1))
        },
        RLPType::StringShort(()) => {
            let len = prefix.into() - 0x80;
            let res = input.slice(1, len);

            Result::Ok((RLPItem::Bytes(res), 1 + len))
        },
        RLPType::StringLong(()) => {
            let len_len = prefix.into() - 0xb7;
            let len_span = input.slice(1, len_len);

            // Bytes => u256 => u32
            let len: u32 = len_span.try_into().unwrap().try_into().unwrap();
            let res = input.slice(1 + len_len, len);

            Result::Ok((RLPItem::Bytes(res), 1 + len_len + len))
        },
        RLPType::ListShort(()) => {
            let len = prefix.into() - 0xc0;
            let mut in = input.slice(1, len);
            let res = rlp_decode_list(ref in);
            Result::Ok((RLPItem::List(res), 1 + len))
        },
        RLPType::ListLong(()) => {
            let len_len = prefix.into() - 0xf7;
            let len_span = input.slice(1, len_len);

            // Bytes => u256 => u32
            let len: u32 = len_span.try_into().unwrap().try_into().unwrap();
            let mut in = input.slice(1 + len_len, len);
            let res = rlp_decode_list(ref in);
            Result::Ok((RLPItem::List(res), 1 + len_len + len))
        }
    }
}

fn rlp_decode_list(ref input: Bytes) -> Span<Bytes> {
    let mut i = 0;
    let len = input.len();
    let mut output = ArrayTrait::new();

    loop {
        if i >= len {
            break ();
        }

        let (decoded, decoded_len) = rlp_decode(input).unwrap();
        match decoded {
            RLPItem::Bytes(b) => {
                output.append(b);
                input = input.slice(decoded_len, input.len() - decoded_len);
            },
            RLPItem::List(_) => {
                panic_with_felt252('Recursive list not supported');
            }
        }
        i += decoded_len;
    };
    output.span()
}

fn rlp_encode_byte_array(data: Array,ref output: Array) -> Bytes {
    let data_len = data.len();

    if data_len < 56 {
        output.append(0x80 + data_len);
        let data_copy = data.slice(0, data_len);
        output.append(data_copy);
    } else {
        //TODO: Convert data length to bytes
        let bytes_data_copy = 0;
        let data_copy = data.slice(0, data_len);

        //TODO: use the length of the length in bytes to add to append
        output.append(0x80 + bytes_data_copy.len());
        output.append(bytes_data_copy);
        output.append(data_copy);        
    }
}


fn rlp_encode_list(data: Array) -> Bytes {
    let data_len = data.len();
    let mut output = ArrayTrait::new();
    // In RLP encoding, if the list length is less than 55, the length can be 
    // directly added to 0xC0 to form the first byte of the encoded output.
    // This compactly encodes both the fact that this is a list and its length.
    if data_len < 56 {
        output.append(0xc0 + data_len);
        let data_copy = data.slice(0, data_len);
        output.append(data_copy);
    // In RLP encoding, if the list length is greater than 55, the length itself
    // needs to be encoded as a byte array(this byte array is the lenght of the list). The first byte is then formed by adding
    // the length of this byte array to 0xF7. This allows for lists of arbitrary
    // length to be encoded.
    } else {
        //TODO: Convert data length to bytes
        let bytes_data_copy = 0;
        let data_copy = data.slice(0, data_len);

        //TODO: use the length of the length in bytes to add to append
        output.append(0xf7 + bytes_data_copy.len());
        output.append(bytes_data_copy);
        output.append(data_copy);
    }

    return output;
}

fn rlp_encode_felt(input_data: felt252, ref rlp_array: Array) {
    if input_data == 0 {
        rlp_array.append(0x80);
    } else if input_data < 127 {
        rlp_array.append(input_data);
    } else {
        // TODO: Implement split_felt
        let (high, low) = split_felt(input_data);
        // TODO: transform the new uint256 into ByteArray / Bytes
        let data_copy : Array = convert_uint256_into_byte_array(high, low);
        rlp_encode_byte_array(data_copy, rlp_array);

    }
}


impl RLPItemPartialEq of PartialEq<RLPItem> {
    fn eq(lhs: @RLPItem, rhs: @RLPItem) -> bool {
        match lhs {
            RLPItem::Bytes(b) => {
                match rhs {
                    RLPItem::Bytes(b2) => {
                        b == b2
                    },
                    RLPItem::List(_) => false
                }
            },
            RLPItem::List(l) => {
                match rhs {
                    RLPItem::Bytes(_) => false,
                    RLPItem::List(l2) => {
                        let len_l = (*l).len();
                        if len_l != (*l2).len() {
                            return false;
                        }
                        let mut i: usize = 0;
                        loop {
                            if i >= len_l {
                                break true;
                            }
                            if (*l).at(i) != (*l2).at(i) {
                                break false;
                            }
                            i += 1;
                        }
                    }
                }
            }
        }
    }

    fn ne(lhs: @RLPItem, rhs: @RLPItem) -> bool {
        // TODO optimize
        !(lhs == rhs)
    }
}

