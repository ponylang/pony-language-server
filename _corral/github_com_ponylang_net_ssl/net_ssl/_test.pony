use "pony_test"
use "itertools"
use "files"
use "net"

actor \nodoc\ Main is TestList
  new create(env: Env) => PonyTest(env, this)
  new make() => None

  fun tag tests(test: PonyTest) =>
    test(_TestALPNProtocolListEncoding)
    test(_TestALPNProtocolListDecode)
    test(_TestALPNStandardProtocolResolver)
    test(_TestTCPSSLWritev)
    test(_TestTCPSSLExpect)
    test(_TestTCPSSLMute)
    test(_TestTCPSSLUnmute)
    ifdef windows then
      test(_TestWindowsLoadRootCertificates)
    else
      test(_TestTCPSSLThrottle)
    end

class \nodoc\ iso _TestALPNProtocolListEncoding is UnitTest
  """
  [Protocol Lists]() are correctly encoded and errors are raised when trying to encode invalid identifiers
  """
  fun name(): String => "net/ssl/_ALPNProtocolList.from_array"

  fun apply(h: TestHelper) =>
    let valid_h2http11 = "\x02h2\x08http/1.1"

    h.assert_error(
      {()? => _ALPNProtocolList.from_array([""])? },
      "raise error on empty protocol identifier")
    h.assert_error(
      {()? => _ALPNProtocolList.from_array(["dummy"; ""])? },
      "raise error when encoding an protocol identifier")
    h.assert_error(
      {()? => _ALPNProtocolList.from_array([])? },
      "raise error when encoding an empty array")

    let id256chars =
      recover val String(256) .> concat(Iter[U8].repeat_value('A'), 0, 256) end
    h.assert_eq[USize](id256chars.size(), USize(256))
    h.assert_error(
      {()? => _ALPNProtocolList.from_array([id256chars])? },
      "raise error on identifier longer than 256 bytes.")
    h.assert_error(
      {()? => _ALPNProtocolList.from_array([id256chars; "dummy"])? },
      "raise error on identifier longer than 256 bytes.")

    try
      h.assert_eq[String](
        _ALPNProtocolList.from_array(["h2"; "http/1.1"])?, valid_h2http11)
    else
      h.fail("failed to encode an array of valid identifiers")
    end

class \nodoc\ iso _TestALPNProtocolListDecode is UnitTest
  fun name(): String => "net/ssl/_ALPNProtocolList.to_array"

  fun apply(h: TestHelper) =>
    let valid_h2http11 = "\x02h2\x08http/1.1"
    try
      let decoded = _ALPNProtocolList.to_array(valid_h2http11)?
      h.assert_eq[USize](decoded.size(), USize(2))
      h.assert_eq[ALPNProtocolName](decoded(0)?, "h2")
      h.assert_eq[ALPNProtocolName](decoded(1)?, "http/1.1")
    else
      h.fail("failed to decode a valid protocol list")
    end

    h.assert_error(
      {()? => _ALPNProtocolList.to_array("")? },
      "raise error when decoding an empty protocol list")
    h.assert_error(
      {()? => _ALPNProtocolList.to_array("\x03h2")? },
      "raise error on malformed data")
    h.assert_error(
      {()? => _ALPNProtocolList.to_array("\x00")? },
      "raise error on malformed data")
    h.assert_error(
      {()? => _ALPNProtocolList.to_array("\x01A\x00")? },
      "raise error on malformed data")
    h.assert_error(
      {()? => _ALPNProtocolList.to_array("\x01A\x01")? },
      "raise error on malformed data")

class \nodoc\ iso _TestALPNStandardProtocolResolver is UnitTest
  fun name(): String => "net/ssl/StandardALPNProtocolResolver"

  fun apply(h: TestHelper) =>
    fallback_case(h)
    failure_case(h)
    match_cases(h)

  fun fallback_case(h: TestHelper) =>
    let resolver = ALPNStandardProtocolResolver(["h2"])

    match resolver.resolve(["http/1.1"])
    | "http/1.1" => None
    else
      h.fail(
        "ALPNStandardProtocolResolver didn't fall back to clients "
        + "first identifier, when it should have")
    end

  fun failure_case(h: TestHelper) =>
    let resolver = ALPNStandardProtocolResolver(["h2"], false)

    match resolver.resolve(["http/1.1"])
    | ALPNWarning => None
    else
      h.fail(
        "ALPNStandardProtocolResolver didn't return ALPNFailure, "
        + "when it should have")
    end

  fun match_cases(h: TestHelper) =>
    let resolver = ALPNStandardProtocolResolver(["h2"])

    match resolver.resolve(["dummy"; "h2"; "http/1.1"])
    | "h2" => None
    else
      h.fail("ALPNStandardProtocolResolver didn't return a matching protocol")
    end

