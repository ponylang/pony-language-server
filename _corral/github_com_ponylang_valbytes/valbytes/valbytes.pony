use "collections" // for getting Hashable

interface val Trimmable[T]
  fun val trim(from: USize, to: USize): Array[T] val

interface CopyToable[T]
  fun copy_to(
    dst: Array[this->T!],
    src_idx: USize,
    dst_idx: USize,
    len: USize)

interface val ReadAsNumerics
  fun read_u8[B: U8 = U8](offset: USize): U8 ?
  fun read_u16[B: U8 = U8](offset: USize): U16 ?
  fun read_u32[B: U8 = U8](offset: USize): U32 ?
  fun read_u64[B: U8 = U8](offset: USize): U64 ?
  fun read_u128[B: U8 = U8](offset: USize): U128 ?

interface val ValBytes is (ReadSeq[U8] & Trimmable[U8] & CopyToable[U8] & ReadAsNumerics)
  """
  Tries to catch both Array[U8] val and ByteArrays in order to define
  ByteArrays as possibly recursive tree structure.
  """

primitive EmptyValBytes is ValBytes
  fun val trim(from: USize, to: USize): Array[U8] val =>
    recover val Array[U8](0) end

  fun copy_to(
    dst: Array[U8],
    src_idx: USize,
    dst_idx: USize,
    len: USize) => None

  fun read_u8[B: U8 = U8](offset: USize): U8 ? => error
  fun read_u16[B: U8 = U8](offset: USize): U16 ? => error
  fun read_u32[B: U8 = U8](offset: USize): U32 ? => error
  fun read_u64[B: U8 = U8](offset: USize): U64 ? => error
  fun read_u128[B: U8 = U8](offset: USize): U128 ? => error

  fun size(): USize => 0
  fun apply(i: USize): U8 ? => error

  fun values(): Iterator[U8] ref^ =>
    object ref is Iterator[U8]
      fun has_next(): Bool => false
      fun next(): U8 ? => error
    end
