# Kraken Ruby Client

A work-in-progress Ruby API wrapper for the Kraken Bitcoin Exchange.

Emphasis on speed, simplicity, no meta-programming, and few dependencies.

Kraken Ruby Client:

- follows
[Proposal X-ISO4217-A3](http://www.ifex-project.org/our-proposals/x-iso4217-a3),
an API standards protocol for the open identification of currencies and
currency-like commodities on the internet by the
[Internet Financial EXchange (IFEX)](http://www.ifex-project.org/) organisation.

- has only one runtime dependency:
The fast [Curb (CUrl-RuBy) gem](https://github.com/taf2/curb), which provides
Ruby bindings for [libcurl](https://github.com/curl/curl), a fully-featured
client-side URL transfer library written in C.

- does not use [Hashie](https://github.com/intridea/hashie),
to avoid the [pain and performance costs]
(http://www.schneems.com/2014/12/15/hashie-considered-harmful.html) of
[subclassing Hash]
(http://tenderlovemaking.com/2014/06/02/yagni-methods-are-killing-me.html).

- uses fast, straightforward, assertions-style
[Minitest](https://github.com/seattlerb/minitest) for its test suite.

Currently developed with Ruby 2.4.0. Written for Ruby 2.3 and up.

## Getting started

## Usage

## Contributions

To support the project:

* Use Kraken Ruby Client in your apps, and please file an issue if you
encounter anything that's broken or missing. A failing test to demonstrate
the issue is awesome. A pull request with passing tests is even better!

## License/disclaimer

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

The author may be contacted by email at jon@atack.com.

Copyright © 2017 Jon Atack (@jonatack)
