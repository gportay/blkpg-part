/*
 * Copyright 2018,2021,2024 Gaël PORTAY
 *                     2024 Rtone.
 *                     2021 Collabora Ltd.
 *                     2018 Savoir-Faire Linux Inc.
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

/*
 * Initial work of Boris Brezillon <boris.brezillon@free-electrons.com>
 */

#ifdef VERSION_STRING
const char VERSION[] = VERSION_STRING;
#else
const char VERSION[] = __DATE__ " " __TIME__;
#endif /* VERSION_STRING */

#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <getopt.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <linux/blkpg.h>

struct options_t {
	char *volname;
};

static inline const char *applet(const char *arg0)
{
	char *s = strrchr(arg0, '/');
	if (!s)
		return arg0;

	return s+1;
}

static inline char *strncpy_null(char *dest, char *src, size_t n)
{
	char *ret;

	if (!dest || !src || !n) {
		errno = EINVAL;
		return NULL;
	}

	ret = strncpy(dest, src, n-1);
	ret[n-1] = 0;
	return ret;
}

void usage(FILE * f, char * const arg0)
{
	fprintf(f, "Usage: %s [OPTIONS] add|resize DEVNAME PNO START LENGTH\n"
		   "       %s [OPTIONS] delete     DEVNAME PNO\n"
		   "\n"
		   "DEVNAME: partition name, like sda5 or c0d1p2, to be used in kernel messages.\n"
		   "PNO:     partition number.\n"
		   "START:   starting offset in bytes.\n"
		   "LENGTH:  length in bytes.\n"
		   "\n"
		   "Options:\n"
		   " -l or --volume-name LABEL      Set volume label.\n"
		   " -h or --help                   Display this message.\n"
		   " -V or --version                Display the version.\n"
		   "", applet(arg0), applet(arg0));
}

int parse_arguments(struct options_t *opts, int argc, char * const argv[])
{
	static const struct option long_options[] = {
		{ "volume-name", required_argument, NULL, 'l' },
		{ "version",     no_argument,       NULL, 'V' },
		{ "help",        no_argument,       NULL, 'h' },
		{ NULL,          no_argument,       NULL, 0   }
	};

	for (;;) {
		int index;
		int c = getopt_long(argc, argv, "l:Vh", long_options, &index);
		if (c == -1) {
			break;
		}

		switch (c) {
		case 'l':
			opts->volname = optarg;
			break;

		case 'V':
			printf("%s\n", VERSION);
			exit(EXIT_SUCCESS);
			break;

		case 'h':
			usage(stdout, argv[0]);
			exit(EXIT_SUCCESS);
			break;

		case '?':
			exit(EXIT_FAILURE);
			break;

		default:
			fprintf(stderr, "Error: Illegal option code 0x%x!\n", c);
			exit(EXIT_FAILURE);
		}
	}

	return optind;
}

int main(int argc, char * const argv[])
{
	static struct options_t options;
	static struct blkpg_partition data;
	static struct blkpg_ioctl_arg req = {
		.datalen = sizeof(data),
		.data = &data,
	};
	int argi, fd, ret = EXIT_FAILURE;
	char *e;
	long l;

	argi = parse_arguments(&options, argc, argv);
	if (argi < 0) {
		fprintf(stderr, "Error: Invalid argument!\n");
		exit(EXIT_FAILURE);
	} else if (argc - argi < 3) {
		usage(stdout, argv[0]);
		fprintf(stderr, "Error: Too few arguments!\n");
		exit(EXIT_FAILURE);
	} else if (argc - argi > 5) {
		usage(stdout, argv[0]);
		fprintf(stderr, "Error: Too many arguments!\n");
		exit(EXIT_FAILURE);
	}

	if (!strcmp("add", argv[argi])) {
		req.op = BLKPG_ADD_PARTITION;
	} else if (!strcmp("delete", argv[argi])) {
		req.op = BLKPG_DEL_PARTITION;
	} else if (!strcmp("resize", argv[argi])) {
		req.op = BLKPG_RESIZE_PARTITION;
	} else {
		usage(stdout, argv[0]);
		fprintf(stderr, "Error: %s: Invalid operation!\n", argv[argi]);
		exit(EXIT_FAILURE);
	}

	if ((req.op == BLKPG_ADD_PARTITION) ||
	    (req.op == BLKPG_RESIZE_PARTITION)) {
		if (argc - argi < 5) {
			usage(stdout, argv[0]);
			fprintf(stderr, "Error: Too few arguments!\n");
			exit(EXIT_FAILURE);
		}
	}

	argi++;
	strncpy_null(data.devname, argv[argi], BLKPG_DEVNAMELTH);

	if (options.volname)
		strncpy_null(data.volname, options.volname, BLKPG_VOLNAMELTH);

	fd = open(data.devname, O_RDWR);
	if (fd == -1) {
		perror("open");
		exit(EXIT_FAILURE);
	}

	argi++;
	l = strtol(argv[argi], &e, 0);
	if (*e) {
		fprintf(stderr, "Error: %s: Invalid argument!\n",
			argv[argi]);
		ret = EXIT_FAILURE;
		goto exit;
	}
	data.pno = l;

	if ((req.op == BLKPG_ADD_PARTITION) ||
	    (req.op == BLKPG_RESIZE_PARTITION)) {
		argi++;
		l = strtol(argv[argi], &e, 0);
		if (*e) {
			fprintf(stderr, "Error: %s: Invalid argument!\n",
				argv[argi]);
			ret = EXIT_FAILURE;
			goto exit;
		}
		data.start = l;

		argi++;
		l = strtol(argv[argi], &e, 0);
		if (*e) {
			fprintf(stderr, "Error: %s: Invalid argument!\n",
				argv[argi]);
			ret = EXIT_FAILURE;
			goto exit;
		}
		data.length = l;
	}

	if (ioctl(fd, BLKPG, &req)) {
		perror("ioctl");
		ret = EXIT_FAILURE;
		goto exit;
	}

	ret = EXIT_SUCCESS;

exit:
	if (fd != -1)
		if (close(fd) == -1)
			perror("close");

	return ret;
}
