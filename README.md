# Kraken Ruby Client

A Ruby API wrapper for the Kraken Bitcoin Exchange, written for Ruby 2.3+.

Emphasis on speed, simplicity, no meta-programming, and few dependencies.

- Kraken Ruby Client has only one runtime dependency:
The fast [Curb (CUrl-RuBy) gem](https://github.com/taf2/curb), which provides
Ruby bindings for [libcurl](https://github.com/curl/curl), a fully-featured
client-side URL transfer library written in C.

- Kraken Ruby Client does not use [Hashie](https://github.com/intridea/hashie),
to avoid the [pain and performance costs]
(http://www.schneems.com/2014/12/15/hashie-considered-harmful.html) of
[subclassing Hash]
(http://tenderlovemaking.com/2014/06/02/yagni-methods-are-killing-me.html).

- Kraken Ruby Client uses fast, straightforward Minitest for its test suite.

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

Copyright © 2016 Jon Atack (@jonatack)
