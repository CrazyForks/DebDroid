// test_random
#define _GNU_SOURCE
#include <stdio.h>
#include <unistd.h>
#include <sys/syscall.h>
#include <linux/random.h>
#include <errno.h>
#include <string.h>

ssize_t getrandom_wrapper(void *buf, size_t buflen, unsigned int flags) {
    return syscall(SYS_getrandom, buf, buflen, flags);
}

int main() {
    unsigned char buffer[16]; // 16 random bytes

    ssize_t ret = getrandom_wrapper(buffer, sizeof(buffer), 0);
    if (ret < 0) {
        fprintf(stderr, "getrandom failed: %s\n", strerror(errno));
        return 1;
    }

    printf("Random bytes: ");
    for (size_t i = 0; i < sizeof(buffer); i++) {
        printf("%02x ", buffer[i]);
    }
    printf("\n");

    return 0;
}

