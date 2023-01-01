## Add path to Homebrew's LibreSSL on ARM macOS

With the release of ponyc 0.45.0, Apple Silicon is now a supported platform, which means that the default install location of Homebrew formulas has changed. This release of net_ssl allows to build the library without using the ponyc `--path` option to include LibreSSL.

