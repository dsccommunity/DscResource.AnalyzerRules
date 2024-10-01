# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Repository Files
  - Add Issue Template.
  - Add PR Template.
  - Add LICENSE.md.
  - Add SECURITY.md
  - Add codecov config.

### Fixed

- Update build files to allow everything to work
- Update build files to include tasks for deploy
- Update pipeline to use the correct default branch
- Repository Files
  - Update README including badges.

## [0.2.0] - 2019-11-21

- Fix issue with DSC composite resources.
- Fix issues with LF by hashtable check.

### Added

- Create new module out of the nested one from DscResource.tests
- Used the DSC custom rules from this built module to apply to its own source
- Suggested corrections for keyword check

### Changed

- Performance improvement on QA tests
- Excluded Help Quality for now