class \nodoc\ iso _TestTCPSSLExpect is UnitTest
  """
  Test expecting framed data with TCP over SSL.
  """
  fun name(): String => "net/TCPSSL.expect"
  fun label(): String => "unreliable-osx"
  fun exclusion_group(): String => "network"

  fun ref apply(h: TestHelper) =>
    h.expect_action("client receive")
    h.expect_action("server receive")
    h.expect_action("expect received")

    (let ssl_client, let ssl_server) =
      try
        _TestSSLContext(h)?
      else
        h.fail("ssl stuff failed")
        return
      end

    _TestTCP(h)(
      SSLConnection(_TestTCPExpectNotify(h, false), consume ssl_client), SSLConnection(_TestTCPExpectNotify(h, true), consume ssl_server))

class \nodoc\ iso _TestTCPSSLWritev is UnitTest
  """
  Test writev (and sent/sentv notification).
  """
  fun name(): String => "net/TCPSSL.writev"
  fun exclusion_group(): String => "network"

  fun ref apply(h: TestHelper) =>
    h.expect_action("client connect")
    h.expect_action("server receive")

    (let ssl_client, let ssl_server) =
      try
        _TestSSLContext(h)?
      else
        h.fail("ssl stuff failed")
        return
      end

    _TestTCP(h)(
      SSLConnection(_TestTCPWritevNotifyClient(h), consume ssl_client), SSLConnection(_TestTCPWritevNotifyServer(h), consume ssl_server))

class \nodoc\ iso _TestTCPSSLMute is UnitTest
  """
  Test that the `mute` behavior stops us from reading incoming data. The
  test assumes that send/recv works correctly and that the absence of
  data received is because we muted the connection.

  Test works as follows:

  Once an incoming connection is established, we set mute on it and then
  verify that within a 2 second long test that received is not called on
  our notifier. A timeout is considering passing and received being called
  is grounds for a failure.
  """
  fun name(): String => "net/TCPSSLMute"
  fun exclusion_group(): String => "network"

  fun ref apply(h: TestHelper) =>
    h.expect_action("receiver accepted")
    h.expect_action("sender connected")
    h.expect_action("receiver muted")
    h.expect_action("receiver asks for data")
    h.expect_action("sender sent data")

    (let ssl_client, let ssl_server) =
      try
        _TestSSLContext(h)?
      else
        h.fail("ssl stuff failed")
        return
      end

    _TestTCP(h)(
      SSLConnection(_TestTCPMuteSendNotify(h), consume ssl_client),
      SSLConnection(_TestTCPMuteReceiveNotify(h), consume ssl_server))

  fun timed_out(h: TestHelper) =>
    h.complete(true)

class \nodoc\ iso _TestTCPSSLUnmute is UnitTest
  """
  Test that the `unmute` behavior will allow a connection to start reading
  incoming data again. The test assumes that `mute` works correctly and that
  after muting, `unmute` successfully reset the mute state rather than `mute`
  being broken and never actually muting the connection.

  Test works as follows:

  Once an incoming connection is established, we set mute on it, request
  that data be sent to us and then unmute the connection such that we should
  receive the return data.
  """
  fun name(): String => "net/TCPSSLUnmute"
  fun exclusion_group(): String => "network"

  fun ref apply(h: TestHelper) =>
    h.expect_action("receiver accepted")
    h.expect_action("sender connected")
    h.expect_action("receiver muted")
    h.expect_action("receiver asks for data")
    h.expect_action("receiver unmuted")
    h.expect_action("sender sent data")

    (let ssl_client, let ssl_server) =
      try
        _TestSSLContext(h)?
      else
        h.fail("ssl stuff failed")
        return
      end

    _TestTCP(h)(
      SSLConnection(_TestTCPMuteSendNotify(h), consume ssl_client),
      SSLConnection(_TestTCPUnmuteReceiveNotify(h), consume ssl_server))

