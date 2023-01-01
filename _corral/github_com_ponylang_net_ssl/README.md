# net_ssl

Pony library that brings SSL networking support to Pony. Requires LibreSSL or OpenSSL. See installation for more details.

## Status

Production ready.

## Installation

* Install [corral](https://github.com/ponylang/corral)
* `corral add github.com/ponylang/net_ssl.git --version 1.2.1`
* `corral fetch` to fetch your dependencies
* `use "net_ssl"` to include this package
* `corral run -- ponyc` to compile your application

## Supported SSL versions

The 0.9.0 and 1.1.x OpenSSL versions and corresponding compatible LibreSSL library versions are supported.

The default is to use the 0.9.x library APIs. You can change the selected supported library version at compile-time by using Pony's compile time definition functionality.

### Using OpenSSL 0.9.0

```bash
corral run -- ponyc -Dopenssl_0.9.0
```

### Using OpenSSL 1.1.x

```bash
corral run -- ponyc -Dopenssl_1.1.x
```

## Dependencies

`net_ssl` requires either LibreSSL or OpenSSL in order to operate. You'll might need to install it within your environment of choice.

### Installing on APT based Linux distributions

```bash
sudo apt-get install -y libssl-dev
```

### Installing on Alpine Linux

```bash
apk add --update libressl-dev
```

### Installing on Arch Linux

```bash
pacman -S openssl

```

### Installing on macOS with Homebrew

```bash
brew update
brew install libressl
```

#### Installing on macOS with MacPorts

```bash
sudo port install libressl
```

### Installing on RPM based Linux distributions with dnf

```bash
sudo dnf install openssl-devel
```

### Installing on RPM based Linux distributions with yum

```bash
sudo yum install openssl-devel
```

### Installing on RPM based Linux distributions with zypper

```bash
sudo zypper install libopenssl-devel
```

### Installing on Windows

If you use [Corral](https://github.com/ponylang/corral) to include this package as dependency of a project, Corral will download and build LibreSSL for you the first time you run `corral fetch`.  Otherwise, before using this package, you must run `.\make.ps1 libs` in its base directory to download and build LibreSSL for Windows. In both cases, you will need CMake (3.15 or higher) and 7Zip (`7z.exe`) in your `PATH`; and Visual Studio 2017 or later (or the Visual C++ Build Tools 2017 or later) installed in your system.

You should pass `--define openssl_0.9.0` to Ponyc when using this package on Windows.

## API Documentation

[https://ponylang.github.io/net_ssl](https://ponylang.github.io/net_ssl)
