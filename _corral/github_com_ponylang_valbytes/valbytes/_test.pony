use "pony_test"
use "pony_check"
use "debug"

actor \nodoc\ Main is TestList
  new create(env: Env) =>
    PonyTest(env, this)

  fun tag tests(test: PonyTest) =>
    test(_NumericReadableTest)
    test(Property1UnitTest[(Array[U8] val, ByteArrays)](_SizeProperty))
    test(Property1UnitTest[(Array[U8] val, ByteArrays)](_HashProperty))
    test(Property1UnitTest[(Array[U8] val, ByteArrays)](_DropProperty))
    test(Property1UnitTest[(Array[U8] val, ByteArrays)](_TakeProperty))
    test(Property1UnitTest[(Array[U8] val, ByteArrays)](_SelectProperty))
    test(Property1UnitTest[(Array[U8] val, ByteArrays)](_ValuesProperty))
    test(Property1UnitTest[(Array[U8] val, ByteArrays)](_ApplyProperty))
    test(Property1UnitTest[(Array[U8] val, ByteArrays)](_TrimProperty))
    test(Property1UnitTest[(Array[U8] val, ByteArrays)](_FindProperty))
    test(Property1UnitTest[(Array[U8] val, ByteArrays)](_AddProperty))
    test(Property1UnitTest[(Array[U8] val, ByteArrays)](_ReadNumericProperty))
    test(Property1UnitTest[(Array[U8] val, ByteArrays)](_ArraysProperty))
    test(Property1UnitTest[String](_SipHash24Property))
    test(Property1UnitTest[Array[U8]](_SipHash24StreamingProperty))
    test(Property1UnitTest[Array[U8]](_HalfSipHash24StreamingProperty))

class \nodoc\ iso _NumericReadableTest is UnitTest
  fun name(): String => "valbytes/numeric-readable"
  fun apply(h: TestHelper) ? =>
    let arr: Array[U8] val = [as U8: 1; 2; 3; 4]

    let ba = ByteArrays([as U8: 1; 2; 3], [as U8: 4])

    h.assert_eq[U8](arr.read_u8(0)?, ba.read_u8(0)?)
    h.assert_eq[U8](arr.read_u8(1)?, ba.read_u8(1)?)
    h.assert_eq[U8](arr.read_u8(2)?, ba.read_u8(2)?)
    h.assert_eq[U8](arr.read_u8(3)?, ba.read_u8(3)?)
    h.assert_error({()? => ba.read_u8(4)? })

    h.assert_eq[U16](arr.read_u16(0)?, ba.read_u16(0)?)
    h.assert_eq[U16](arr.read_u16(1)?, ba.read_u16(1)?)
    h.assert_eq[U16](arr.read_u16(2)?, ba.read_u16(2)?)
    h.assert_error({()? => ba.read_u16(3)? })

    h.assert_eq[U32](arr.read_u32(0)?, ba.read_u32(0)?)
    h.assert_error({()? => ba.read_u32(1)? })

primitive \nodoc\ _ByteArrayAndSourceGen
  """
  Generator that returns a continuous byte array
  and a ByteArrays instance made from random splits of the first array.

  TODO: create a separate generator using non-consecutive source arrays.
  """
  fun apply(min_size: USize = 0, max_size: USize = 100): Generator[(Array[U8] val, ByteArrays)] =>
    let size_gen = Generators.usize(min_size, max_size)
    let array_and_splits_gen: Generator[(Array[U8] iso, Array[USize] iso)] =
      size_gen.flat_map[(Array[U8] iso, Array[USize] iso)](
        {(size: USize): Generator[(Array[U8] iso, Array[USize] iso)] =>
          let array_gen: Generator[Array[U8] iso] = Generators.iso_seq_of[U8, Array[U8] iso](Generators.u8('a', 'z'), size, size)
          let split_gen = Generators.iso_seq_of[USize, Array[USize] iso](
            Generators.usize(where min=0, max=size), size, size * 10).filter({(arr) =>
                var sum = USize(0)
                var i = USize(0)
                try
                  while i < arr.size() do
                    let elem = arr(i)?
                    sum = sum + elem
                    i = i + 1
                  end
                end
                (consume arr, sum >= size)
              })
          Generators.zip2[Array[U8] iso, Array[USize] iso](array_gen, split_gen)
        })
    array_and_splits_gen.map[(Array[U8] val, ByteArrays)](
      {(arg: (Array[U8] iso, Array[USize] iso)) =>
        // split generated array at given points until we reached the end
        (let immutable_arr: Array[U8] val, let splits: Array[USize] val) = recover val consume arg end
        var running_sum: USize = 0
        var ba = ByteArrays
        for split in (consume splits).values() do
          let trim = immutable_arr.trim(running_sum, running_sum + split)
          ba = ba + recover val trim.clone() end
          running_sum = running_sum + split
          if running_sum >= immutable_arr.size() then break end
        end
        (immutable_arr, ba)
      })

