/*
 *  Copyright (C) 2018 Savoir-Faire Linux Inc.
 *
 *  Authors:
 *       Gaël PORTAY <gael.portay@savoirfairelinux.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include <stdio.h>
#include <stdarg.h>
#include <errno.h>
#include <fcntl.h>
#include <linux/blkpg.h>

int open(const char *filename, int flags, ...)
{
	mode_t mode = 0;
	va_list ap;
	va_start(ap, flags);
	mode = va_arg(ap, mode_t);
	va_end(ap);

	printf("%s_filename=\"%s\"\n", __FUNCTION__, filename);
	printf("%s_flags=0x%x\n", __FUNCTION__, flags);
	printf("%s_mode=0x%x\n", __FUNCTION__, mode);

	return 127;
}

int close(int fd)
{
	printf("%s_fd=%i\n", __FUNCTION__, fd);

	if (fd < 0) {
		errno = EINVAL;
		return -1;
	}

	return 0;
}

int ioctl(int fd, int req, ...)
{
	printf("%s_fd=%i\n", __FUNCTION__, fd);
	printf("%s_req=%i\n", __FUNCTION__, req);

	if (fd < 0) {
		errno = EINVAL;
		return -1;
	}

	if (req == BLKPG) {
		struct blkpg_ioctl_arg *arg1;

		va_list ap;
		va_start(ap, req);
		arg1 = va_arg(ap, struct blkpg_ioctl_arg *);
		va_end(ap);

		printf("%s_arg1_op=0x%x\n", __FUNCTION__, arg1->op);
		printf("%s_arg1_flags=0x%x\n", __FUNCTION__, arg1->flags);
		printf("%s_arg1_datalen=%i\n", __FUNCTION__, arg1->datalen);

		printf("%s_arg1_op=0x%x\n", __FUNCTION__, arg1->op);
		printf("%s_arg1_flags=0x%x\n", __FUNCTION__, arg1->flags);
		printf("%s_arg1_datalen=%i\n", __FUNCTION__, arg1->datalen);
		printf("%s_arg1_data_start=%lli\n", __FUNCTION__, ((struct blkpg_partition *)arg1->data)->start);
		printf("%s_arg1_data_length=%lli\n", __FUNCTION__, ((struct blkpg_partition *)arg1->data)->length);
		printf("%s_arg1_data_pno=%i\n", __FUNCTION__, ((struct blkpg_partition *)arg1->data)->pno);
		printf("%s_arg1_data_devname=\"%s\"\n", __FUNCTION__, ((struct blkpg_partition *)arg1->data)->devname);
		printf("%s_arg1_data_volname=\"%s\"\n", __FUNCTION__, ((struct blkpg_partition *)arg1->data)->volname);

		return 0;
	}

	errno = EINVAL;
	return -1;
}
