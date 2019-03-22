[![Build Status](https://travis-ci.com/jeremyvaartjes/subminder.svg?branch=master)](https://travis-ci.com/jeremyvaartjes/comgen)

![SubMinder Icon](https://raw.githubusercontent.com/jeremyvaartjes/subminder/master/subminder.png)
SubMinder
=========

Keep tabs on your subscriptions.

[![Get it on AppCenter](https://appcenter.elementary.io/badge.svg)](https://appcenter.elementary.io/com.github.jeremyvaartjes.subminder)﻿

![SubMinder Screenshot](https://raw.githubusercontent.com/jeremyvaartjes/subminder/master/data/screenshot.png)

Developing and Building
=======================

If you want to hack on and build SubMinder yourself, you'll need the following dependencies:

* libgtk-3-dev
* meson
* valac
* libsoup2.4-dev
* libjson-glib-dev
* libgranite-dev
* libgee-0.8-dev

Run `meson build` to configure the build environment and run `ninja test` to build and run automated tests

```
meson build --prefix=/usr
cd build
ninja test
```

To install, use `ninja install`, then execute with `com.github.jeremyvaartjes.subminder`

```
sudo ninja install
com.github.jeremyvaartjes.subminder
```