class \nodoc\ iso _SizeProperty is Property1[(Array[U8] val, ByteArrays)]
  fun name(): String => "valbytes/size/property"

  fun gen(): Generator[(Array[U8] val, ByteArrays)] => _ByteArrayAndSourceGen(where max_size=1000)

  fun property(sample: (Array[U8] val, ByteArrays), h: PropertyHelper) =>
    h.assert_eq[USize](sample._1.size(), sample._2.size())
    h.assert_array_eq[U8](sample._1, sample._2.array())


class \nodoc\ iso _HashProperty is Property1[(Array[U8] val, ByteArrays)]
  fun name(): String => "valbytes/hash/property"
  fun gen(): Generator[(Array[U8] val, ByteArrays)] => _ByteArrayAndSourceGen(where max_size=1000)

  fun property(sample: (Array[U8] val, ByteArrays), h: PropertyHelper) =>
    h.assert_eq[USize](
      String.from_array(sample._1).hash(),
      sample._2.hash()
    )


class \nodoc\ iso _DropProperty is Property1[(Array[U8] val, ByteArrays)]
  fun name(): String => "valbytes/drop/property"
  fun gen(): Generator[(Array[U8] val, ByteArrays)] => _ByteArrayAndSourceGen(where max_size=1000)

  fun property(sample: (Array[U8] val, ByteArrays), h: PropertyHelper) =>

    h.assert_eq[USize](sample._1.size(), sample._2.drop(0).size())
    if sample._1.size() > 0 then
      h.assert_eq[USize](sample._1.size() - 1, sample._2.drop(1).size())
    end
    h.assert_array_eq[U8](sample._1, sample._2.drop(0).array())
    h.assert_eq[USize](0, sample._2.drop(sample._2.size()).size())
    h.assert_eq[USize](0, sample._2.drop(sample._2.size() + 1).size())

    let middle = sample._1.size() / 2
    h.assert_array_eq[U8](
      sample._1.trim(middle, sample._1.size()),
      sample._2.drop(middle).array())


class \nodoc\ iso _TakeProperty is Property1[(Array[U8] val, ByteArrays)]
  fun name(): String => "valbytes/take/property"
  fun gen(): Generator[(Array[U8] val, ByteArrays)] => _ByteArrayAndSourceGen(where max_size=1000)

  fun property(sample: (Array[U8] val, ByteArrays), h: PropertyHelper) =>
    h.assert_eq[USize](sample._1.size(), sample._2.take(sample._1.size()).size())
    h.assert_eq[USize](0, sample._2.take(0).size())

    h.assert_array_eq[U8](
      sample._1,
      sample._2.take(sample._1.size()).array())
    h.assert_array_eq[U8](
      sample._1,
      sample._2.take(sample._1.size() + 1).array())

    let  middle = sample._1.size() / 2
    h.assert_array_eq[U8](
      sample._1.trim(0, middle),
      sample._2.take(middle).array())

class \nodoc\ iso _SelectProperty is Property1[(Array[U8] val, ByteArrays)]
  fun name(): String => "valbytes/select/property"
  fun gen(): Generator[(Array[U8] val, ByteArrays)] => _ByteArrayAndSourceGen(where max_size=100)

  fun property(sample: (Array[U8] val, ByteArrays), h: PropertyHelper) =>
    let sample_size = sample._1.size()
    //h.log("SAMPLE " + sample._2.debug())
    h.assert_array_eq[U8](sample._1, sample._2.select().array())
    let some = USize(10).min(sample_size)
    //h.log("TAKE " + sample._2.select(0, some).debug())
    h.assert_array_eq[U8](sample._1.trim(0, some), sample._2.select(0, some).array())
    //h.log("DROP " + sample._2.select(some, -1).debug())
    h.assert_array_eq[U8](sample._1.trim(some), sample._2.select(some, -1).array())

    h.assert_array_eq[U8](sample._1.trim(some, sample_size), sample._2.select(some, sample_size))

