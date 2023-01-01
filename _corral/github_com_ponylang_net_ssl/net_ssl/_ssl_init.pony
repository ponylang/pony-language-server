use "path:/usr/local/opt/libressl/lib" if osx and x86
use "path:/opt/homebrew/opt/libressl/lib" if osx and arm
use "lib:ssl"
use "lib:crypto"

use @ponyint_ssl_multithreading[Pointer[U8]](count: U32)
use @OPENSSL_init_ssl[I32](opts: U64, settings: Pointer[_OpenSslInitSettings])
use @OPENSSL_INIT_new[Pointer[_OpenSslInitSettings]]()
use @OPENSSL_INIT_free[None](settings: Pointer[_OpenSslInitSettings])
use @SSL_library_init[I32]() if "openssl_0.9.0"
use @SSL_load_error_strings[None]() if "openssl_0.9.0"
use @CRYPTO_num_locks[I32]() if "openssl_0.9.0"
use @CRYPTO_set_locking_callback[None](cb: Pointer[U8]) if "openssl_0.9.0"

primitive _OpenSslInitSettings

// From https://github.com/ponylang/ponyc/issues/330
primitive _OpenSslInitNoLoadSslStrings    fun val apply(): U64 => 0x00100000
primitive _OpenSslInitLoadSslStrings      fun val apply(): U64 => 0x00200000
primitive _OpenSslInitNoLoadCryptoStrings fun val apply(): U64 => 0x00000001
primitive _OpenSslInitLoadCryptoStrings   fun val apply(): U64 => 0x00000002

primitive _SSLInit
  """
  This initialises SSL when the program begins.
  """
  fun _init() =>
    ifdef "openssl_1.1.x" then
      let settings = @OPENSSL_INIT_new()
      @OPENSSL_init_ssl(
        _OpenSslInitLoadSslStrings() + _OpenSslInitLoadCryptoStrings(),
        settings)
      @OPENSSL_INIT_free(settings)
    elseif "openssl_0.9.0" then
      @SSL_load_error_strings()
      @SSL_library_init()
      let cb =
        @ponyint_ssl_multithreading(@CRYPTO_num_locks().u32())
      @CRYPTO_set_locking_callback(cb)
    else
      compile_error "You must select an SSL version to use."
    end