class \nodoc\ iso _TestTCPSSLThrottle is UnitTest
  """
  Test that when we experience backpressure when sending that the `throttled`
  method is called on our `TCPConnectionNotify` instance.

  We do this by starting up a server connection, muting it immediately and then
  sending data to it which should trigger a throttling to happen. We don't
  start sending data til after the receiver has muted itself and sent the
  sender data. This verifies that muting has been completed before any data is
  sent as part of testing throttling.

  This test assumes that muting functionality is working correctly.
  """
  fun name(): String => "net/TCPSSLThrottle"
  fun exclusion_group(): String => "network"

  fun ref apply(h: TestHelper) =>
    h.expect_action("receiver accepted")
    h.expect_action("sender connected")
    h.expect_action("receiver muted")
    h.expect_action("receiver asks for data")
    h.expect_action("sender sent data")
    h.expect_action("sender throttled")

    (let ssl_client, let ssl_server) =
      try
        _TestSSLContext(h)?
      else
        h.fail("ssl stuff failed")
        return
      end

    _TestTCP(h)(
      SSLConnection(_TestTCPThrottleSendNotify(h), consume ssl_client),
      SSLConnection(_TestTCPThrottleReceiveNotify(h), consume ssl_server))

class \nodoc\ iso _TestWindowsLoadRootCertificates is UnitTest
  """
  Test loading the Windows root certificates when `set_authority(None, None)`
  is called.
  """
  fun name(): String => "net/TCPSSLWindowsLoadRootCertificates"

  fun ref apply(h: TestHelper) =>
    try
      let auth = FileAuth(h.env.root)
      let ssl_ctx =
        recover
          SSLContext
            .>set_authority(None, None)?
            .>set_cert(FilePath(auth, "assets/cert.pem"),
              FilePath(auth, "assets/key.pem"))?
            .>set_client_verify(true)
            .>set_server_verify(true)
        end

      let ssl_client = ssl_ctx.client()?
      let ssl_server = ssl_ctx.server()?

      _TestTCP(h)(
        SSLConnection(_TestTCPExpectNotify(h, false), consume ssl_client),
        SSLConnection(_TestTCPExpectNotify(h, true), consume ssl_server))
    else
      h.fail("set_authority failed")
    end

class \nodoc\ _TestTCPThrottleReceiveNotify is TCPConnectionNotify
  """
  Notifier to that mutes itself on startup. We then send data to it in order
  to trigger backpressure on the sender.
  """
  let _h: TestHelper

  new iso create(h: TestHelper) =>
    _h = h

  fun ref accepted(conn: TCPConnection ref) =>
    _h.complete_action("receiver accepted")
    conn.mute()
    _h.complete_action("receiver muted")
    conn.write("send me some data that i won't ever read")
    _h.complete_action("receiver asks for data")
    _h.dispose_when_done(conn)

  fun ref connect_failed(conn: TCPConnection ref) =>
    _h.fail_action("receiver connect failed")

class \nodoc\ _TestTCPThrottleSendNotify is TCPConnectionNotify
  """
  Notifier that sends data back when it receives any. Used in conjunction with
  the mute receiver to verify that after muting, we don't get any data on
  to the `received` notifier on the muted connection. We only send in response
  to data from the receiver to make sure we don't end up failing due to race
  condition where the senders sends data on connect before the receiver has
  executed its mute statement.
  """
  let _h: TestHelper
  var _throttled_yet: Bool = false

  new iso create(h: TestHelper) =>
    _h = h

  fun ref connected(conn: TCPConnection ref) =>
    _h.complete_action("sender connected")

  fun ref connect_failed(conn: TCPConnection ref) =>
    _h.fail_action("sender connect failed")

  fun ref received(
    conn: TCPConnection ref,
    data: Array[U8] val,
    times: USize)
    : Bool
  =>
    conn.write("it's sad that you won't ever read this")
    _h.complete_action("sender sent data")
    true

  fun ref throttled(conn: TCPConnection ref) =>
    _throttled_yet = true
    _h.complete_action("sender throttled")
    _h.complete(true)

  fun ref sent(conn: TCPConnection ref, data: ByteSeq): ByteSeq =>
    if not _throttled_yet then
      conn.write("this is more data that you won't ever read" * 10000)
    end
    data