class \nodoc\ iso _ValuesProperty is Property1[(Array[U8] val, ByteArrays)]
  fun name(): String => "valbytes/values/property"
  fun gen(): Generator[(Array[U8] val, ByteArrays)] => _ByteArrayAndSourceGen(where max_size=1000)

  fun property(sample: (Array[U8] val, ByteArrays), h: PropertyHelper) ? =>
    let array_iter = sample._1.values()
    let ba_iter = sample._2.values()

    var i = USize(0)
    while array_iter.has_next() and ba_iter.has_next() do
      let array_elem = array_iter.next()?
      let ba_elem = ba_iter.next()?

      h.assert_eq[U8](array_elem, ba_elem, "differing elements at index: " + i.string())
      i = i + 1
    end
    if array_iter.has_next() or ba_iter.has_next() then
      h.fail("ByteArrays.values() longer than Array.values().")
    end


class \nodoc\ iso _ApplyProperty is Property1[(Array[U8] val, ByteArrays)]
  fun name(): String => "valbytes/apply/property"
  fun gen(): Generator[(Array[U8] val, ByteArrays)] => _ByteArrayAndSourceGen(where max_size=1000)

  fun property(sample: (Array[U8] val, ByteArrays), h: PropertyHelper) ? =>
    var i = USize(0)
    while i < sample._1.size() do
      h.assert_eq[U8](sample._1(i)?, sample._2(i)?, "Differing result from apply at index " + i.string())
      i = i + 1
    end


class \nodoc\ iso _TrimProperty is Property1[(Array[U8] val, ByteArrays)]
  fun name(): String => "valbytes/trim/property"
  fun gen(): Generator[(Array[U8] val, ByteArrays)] => _ByteArrayAndSourceGen(where max_size=1000)

  fun property(sample: (Array[U8] val, ByteArrays), h: PropertyHelper) =>

    let middle = sample._1.size() / 2
    h.assert_array_eq[U8](sample._1.trim(0, middle), sample._2.trim(0, middle))
    h.assert_array_eq[U8](sample._1.trim(middle), sample._2.trim(middle))
    h.assert_eq[USize](0, sample._2.trim(0, 0).size())
    h.assert_array_eq[U8](sample._1, sample._2.trim())


class \nodoc\ iso _ReadNumericProperty is Property1[(Array[U8] val, ByteArrays)]
  fun name(): String => "valbytes/read-numeric/property"
  fun gen(): Generator[(Array[U8] val, ByteArrays)] => _ByteArrayAndSourceGen(where min_size=16)

  fun property(sample: (Array[U8] val, ByteArrays), h: PropertyHelper) ? =>
    h.assert_eq[U8](sample._1.read_u8(0)?, sample._2.read_u8(0)?)
    h.assert_eq[U16](sample._1.read_u16(0)?, sample._2.read_u16(0)?)
    h.assert_eq[U32](sample._1.read_u32(0)?, sample._2.read_u32(0)?)
    h.assert_eq[U64](sample._1.read_u64(0)?, sample._2.read_u64(0)?)
    h.assert_eq[U128](sample._1.read_u128(0)?, sample._2.read_u128(0)?)


class \nodoc\ iso _SkipProperty is Property1[(Array[U8] val, ByteArrays)]
  fun name(): String => "valbytes/skip/property"
  fun gen(): Generator[(Array[U8] val, ByteArrays)] => _ByteArrayAndSourceGen(where min_size=2, max_size=1000)

  fun property(sample: (Array[U8] val, ByteArrays), h: PropertyHelper) =>
    // TODO
    None


class \nodoc\ iso _FindProperty is Property1[(Array[U8] val, ByteArrays)]
  fun name(): String => "valbytes/find/property"
  fun gen(): Generator[(Array[U8] val, ByteArrays)] => _ByteArrayAndSourceGen(where min_size=2, max_size=1000)

  fun property(sample: (Array[U8] val, ByteArrays), h: PropertyHelper) =>
    let head = sample._1.trim(0, 2)
    match sample._2.find(head)
    | (true, let index: USize) =>
      h.assert_eq[USize](0, index, "found at wrong index.")
    else
      h.fail("find did not find existing content.")
    end
    h.assert_false(sample._2.find("")._1)

    match sample._2.find(sample._1)
    | (true, 0) =>
      h.log("OK found its whole content.")
    else
      h.fail("unable to find its whole content.")
    end


