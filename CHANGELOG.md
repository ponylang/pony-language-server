# Change Log

All notable changes to this project will be documented in this file. This project adheres to [Semantic Versioning](http://semver.org/) and [Keep a CHANGELOG](http://keepachangelog.com/).

## [unreleased] - unreleased

### Fixed

- Fixed workspace discovery of folders without `corral.json` but containing a `main.pony` file ([PR #9](https://github.com/ponylang/pony-language-server/pull/9))
- Properly discover all packages in a program, not only the packages and dependencies provided in `corral.json` ([PR #8](https://github.com/ponylang/pony-language-server/pull/9))

### Added

### Changed

## [0.2.2] - 2024-07-27

### Fixed

- Properly set textDocumentSync properties of the serverCapabilities ([PR #7](https://github.com/ponylang/pony-language-server/pull/7))

## [0.2.1] - 2024-06-24

### Fixed

- Upgrade pony-ast dependency to 0.2.1 ([PR #1](https://github.com/ponylang/pony-language-server/pull/1))
