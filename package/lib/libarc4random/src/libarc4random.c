// arc4random.c
#include <errno.h>
#include <stddef.h>
#include <stdint.h>
#include <string.h>
#include <unistd.h>

// Provides a hardened stub implementation for arc4random_buf
void arc4random_buf(void *p, size_t n)
{
    // Prevents leaking uninitialized data
    // Returns a zero-filled buffer in case of error
    int res = getentropy(p, n);
    if (res != 0)
        memset(p, 0, n);
}

// Provides a stub implementation for arc4random_buf
uint32_t arc4random(void)
{
    uint32_t r;
    arc4random_buf(&r, sizeof(r));
    return r;
}

// Provides a stub implementation for arc4random_uniform
/* NOTES:
 *   - Provides a uniform bounded random number without modulo bias
 *   - Implements the rejection‑sampling algorithm used by OpenBSD
 */
uint32_t arc4random_uniform(uint32_t bound)
{
    if (bound == 0)
        return 0; // consistent with BSD behaviour

    // Calculates the smallest multiple of bound that fits in a uint32_t
    // Values >= limit will be rejected to avoid bias
    uint32_t limit = UINT32_MAX - (UINT32_MAX % bound);
    for (;;) {
        uint32_t r = arc4random();
        if (r < limit)
            return r % bound;
    }
}