class \nodoc\ iso _AddProperty is Property1[(Array[U8] val, ByteArrays)]
  fun name(): String => "valbytes/add/property"
  fun gen(): Generator[(Array[U8] val, ByteArrays)] => _ByteArrayAndSourceGen(where max_size=1000)

  fun property(sample: (Array[U8] val, ByteArrays), h: PropertyHelper) =>
    let add_me: Array[U8] val = [as U8: 'A'; 'B'; 'C'; 'D']
    let added_array = recover val sample._1.clone().>append(add_me) end
    let added_ba = sample._2 + add_me
    h.assert_array_eq[U8](added_array, added_ba.array())

class \nodoc\ iso _ArraysProperty is Property1[(Array[U8] val, ByteArrays)]
  fun name(): String => "valbytes/arrays/property"
  fun gen(): Generator[(Array[U8] val, ByteArrays)] => _ByteArrayAndSourceGen(where max_size=100)

  fun property(sample: (Array[U8] val, ByteArrays), h: PropertyHelper) =>
    h.log(sample._2.debug())
    let acc: Array[U8] iso = recover iso Array[U8](sample._1.size()) end
    for array in sample._2.arrays().values() do
      acc.append(array)
    end
    h.assert_array_eq[U8](sample._1, consume acc)

class \nodoc\ iso _ArraysTest is UnitTest
  fun name(): String => "valbytes/arrays"
  fun apply(h: TestHelper)? =>
    let ba = ByteArrays("abc".array(), ByteArrays("def".array()))
    let acc = recover iso Array[U8](6) end
    let arrs = ba.arrays()
    h.assert_eq[USize](2, arrs.size())
    h.assert_array_eq[U8]("abc".array(), arrs(0)?)
    h.assert_array_eq[U8]("def".array(), arrs(1)?)

class \nodoc\ iso _SipHash24Property is Property1[String]
  """checks conformance with stdlib implementation."""

  fun name(): String => "siphash24/property"

  fun gen(): Generator[String] =>
    Generators.byte_string(
      Generators.u8(),
      0,
      100000
    )

  fun property(sample: String, h: PropertyHelper) =>
    let my_siphash =
      ifdef ilp32 then
        HalfSipHash24.apply[String](sample).usize()
      else
        SipHash24.apply[String](sample).usize()
      end
    h.assert_eq[USize](my_siphash, sample.hash())

class \nodoc\ iso _SipHash24StreamingProperty is Property1[Array[U8]]
  fun name(): String => "siphash24/streaming/property"

  fun gen(): Generator[Array[U8]] =>
    let sizeGen = Generators.usize(where min=0, max=100)
    sizeGen.flat_map[Array[U8]]({(size: USize) =>
      let arr_size = size * 8
      Generators.array_of[U8](Generators.u8() where min = arr_size, max = arr_size)
    })

  fun property(sample: Array[U8], h: PropertyHelper) ? =>
    var i: USize = 0
    let endi = sample.size() - (sample.size() % 8)
    let sip = SipHash24Streaming.create()

    while i < endi do
      let m = sample.read_u64(i)?
      sip.update(m)
      i = i + 8
    end
    let streaming_hash = sip.finish()
    let array_hash = SipHash24.apply[Array[U8]](sample)
    h.assert_eq[U64](array_hash, streaming_hash)


class \nodoc\ iso _HalfSipHash24StreamingProperty is Property1[Array[U8]]
  fun name(): String => "halfsiphash24/streaming/property"

  fun gen(): Generator[Array[U8]] =>
    let sizeGen = Generators.usize(where min=0, max=100)
    sizeGen.flat_map[Array[U8]]({(size: USize) =>
      let arr_size = size * 4
      Generators.array_of[U8](Generators.u8() where min = arr_size, max = arr_size)
    })

  fun property(sample: Array[U8], h: PropertyHelper) ? =>
    var i: USize = 0
    let endi = sample.size() - (sample.size() % 4)
    h.log("size: " + sample.size().string())
    let sip = HalfSipHash24Streaming.create()

    while i < endi do
      let m = sample.read_u32(i)?
      sip.update(m)
      i = i + 4
    end
    let streaming_hash = sip.finish()
    let array_hash = HalfSipHash24.apply[Array[U8]](sample)
    h.assert_eq[U32](array_hash, streaming_hash)
