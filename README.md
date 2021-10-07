# blkpg-part

Partition table and disk geometry handling utility

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
1. the _offset_ and the _length_ of the desired _partition_ in _bytes_[*].

Only _consecutive blocks_ that are _not_ a part of an existing _partition_ can
create a _partition_.

### DELETE PARTITION

The deletion of an _existing partition_ takes:

1. the _block device_ (ex. _/dev/mmcblk0_)
1. the _partition number_ (ex. _1_ or _100_)

Both _temporary partition_ and _partition_ from the _partition table_ can be
deleted.

## EMBEDDED BUILD SYSTEMS

[blkpg-part(1)] is neither a part of [Buildroot] nor [OpenEmbedded]. However, a
[Buildroot package] and a [Bitbake recipe] are available in the `support`
directory, as well as structures for a [Buildroot br2-external] in `support/br2`
and an [OpenEmbedded layer] in `support/oe/meta-blkpg-part`.

## BUGS

Report bugs at <https://github.com/gportay/blkpg-part/issues>

## AUTHOR

Written by Gaël PORTAY <gael.portay@gmail.com>

## COPYRIGHT

Copyright (c) 2018 Gaël PORTAY

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, version 2.

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

[*]: Both _offsets_ and _sizes_ are expressed in _bytes_ and should be a
_multiple_ of _block size_ (_512 Bytes_).
