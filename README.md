# blkpg-part

Partition table and disk geometry handling utility

## TL;DR;

[blkpg-part(1)] creates _temporary partitions_ that are not part of the _MBR_.
It makes a _partition block device_ from any _consecutive blocks_ that are _not
partitioned_.

## DESCRIPTION

[blkpg-part(1)] creates, resizes and deletes _partitions_ on the fly without
writing back the changes to the _partition table_.

Under the hood, [blkpg-part(1)] uses the three following *ioctl(3P)* from the
_header_ [linux/blkpg.h]:

* *BLKPG_ADD_PARTITION*
* *BLKPG_DEL_PARTITION*
* *BLKPG_RESIZE_PARTITION*

Thanks to [blkpg-part(1)], it is possible to export any _consecutive blocks_,
that are not already part of a _partition_, as a _temporary partitioned_
block device.

A typically use case in _embedded systems_ is to export hidden _blobs_ that are
stored in _raw_ in block devices (i.e. _blobs_ that are not stored into a
_file-system_).

### CREATE PARTITION

The creation of a _temporary partition_ takes:

1. the _block device_ (ex. _/dev/mmcblk0_)
1. an arbitrary _partition number_ (ex. _100_)
1. the _offset_ and the _length_ of the desired _partition_ in _bytes_\[\*\].

Only _consecutive blocks_ that are _not_ a part of an existing _partition_ can
create a _partition_.

\[\*\]: Both _offsets_ and _sizes_ are expressed in _bytes_ and should be a
_multiple_ of _block size_ (_512 Bytes_).

#### CREATE EXAMPLE

A _dummy_ example for _DOS partition scheme devices_ is to create a _partition_
that exports the _MBR_:

``` bash
# blkpg-part add /dev/mmcblk0 100 0 512
# hexdump -C /dev/mmcblk0p100
00000000  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
*
000001b0  00 00 00 00 00 00 00 00  00 00 00 00 00 00 xx xx  |................|
000001c0  xx xx xx xx xx xx xx xx  xx xx xx xx xx xx xx xx  |................|
000001d0  xx xx xx xx xx xx xx xx  xx xx xx xx xx xx xx xx  |................|
000001e0  xx xx xx xx xx xx xx xx  xx xx xx xx xx xx xx xx  |................|
000001f0  xx xx xx xx xx xx xx xx  xx xx xx xx xx xx 55 aa  |..............U.|
00000200
```

### DELETE PARTITION

The deletion of an _existing partition_ takes:

1. the _block device_ (ex. _/dev/mmcblk0_)
1. the _partition number_ (ex. _1_ or _100_)

Both _temporary partition_ and _partition_ from the _partition table_ can be
deleted.

#### DELETE EXAMPLES

A _dummy_ example for _DOS partition scheme devices_ is to delete the recently
created _temporary partition_ that exports the _MBR_:

``` bash
# blkpg-part delete /dev/mmcblk0 100
# hexdump -C /dev/mmcblk0p100
hexdump: /dev/mmcblk0p100: No such file or directory
hexdump: all input file arguments failed
```

Another example is to delete the existing first _partition_ from the _partition
table_:

``` bash
# blkpg-part delete /dev/mmcblk0 1
# hexdump -C /dev/mmcblk0p1
hexdump: /dev/mmcblk0p1: No such file or directory
hexdump: all input file arguments failed
```

## CONCRETE EXAMPLE

Here is a simple _DOS partition scheme_ on an _SD-Card_ where there is space
that is not _partitioned_ at the beginning of the _disk_; between the _MBR_ and
the first partition (_Boot_).

 Partition | Offset      | Length       | Device name
 --------- | ----------- | ------------ | -------------
 MBR       |     0       |     1 (512B) | -
 (empty)   |     1       |  8191  (4MB) | -
 Boot      |  8192  (4M) |  8192  (4MB) | /dev/mmcblkp1
 RootFS    | 16384  (8M) | 16384  (8MB) | /dev/mmcblkp2
 Data      | 32768 (16M) | -            | /dev/mmcblkp3

This kind of scheme is common on _embedded devices_. This _empty_ space usually
hides _blobs_ specific to the _SoC_ such as _bootloaders_ stored in _raw format_
\[1\] into the _block device_.

