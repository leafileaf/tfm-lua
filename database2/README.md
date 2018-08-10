# database2

A project to serialise objects with known structure

by Leafileaf

## IMPORTANT

database2 can decode and encode database1 strings, but encoding to db1 is discouraged

## Example usage

See `test.lua` for test code.

# Documentation

## Schemas

Schemas are a list of datatype instances, in the order to be encoded.

Optionally has a property VERSION indicating the schema's version.

If VERSION is absent and not passed in during encoding, no version information will be encoded.

```lua
schema = {
	VERSION = 1, -- version of the schema
	db2.UnsignedInt{ size = 4 , key = "someint" },
	db2.VarChar{ size = 127 , key = "somestring" },
	-- etc...
}
```

## Datatypes

Datatypes represent different methods to encode different *data types*.

Each type of data has a custom encoding method (floats are handled differently than integers, for example).

All Datatype instances possess the following properties and methods:

### Properties

#### `dt.basetype`

This is the constructor function used to create the datatype.

You can do equality testing with this (`dt.basetype == db2.Float`)

### Methods

#### `dt:encode( data , bpb )`

Attempts to encode the provided data into the form specified by this datatype instance.

*Internal function - it should be unnecessary to call this yourself.*

- `any data` Data to be encoded.
- `integer bpb` Number of bits per byte. Either 7 or 8.
- *returns* `string` Encoded data.
- *errors* If data is invalid.

#### `dt:decode( enc , ptr , bpb )`

Attempts to decode the encoded string according to the form specified by this datatype instance.

*Internal function - it should be unnecessary to call this yourself.*

- `string enc` String containing the encoded data.
- `integer ptr` Index of the string where the encoded data for this datatype can be found.
- `integer bpb` Number of bits per byte. Either 7 or 8.
- *returns* `any` Decoded data.
- *returns* `integer` Index after this datatype's data chunk.

### Parameters

All Datatype constructors accept the following parameters:

#### `key = any key`

Indicates the data for this datatype can be found at key `key`.

Optional if and only if passing this instance as a parameter to `db2.VarDataList` or `db2.FixedDataList`.

Otherwise, an unclean error will be thrown on encode/decode attempt.

### List of Datatypes

#### `db2.UnsignedInt{ size = n }`

Creates an `UnsignedInt` datatype.

Can process unsigned integers from `0` to `(2^bpb)^n`.

*Uses `n` bytes.*

- `integer size` Number of bytes to use.
- *returns* `UnsignedInt` The UnsignedInt instance constructed.

#### `db2.Float{}`

Creates a `Float` datatype.

Can process floating-point numbers.

When `bpb` is 8, uses IEEE754 single-precision format (8-bit exponent, 23-bit significand)

When `bpb` is 7, uses a 7-bit exponent and 20-bit significand.

*Uses 4 bytes.*

- *returns* `Float` The Float instance constructed.

#### `db2.Double{}`
Creates a `Double` datatype.

Can process floating-point numbers.

When `bpb` is 8, uses IEEE754 double-precision format (11-bit exponent, 52-bit significand)

When `bpb` is 7, uses a 10-bit exponent and 45-bit significand.

*Uses 8 bytes.*

- *returns* `Double` The Double instance constructed.

#### `db2.VarChar{ size = n }`

Creates a `VarChar` datatype.

Can process strings of up to length `n`.

*Uses `x+len(data)` bytes,* where *`x`* is the minimum number of bytes required to encode the number `n`.

- `integer size` Maximum length of string that can be processed.
- *returns* `VarChar` The VarChar instance constructed.

#### `db2.FixedChar{ size = n }`
Creates a `FixedChar` datatype.

Can process strings of exactly length `n`.

Shorter strings will be automatically right-padded with `\x00`.

*Uses `n` bytes.*

- `integer size` Length of string that can be processed.
- *returns* `FixedChar` The FixedChar instance constructed.

#### `db2.Bitset{ size = n }`

Creates a `Bitset` datatype.

Can process an array of exactly `n` boolean values.

Smaller arrays will be automatically back-padded with `false`.

*Uses `ceil(n/bpb)` bytes.*

- `integer size` Number of boolean values that can be processed.
- *returns* `Bitset` The Bitset instance constructed.

#### `db2.VarBitset{ size = n }`

Creates a `VarBitset` datatype.

Can process an array of up to `n` boolean values.

*Uses `x+ceil(len(data)/bpb)` bytes,* where *`x`* is the minimum number of bytes required to encode the number `n`.

- `integer size` Maximum number of boolean values that can be processed.
- *returns* `VarBitset` The VarBitset instance constructed.

#### `db2.VarDataList{ size = n , datatype = d }`

Creates a `VarDataList` datatype.

Can process an array of up to `n` data processable by `d`.

*Uses `x+y` bytes,* where *`x`* is the minimum number of bytes required to encode the number `n`, and *`y`* is the sum of bytes used to encode every datum in the list.

