## Unreleased
* Support Rails 7.0.

## 2.2.0
* Drop support for old Ruby versions.
* Support Rails 5.1.

## 2.1.1
* Delete circular symlink in gem package
  * No changes in library code

## 2.1.0
* Support Rails 5.
* Drop support of ruby 1.9.x and 2.0.0.
* Drop support of Rails 3.x.

## 2.0.8
* Improve documentation about expanding class methods.

## 2.0.7
* Fix run_default again. 2.0.6 still has run_default bug. Use unstack block instad of depth counting.

## 2.0.6
* Fix stack control of run_default.

## 2.0.5
* Guarantee thread-safety of unit stack for Rails 4

## 2.0.4
* Allow to change Chanko::Config.eager_load after loading chanko

## 2.0.3
* Custom eager-loading support on production env