Those _blobs_ are generally _dd'ed_ at a very specific _offset_ which depends
on the _ROMCode_\[2\] of the _SoC_ in use.

The _ROMCode_ of _TI AM335x SoCs_ loads a _second stage bootloader_ that loads
a _third stage bootloader_ that loads the _operating system_.

This very first piece of software is called _MLO_ and must be stored at
_offset_ _0_ on the _booting device_. It can also be duplicated at offsets
_0x20000_, _0x40000_ and _0x60000_\[3\].

_Note_: Because of this example is using a _DOS partition scheme_, the _MLO_
cannot be placed at _offset 0_, otherwise it overrides the _DOS partition
table_.

``` bash
# dd if=MLO of=/dev/mmcblk0 skip=$((0x20000))
# dd if=MLO of=/dev/mmcblk0 skip=$((0x40000))
# dd if=MLO of=/dev/mmcblk0 skip=$((0x60000))
```

It offers two advantages:

1. It is not necessary to remember the precise _offset_: the new created _block
   device_ knows where to start.
1. If the _blob_ to _dd_ is _bigger_ than expected, the copy does not override
   the following partition: the new created _block device_ knows where to stop.

``` bash
# dd if=MLO of=/dev/mmcblk0p101
# dd if=MLO of=/dev/mmcblk0p102
# dd if=MLO of=/dev/mmcblk0p103
```

\[1\]: The _raw_ format is to opposed to _file-system_ where the _blob_ is
easily identifiable using a human readable identifier (_filename_).

\[2\]: The _ROMCode_ is the _bootloader_ that is _hardcoded_ inside the _SoC_.
Its goal is to load the _first_ piece of software that will be run by the
_CPU_. It is usually referenced as the _first stage bootloader_.

\[3\]: The _ROMCode_ of _TI AM335x SoCs_ allows the _MLO_ to be stored in a
_FAT_ partition. But this case does not illustrate how _blkpg-part_ can be
useful in such situation.

## UDEV RULES

[udev(7)] automates the creation of a _temporary partition_ via static rules by
_RUN_-ing [blkpg-part(1)] matching the name of a non-deleted block device.

An example of an [udev rule] is available in in the in the `support` directory.

## EMBEDDED BUILD SYSTEMS

[blkpg-part(1)] is neither a part of [Buildroot] nor [OpenEmbedded]. However, a
[Buildroot package] and a [Bitbake recipe] are available in the `support`
directory, as well as structures for a [Buildroot br2-external] in `support/br2`
and an [OpenEmbedded layer] in `support/oe/meta-blkpg-part`.

## PATCHES

Sumbit patches at <https://github.com/gportay/blkpg-part/pulls>

## BUGS

Report bugs at <https://github.com/gportay/blkpg-part/issues>

## AUTHOR

Written by Gaël PORTAY <gael.portay@gmail.com>

## COPYRIGHT

Copyright 2018,2021,2024 Gaël PORTAY
                    2024 Rtone.
                    2021 Collabora Ltd.
                    2018 Savoir-Faire Linux Inc.

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU Lesser General Public License as published by the Free
Software Foundation, either version 2.1 of the License, or (at your option) any
later version.

## SEE ALSO

[ioctl(3P)]

[blkpg-part(1)]: blkpg-part.1.adoc "Go to the Manual page"
[linux/blkpg.h]: https://raw.githubusercontent.com/torvalds/linux/master/include/uapi/linux/blkpg.h "See linux/blkpg.h content"
[Buildroot]: https://buildroot.org/ "Go to Buildroot website"
[OpenEmbedded]: http://www.openembedded.org/ "Go to OpenEmbedded website"
[Buildroot package]: support/blkpg-part.mk "See the Buildroot Package content"
[Bitbake recipe]: support/blkpg-part.bb "See the Bitbake Recipe content"
[Buildroot br2-external]: support/br2 "See the Buildroot br2-external structure"
[OpenEmbedded layer]: support/oe "See the OpenEmbedded Layer structure"
[ioctl(3P)]: https://linux.die.net/man/3/ioctl
[udev(7)]: https://man7.org/linux/man-pages/man7/udev.7.html "Go to the Manual page"
[udev rule]: support/90-blkpg-part.rules#L27 "See an example of udev rule content"