- `integer size` Maximum number of data that can be processed.
- `Datatype datatype` Datatype capable of processing data in list.
- *returns* `VarDataList` The VarDataList instance constructed.

#### `db2.FixedDataList{ size = n , datatype = d }`

Creates a `FixedDataList` datatype.

Can process an array of exactly `n` data processable by `d`.

*Uses `y` bytes,* where *`y`* is the sum of bytes used to encode every datum in the list.

- `integer size` Number of data that can be processed.
- `Datatype datatype` Datatype capable of processing data in list.
- *returns* `FixedDataList` The FixedDataList instance constructed.
- *errors* If input data list is not exactly length `n`.

#### `db2.VarObjectList{ size = n , schema = s }`

Creates a `VarObjectList` datatype.

Can process an array of up to `n` objects, each of which has structure defined by `s`.

*Uses `x+y` bytes,* where *`x`* is the minimum number of bytes required to encode the number `n`, and *`y`* is the sum of bytes used to encode every object in the list.

- `integer size` Maximum number of objects that can be processed.
- `Schema schema` Schema defining the structure of objects in list.
- *returns* `VarObjectList` The VarObjectList instance constructed.

#### `db2.FixedObjectList{ size = n , schema = s }`

Creates a `FixedObjectList` datatype.

Can process an array of exactly `n` objects, each of which has structure defined by `s`.

*Uses `y` bytes,* where *`y`* is the sum of bytes used to encode every object in the list.

- `integer size` Number of data that can be processed.
- `Schema schema` Schema defining the structure of objects in list.
- *returns* `FixedObjectList` The FixedObjectList instance constructed.
- *errors* If input object list is not exactly length `n`.

#### `db2.SwitchObject{ typekey = tk , typedt = tdt , schemamap = sm }`

Creates a `SwitchObject` datatype.

A versatile datatype that can utilise different processing methods depending on the value of a property.

The value found in `tk` is used to find a schema in `sm`, which is then used to process the object.

See `test.lua` for example usage.

*Uses `y+z` bytes,* where *`y`* is the number of bytes required to encode the value in `tk` according to `tdt`, and *`z`* is the number of bytes required to encode the object according to the corresponding schema.

- `any typekey` Key where the switch value can be found.
- `Datatype typedt` Datatype capable of processing the value in `tk`.
- `table< any , Schema > schemamap` Map of `tk` value to schema used.
- *returns* `SwitchObject` The SwitchObject instance constructed.
- *errors* If `typekey` value cannot be found in the input object, or `schemamap` does not have a schema corresponding to `typekey` value.

## Methods

#### `db2.Datatype{ init = initf , encode = encodef , decode = decodef }`

Creates a new `Datatype` constructor.

*Internal function - it should be unnecessary to call this yourself.*

- `function init( inst , params ) -> nil` Initialisation function of the Datatype instance.
- `function encode( inst , data , bpb ) -> string` Encoding function of the Datatype instance.
- `function decode( inst , enc , ptr , bpb ) -> any , integer` Decoding function of the Datatype instance.
- *returns* `DatatypeConstructor` The Datatype constructor created.
- *errors* If invalid parameters are provided.

#### `db2.encode( schema , data , params )`

Encodes `data` following `schema`.

Optionally applies `params` to encoding.

- `Schema schema` Schema to be followed when encoding data.
- `table data` Data to be encoded.
- `table< string , any > params` Optional parameters to be applied.
- *returns* `string` The encoded string.
- *errors* If parameter `USE_SCHEMALIST` is set to `true`.

#### `db2.decode( schemalist , encoded , params )`

Decodes `encoded` according to `schemalist`.

Optionally applies `params` to decoding.

If `encoded` has a settings byte, parameters `USE_MAGIC`, `USE_EIGHTBIT` will be overridden.

- `table< integer , Schema > schemalist` Map of version to schema.
- `Schema schemalist` Schema to be followed when decoding data. This definition is only used if there is no versioning and `USE_SCHEMALIST` is not `true`.
- `string encoded` String to be decoded.
- `table< string , any > params` Optional parameters to be applied.
- *returns* `string` The decoded data.
- *errors* If settings byte is invalid while `USE_SETTINGS` is not `false`.
- *errors* If magic number testing fails while `USE_MAGIC` is not `false`.
- *errors* If `schemalist` does not have a schema corresponding to the version number.
- *errors* If end of string reached while parsing.
- *errors* If end of schema reached while parsing.

#### `db2.test( encoded , params )`

Tests if `encoded` is a valid db2 string, optionally applying `params`.

Tests the validity of the settings byte and magic number.

- `string encoded` String to be tested.
- `table< string , any > params` Optional parameters to be applied.
- *returns* `boolean` Is `encoded` a valid db2 string?

#### `db2.errorfunc( fn )`

Instead of throwing errors, db2 will now call `fn` if an error is encountered.

- `function fn( message ) -> nil` The new error function.

#### `db2.bytestonumber( bytes , bpb )`

Converts `bytes` to an integer using `bpb` bits per byte.

