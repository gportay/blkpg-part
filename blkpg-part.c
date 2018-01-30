/*
 *            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
 *                    Version 2, December 2004
 *
 * Copyright (C) 2004 Sam Hocevar <sam@hocevar.net>
 *
 * Everyone is permitted to copy and distribute verbatim or modified
 * copies of this license document, and changing it is allowed as long
 * as the name is changed.
 *
 *            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
 *   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
 *
 *  0. You just DO WHAT THE FUCK YOU WANT TO.
 */

#include <linux/blkpg.h>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <errno.h>
#include <fcntl.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>

int main(int argc, char **argv)
{
	struct blkpg_partition part = { };
	struct blkpg_ioctl_arg req = {
		.datalen = sizeof(part),
		.data = &part,
	};
	int fd, ret;

	if (argc < 4)
		goto err_invalid_arg;

	if (!strcmp("add", argv[1]))
		req.op = BLKPG_ADD_PARTITION;
	else if (!strcmp("remove", argv[1]))
		req.op = BLKPG_DEL_PARTITION;
	else
		goto err_invalid_arg;


	fd = open(argv[2], O_RDWR);
	if (fd < 0) {
		printf("failed to open block device %s (%s)\n",
		       argv[2], strerror(errno));
		return -1;
	};

	errno = 0;
	part.pno = strtoll(argv[3], NULL, 0);

	if (req.op == BLKPG_ADD_PARTITION) {
		if (argc < 6)
			goto err_invalid_arg;

		part.start = strtoll(argv[4], NULL, 0);
		part.length = strtoll(argv[5], NULL, 0);
	}

	if (errno)
		return -1;

	if (ioctl(fd, BLKPG, &req)) {
		printf("failed (err %d => %s)\n", errno, strerror(errno));
		return -1;
	}

	printf("partition %s\n",
	       req.op == BLKPG_ADD_PARTITION ? "created" : "removed");
	return 0;

err_invalid_arg:
	printf("usage:\n");
	printf("\tblkpart add|remove <blk-dev> <partno> [<blk-dev-offset> <part-size>]\n");
	return -1;
}
