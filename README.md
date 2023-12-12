# @ocku/whois-servers ![npm](https://img.shields.io/npm/v/%40ocku%2Fwhois-servers)

A whois server list compiled biweekly from IANA's TLD list.

## Usage

This library provides a compiled list of whois servers for each TLD in the format `{domain: server}`.

```js
import servers from '@ocku/whois-servers';
// or
const servers = require('@ocku/whois-servers');
```

```js
console.log(servers.de); // whois.nic.de
console.log(servers.arpa); // whois.iana.org
console.log(servers['xn--tckwe']); // whois.nic.xn--tckwe
```

## Punycode

Punycode TLDs are supported, but to keep overhead low, special Unicode characters are not automatically transcoded to LDH.

What this means is that if you want to get the server of a tld, for example `コム`, you would have to reference it by its ASCII name:

```js
servers['xn--tckwe']; // whois.nic.xn--tckwe
```

## Staying up to date

All server updates are done by raising the `patch` version of the library, so you should be able to stay up to date simply by updating your dependencies every so often.

## Build

In the case that you want to build this library yourself, do the following:

```sh
yarn # install prettier
./genenerate.sh # run the generator
```

And that's it! It will take a while but that's all that you need to do.

## Reference

- this project was heavily inspired by [the whois-servers-list npm package](https://github.com/WooMai/whois-servers).
