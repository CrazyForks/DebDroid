// test_random/src/main.c
#define _GNU_SOURCE
#include <stdio.h>
#include <unistd.h>
#include <sys/syscall.h>
#include <linux/random.h>
#include <errno.h>
#include <string.h>
#include <stdint.h>
#include <stdlib.h>

// Prints a byte buffer in hex format
static void print_hex(const unsigned char *buf, size_t len)
{
    for (size_t i = 0; i < len; ++i)
        printf("%02x ", buf[i]);
}

int main(void)
{
    const size_t n = 16;
    unsigned char buf[n];

    // 1. syscall(SYS_getrandom)
    ssize_t ret = syscall(SYS_getrandom, buf, n, 0);
    if (ret < 0) {
        fprintf(stderr, "getrandom failed: %s\n", strerror(errno));
        return EXIT_FAILURE;
    }
    printf("syscall(SYS_getrandom) -> ");
    print_hex(buf, n);
    printf("\n");

    // 2. getentropy()
    ret = getentropy(buf, n);
    if (ret != 0) {
        fprintf(stderr, "getentropy failed: %s\n", strerror(errno));
        return EXIT_FAILURE;
    }
    printf("getentropy()-> ");
    print_hex(buf, n);
    printf("\n");

    // 3. arc4random_buf
    arc4random_buf(buf, n);
    printf("arc4random_buf() -> ");
    print_hex(buf, n);
    printf("\n");

    // 4. arc4random
    uint32_t r32 = arc4random();
    printf("arc4random() -> %08x\n", r32);

    // 5. arc4random_uniform
    uint32_t bound = 100;
    uint32_t uniform = arc4random_uniform(bound);
    printf("arc4random_uniform(%u) -> %u\n", bound, uniform);

    return EXIT_SUCCESS;
}