Uses little-endian encoding.

*Internal function - it should be unnecessary to call this yourself.*

- `string bytes` Bytes to be converted.
- `integer bpb` Number of bits per byte. Either 7 or 8.
- *returns* `integer` Converted integer.

#### `db2.numbertobytes( num , bpb , len )`

Converts `num` to a string of length `len` using `bpb` bits per byte.

If `num` is too big, only processes lower-order bits.

Uses little-endian encoding.

*Internal function - it should be unnecessary to call this yourself.*

- `integer num` Number to be converted.
- `integer bpb` Number of bits per byte. Either 7 or 8.
- `integer len` Expected length of string.
- *returns* `string` Converted bytes.

#### *deprecated* `db2.lbtn( bytes , bpb )`

Converts `bytes` to an integer using `bpb` bits per byte.

Legacy function for decoding db1 strings.

Uses big-endian encoding.

*Internal function - it should be unnecessary to call this yourself.*

- `string bytes` Bytes to be converted.
- `integer bpb` Number of bits per byte. Either 7 or 8.
- *returns* `integer` Converted integer.

#### *deprecated* `db2.lntb( num , bpb , expected_length )`

Converts `num` to a string of length `expected_length` using `bpb` bits per byte.

Legacy function for encoding db1 strings.

Uses big-endian encoding.

**WARNING**: Unsafe; has overflow bug. Output may be bigger than `expected_length` if `num` is too large.

Encoding in legacy mode is strongly discouraged.

*Internal function - it should be unnecessary to call this yourself.*

- `integer num` Number to be converted.
- `integer bpb` Number of bits per byte. Either 7 or 8.
- `integer expected_length` Expected length of string.
- *returns* `string` Converted bytes.

## Encode/decode parameters

The following parameters can be passed to `db2.encode` or `db2.decode`.

- `boolean USE_SETTINGS` Default `true`. Encode a settings byte into the string?
- `boolean USE_MAGIC` Default `true`. Encode a magic number into the string?
- `boolean USE_EIGHTBIT` Default `false`. Use eight-bit-per-byte encoding?
- `integer USE_VERSION` Default `nil`. Force a specific number of version bytes. If `nil`, scales dynamically.
- `boolean USE_LEGACY` Default `false`. Whether to use legacy mode encoding/decoding.
- `boolean USE_SCHEMALIST` Default `false`. Never treat `schemalist` as a single schema in `db2.decode` even if no versioning is done. Throws an error when used with `db2.encode`.
- `integer VERSION` Default `nil`. Override the version number (if any) found in `schema.VERSION` while encoding. No effect when used with `db2.decode`.

## Additional data format information

All `Var*` datatypes store an integer at the front of their allotted block indicating the number of elements to read, followed by the actual data.

All `Fixed*` datatypes, `Bitset`, `Float`, `Double`, and `UnsignedInt` store data directly.

The data format header is as follows.

- 1 settings byte (can be turned off)
- 2 magic number bytes (can be turned off)
- 0-7 version bytes

### Settings byte

Bits 0-2 represents the length of the version field in the header.

Bit 3 is always set.

Bit 4 is set if magic number is enabled.

Bit 5 is always set.

Bit 6 is reserved for future usage.

Bit 7 is set if using 8-bit-per-byte encoding. (Can't be set on 7-bpb anyway.)

### Magic number bytes

This is the number 9224 in little-endian.

Additionally, bit 15 (highest-order bit) is set if using 8-bpb encoding.

### Version bytes

This is the version number of the encoded data in little-endian.

The length of this field is in the settings byte or must be provided via USE_VERSION if missing.

## Creating your own datatypes

The existing datatypes provided in db2 can be used for a wide variety of applications.

If you need a specialised datatype, continue reading.

You may use the inbuilt `db2.Datatype` function to create your own datatypes easily. See the following for an example.

```lua
TimeField = db2.Datatype{
	init = function( dt , params )
		dt.__timef = params.timefunction
		dt.__len = params.size
	end,
	encode = function( dt , data , bpb )
		-- encode the current time, regardless of the value from the key
		return db2.numbertobytes( dt.__timef() , bpb , dt.__len )
	end,
	decode = function( dt , enc , ptr , bpb )
		-- decode the encoded time and return it
		-- also remember to return the new ptr, since it's passed to the next Datatype in line
		return db2.bytestonumber( enc:sub(ptr,ptr+dt.__len-1) , bpb ) , ptr + dt.__len
	end
}
```

`init` is a function called when creating a new instance of the datatype. By calling `TimeField{ timefunction = os.time , size = 6 }`, the parameters given can be found in `params`.

`encode` is called when trying to get the encoded string for a given data value.

`decode` is called when trying to get the decoded value for a given string (at index `ptr`).

If you should choose not to use the inbuilt `db2.Datatype` function, any table containing `encode`, `decode`, and a `basetype` field can be recognised as a datatype instance when used in a schema (where `encode` and `decode` are as defined above).