class \nodoc\ _TestTCPMuteReceiveNotify is TCPConnectionNotify
  """
  Notifier to fail a test if we receive data after muting the connection.
  """
  let _h: TestHelper

  new iso create(h: TestHelper) =>
    _h = h

  fun ref accepted(conn: TCPConnection ref) =>
    _h.complete_action("receiver accepted")
    conn.mute()
    _h.complete_action("receiver muted")
    conn.write("send me some data that i won't ever read")
    _h.complete_action("receiver asks for data")
    _h.dispose_when_done(conn)

  fun ref received(
    conn: TCPConnection ref,
    data: Array[U8] val,
    times: USize)
    : Bool
  =>
    _h.complete(false)
    true

  fun ref connect_failed(conn: TCPConnection ref) =>
    _h.fail_action("receiver connect failed")


class \nodoc\ _TestTCPMuteSendNotify is TCPConnectionNotify
  """
  Notifier that sends data back when it receives any. Used in conjunction with
  the mute receiver to verify that after muting, we don't get any data on
  to the `received` notifier on the muted connection. We only send in response
  to data from the receiver to make sure we don't end up failing due to race
  condition where the senders sends data on connect before the receiver has
  executed its mute statement.
  """
  let _h: TestHelper

  new iso create(h: TestHelper) =>
    _h = h

  fun ref connected(conn: TCPConnection ref) =>
    _h.complete_action("sender connected")

  fun ref connect_failed(conn: TCPConnection ref) =>
    _h.fail_action("sender connect failed")

   fun ref received(
    conn: TCPConnection ref,
    data: Array[U8] val,
    times: USize)
    : Bool
   =>
     conn.write("it's sad that you won't ever read this")
     _h.complete_action("sender sent data")
     true

class \nodoc\ _TestTCPExpectNotify is TCPConnectionNotify
  let _h: TestHelper
  let _server: Bool
  var _expect: USize = 4
  var _frame: Bool = true

  new iso create(h: TestHelper, server: Bool) =>
    _server = server
    _h = h

  fun ref accepted(conn: TCPConnection ref) =>
    conn.set_nodelay(true)
    try
      conn.expect(_expect)?
      _send(conn, "hi there")
    else
      _h.fail("expect threw an error")
    end

  fun ref connect_failed(conn: TCPConnection ref) =>
    _h.fail_action("client connect failed")

  fun ref connected(conn: TCPConnection ref) =>
    _h.complete_action("client connect")
    conn.set_nodelay(true)
    try
      conn.expect(_expect)?
    else
      _h.fail("expect threw an error")
    end

  fun ref expect(conn: TCPConnection ref, qty: USize): USize =>
    _h.complete_action("expect received")
    qty

  fun ref received(
    conn: TCPConnection ref,
    data: Array[U8] val,
    times: USize)
    : Bool
  =>
    if _frame then
      _frame = false
      _expect = 0

      for i in data.values() do
        _expect = (_expect << 8) + i.usize()
      end
    else
      _h.assert_eq[USize](_expect, data.size())

      if _server then
        _h.complete_action("server receive")
        _h.assert_eq[String](String.from_array(data), "goodbye")
      else
        _h.complete_action("client receive")
        _h.assert_eq[String](String.from_array(data), "hi there")
        _send(conn, "goodbye")
      end

      _frame = true
      _expect = 4
    end

    try
      conn.expect(_expect)?
    else
      _h.fail("expect threw an error")
    end
    true

  fun ref _send(conn: TCPConnection ref, data: String) =>
    let len = data.size()

    var buf = recover Array[U8] end
    buf.push((len >> 24).u8())
    buf.push((len >> 16).u8())
    conn.write(consume buf)

    buf = recover Array[U8] end
    buf.push((len >> 8).u8())
    buf.push((len >> 0).u8())
    buf.append(data)
    conn.write(consume buf)

class \nodoc\ _TestTCPWritevNotifyClient is TCPConnectionNotify
  let _h: TestHelper

  new iso create(h: TestHelper) =>
    _h = h

  fun ref sentv(conn: TCPConnection ref, data: ByteSeqIter): ByteSeqIter =>
    recover
      Array[ByteSeq] .> concat(data.values()) .> push(" (from client)")
    end

  fun ref connected(conn: TCPConnection ref) =>
    _h.complete_action("client connect")
    conn.writev(recover ["hello"; ", hello"] end)

  fun ref connect_failed(conn: TCPConnection ref) =>
    _h.fail_action("client connect failed")

