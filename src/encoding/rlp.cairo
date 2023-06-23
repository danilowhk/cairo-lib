use result::ResultTrait;
use array::{Array, ArrayTrait, Span, SpanTrait};
use clone::Clone;
use traits::Into;
use cairo_lib::utils::types::{Bytes, BytesPartialEq};

#[derive(Drop, PartialEq)]
enum RLPType {
    String: (),
    StringShort: (),
    StringLong: (),
    ListShort: (),
    ListLong: (),
}

trait RLPTypeTrait {
    fn from_byte(byte: u8) -> Result<RLPType, felt252>;
}

impl RLPTypeImpl of RLPTypeTrait {
    fn from_byte(byte: u8) -> Result<RLPType, felt252> {
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

#[derive(Drop)]
enum RLPItem {
    Bytes: Bytes,
    // Should be Array<RLPItem> to allow for any depth , but compiler panic
    List: Array<Bytes>
}

//trait RLPItemTrait {
    //fn len(self: @RLPItem) -> usize;
//}

//impl RLPItemImpl of RLPItemTrait {
    //fn len(self: @RLPItem) -> usize {
        //match self {
            //RLPItem::Bytes(b) => {
                //if b.len() == 1 {
                    //if *b.at(0) <= 23 {
                        //1
                    //} else {
                        //// TODO handle b.len() > 55
                        //1 + b.len()
                    //}
                //} else {
                    //1 + b.len()
                //}
            //},
            //RLPItem::List(l) => {
                //let mut payload_len = 0;
                //let mut i: usize = 0;
                //loop {
                    //if i >= l.len() {
                        //break ();
                    //}
                    //let item = RLPItem::Bytes(l.at(i).clone());
                    //payload_len += item.len();
                //};

                //1 + payload_len
                //// TODO handle payload_len > 55
            //}
        //}
    //}
//}

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
                        let len_l = l.len();
                        if len_l != l2.len() {
                            return false;
                        }
                        let mut i: usize = 0;
                        loop {
                            if i >= len_l {
                                break true;
                            }
                            if l.at(i) != l2.at(i) {
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

fn rlp_decode(input: Span<u8>) -> Result<Array<RLPItem>, felt252> {
    let mut i: usize = 0;
    let mut output = ArrayTrait::new();

    loop {
        if i >= input.len() {
            break ();
        }
        let prefix = *input.at(i);
        i += 1;

        // Unwrap is impossible to panic here
        let rlp_type = RLPTypeTrait::from_byte(prefix).unwrap();
        let item = match rlp_type {
            RLPType::String(()) => {
                let mut arr = ArrayTrait::new();
                arr.append(prefix);
                RLPItem::Bytes(arr.span())
            },
            RLPType::StringShort(()) => RLPItem::Bytes(ArrayTrait::new().span()),
            RLPType::StringLong(()) => RLPItem::Bytes(ArrayTrait::new().span()),
            RLPType::ListShort(()) => RLPItem::Bytes(ArrayTrait::new().span()),
            RLPType::ListLong(()) => RLPItem::Bytes(ArrayTrait::new().span()),
            //RLPType::StringShort(()) => {
                //let len = prefix - 0x80;
                //let mut j: usize = i;
                //let mut arr = ArrayTrait::new();
                //loop {
                    //if j >= i + len.into() {
                        //break ();
                    //}

                    //arr.append(*input[j]);
                    //j += 1;
                //};

                //i += len.into();
                //RLPItem::Bytes(arr)
            //},
            //RLPType::StringLong(()) => {
                //let len_len = prefix - 0xb7;
                //let mut j: usize = i;
                //let mut len_arr = ArrayTrait::new();
                //loop {
                    //if j >= i + len_len.into() {
                        //break ();
                    //}

                    //len_arr.append(*input[j]);
                    //j += 1;
                //};

                //// TODO let len = len_arr.into() -> Implement Array<u8> to usize
                //let len = 0;
                //i += len_len.into();

                //let mut arr = ArrayTrait::new(); 
                //j = i;
                //loop {
                    //if j >= i + len {
                        //break ();
                    //}

                    //arr.append(*input[j]);
                    //j += 1;
                //};

                //i += len.into();
                //RLPItem::Bytes(arr)
            //},
            //RLPType::ListShort(()) => {
                //let len = prefix - 0xc0;
                //let mut j: usize = i;
                //let mut arr = ArrayTrait::new();
                //loop {
                    //if j >= i + len.into() {
                        //break ();
                    //}

                    //arr.append(*input[j]);
                    //j += 1;
                //};

                //i += len.into();

                //let mut span = arr.span();
                //// TODO replace unwrap
                //let decoded_list = rlp_decode_list(ref span).unwrap();
                //RLPItem::List(decoded_list)
            //},
            //RLPType::ListLong(()) => {
                //let len_len = prefix - 0xf7;
                //let mut j: usize = i;
                //let mut len_arr = ArrayTrait::new();
                //loop {
                    //if j >= i + len_len.into() {
                        //break ();
                    //}

                    //len_arr.append(*input[j]);
                    //j += 1;
                //};

                //// TODO let len = len_arr.into() -> Implement Array<u8> to usize
                //let len = 0;
                //i += len_len.into();

                //let mut arr = ArrayTrait::new(); 
                //j = i;
                //loop {
                    //if j >= i + len {
                        //break ();
                    //}

                    //arr.append(*input[j]);
                    //j += 1;
                //};

                //i += len.into();

                //let mut span = arr.span();
                //// TODO replace unwrap
                //let decoded_list = rlp_decode_list(ref span).unwrap();
                //RLPItem::List(decoded_list)
            //}
        };
        output.append(item);
    };

    Result::Ok(output)
}

 //fn rlp_decode_list(ref input: Span<u8>) -> Result<Array<Array<u8>>, felt252> {
    //let mut i = 0;
    //let mut output = ArrayTrait::new();

    //loop {
        //if i >= input.len() {
            //break Result::Ok(output.clone());
        //}
        //let mut j = i;
        //loop {
            //if j == 0 {
                //break ();
            //}

            //input.pop_back();
            //j -= 1;
        //};

        //// TODO replace unwrap
        //let items = rlp_decode(input).unwrap();
        //if items.len() > 1 {
            //break Result::Err('Recursive arrays not supported');
        //}
        //let item = items.at(0);
        //i += item.len();

        //match item {
            //RLPItem::Bytes(b) => {
                //output.append(b.clone());
            //},
            //RLPItem::List(_) => {
                //break Result::Err('Recursive arrays not supported');
            //}
        //};
    //}
//}