class \nodoc\ _TestTCPWritevNotifyServer is TCPConnectionNotify
  let _h: TestHelper
  var _buffer: String iso = recover iso String end

  new iso create(h: TestHelper) =>
    _h = h

  fun ref received(
    conn: TCPConnection ref,
    data: Array[U8] iso,
    times: USize)
    : Bool
  =>
    _buffer.append(consume data)

    let expected = "hello, hello (from client)"

    if _buffer.size() >= expected.size() then
      let buffer: String = _buffer = recover iso String end
      _h.assert_eq[String](expected, consume buffer)
      _h.complete_action("server receive")
    end
    true

  fun ref connect_failed(conn: TCPConnection ref) =>
    _h.fail_action("sender connect failed")

class \nodoc\ _TestTCP is TCPListenNotify
  """
  Run a typical TCP test consisting of a single TCPListener that accepts a
  single TCPConnection as a client, using a dynamic available listen port.
  """
  let _h: TestHelper
  var _client_conn_notify: (TCPConnectionNotify iso | None) = None
  var _server_conn_notify: (TCPConnectionNotify iso | None) = None

  new iso create(h: TestHelper) =>
    _h = h

  fun iso apply(c: TCPConnectionNotify iso, s: TCPConnectionNotify iso) =>
    _client_conn_notify = consume c
    _server_conn_notify = consume s

    let h = _h
    h.expect_action("server create")
    h.expect_action("server listen")
    h.expect_action("client create")
    h.expect_action("server accept")

    let auth = TCPListenAuth(h.env.root)
    h.dispose_when_done(TCPListener(auth, consume this))
    h.complete_action("server create")

    h.long_test(2_000_000_000)

  fun ref not_listening(listen: TCPListener ref) =>
    _h.fail_action("server listen")

  fun ref listening(listen: TCPListener ref) =>
    _h.complete_action("server listen")

    try
      let auth = TCPConnectAuth(_h.env.root)
      let notify = (_client_conn_notify = None) as TCPConnectionNotify iso^
      (let host, let port) = listen.local_address().name()?
      _h.dispose_when_done(TCPConnection(auth, consume notify, host, port))
      _h.complete_action("client create")
    else
      _h.fail_action("client create")
    end

  fun ref connected(listen: TCPListener ref): TCPConnectionNotify iso^ ? =>
    try
      let notify = (_server_conn_notify = None) as TCPConnectionNotify iso^
      _h.complete_action("server accept")
      consume notify
    else
      _h.fail_action("server accept")
      error
    end

class \nodoc\ _TestTCPUnmuteReceiveNotify is TCPConnectionNotify
  """
  Notifier to test that after muting and unmuting a connection, we get data
  """
  let _h: TestHelper

  new iso create(h: TestHelper) =>
    _h = h

  fun ref accepted(conn: TCPConnection ref) =>
    _h.complete_action("receiver accepted")
    conn.mute()
    _h.complete_action("receiver muted")
    conn.write("send me some data that i won't ever read")
    _h.complete_action("receiver asks for data")
    conn.unmute()
    _h.complete_action("receiver unmuted")

  fun ref received(
    conn: TCPConnection ref,
    data: Array[U8] val,
    times: USize)
    : Bool
  =>
    _h.complete(true)
    true

  fun ref connect_failed(conn: TCPConnection ref) =>
    _h.fail_action("receiver connect failed")

primitive \nodoc\ _TestSSLContext
  fun val apply(h: TestHelper): (SSL iso^, SSL iso^) ? =>
    let sslctx =
      try
        let auth = FileAuth(h.env.root)
        recover
          SSLContext
            .> set_authority(FilePath(auth, "assets/cert.pem"))?
            .> set_cert(
                FilePath(auth, "assets/cert.pem"),
                FilePath(auth, "assets/key.pem"))?
            .> set_client_verify(true)
            .> set_server_verify(true)
        end
      else
        h.fail("set_cert failed")
        error
      end

    let ssl_client =
      try
        sslctx.client()?
      else
        h.fail("failed getting ssl client session")
        error
      end
    let ssl_server =
      try
        sslctx.server()?
      else
        h.fail("failed getting ssl server session")
        error
      end

    (consume ssl_client, consume ssl_server)
