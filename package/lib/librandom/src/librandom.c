// librandom.c
#define _GNU_SOURCE
#include <stdlib.h>
#include <stdarg.h>
#include <errno.h>
#include <string.h>
#include <dlfcn.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/syscall.h>
#include <pthread.h>

typedef long (*syscall_t)(long number, ...);

// Global protected state
static syscall_t real_syscall = NULL;
static pthread_once_t init_once = PTHREAD_ONCE_INIT;

// Helper state
static int urandom_fd = -1;
static pthread_mutex_t urandom_lock = PTHREAD_MUTEX_INITIALIZER;

/* NOTES:
 *   - dlsym is by itself thread‑safe
 *   - dlsym failure results in real_syscall == NULL, resulting in ENOSYS
 */
static void init_real_syscall(void)
{
    real_syscall = (syscall_t)dlsym(RTLD_NEXT, "syscall");
}


// Returns a lazily-initialized descriptor to urandom
// NOTE: The lock protects the race on fd.
static int get_urandom_fd(void)
{
    int fd = __atomic_load_n(&urandom_fd, __ATOMIC_ACQUIRE);
    if (fd >= 0)
        return fd;

    pthread_mutex_lock(&urandom_lock);
    /* Double‑check after acquiring the lock */
    fd = urandom_fd;
    if (fd < 0) {
        fd = open("/dev/urandom", O_RDONLY | O_CLOEXEC);
        if (fd >= 0)
            __atomic_store_n(&urandom_fd, fd, __ATOMIC_RELEASE);
    }
    pthread_mutex_unlock(&urandom_lock);
    return fd;
}

// Performs a safe read from urandom with robust error handling
static ssize_t urandom_read(void *buf, size_t buflen)
{
    int fd = get_urandom_fd();
    if (fd < 0)
        return -1; // propagate open() errno

    size_t total = 0;
    while (total < buflen) {
        ssize_t n = 
            read(fd, (unsigned char *)buf + total, buflen - total);

        if (n < 0) {
            if (errno == EINTR)
                continue; // retry
            return -1; // propagate errno
        }

        if (n == 0) { // sanity check, should never happen
            errno = EIO;
            return -1;
        }

        total += (size_t)n;
    }
    return (ssize_t)total;
}

// Wraps the real syscall to provide getrandom
// NOTE: The stub implementation for getrandom ignores flags
// !!! Do not use the implementation below for entropy-critical tasks such as cryptography
long syscall(long number, ...)
{
    // Ensures the real_syscall pointer is initialized exactly once
    pthread_once(&init_once, init_real_syscall);
    if (!real_syscall) {
        errno = ENOSYS;
        return -1;
    }

    // Provides a stub implementation for getrandom
    if (number == SYS_getrandom) {
        va_list ap;
        void *buf;
        size_t buflen;
        unsigned int flags;

        va_start(ap, number);
        buf   = va_arg(ap, void *);
        buflen= va_arg(ap, size_t);
        flags = va_arg(ap, unsigned int);
        va_end(ap);

        (void)flags; // Ignores flags
        return urandom_read(buf, buflen);
    }

    // Forward other syscalls while preserving arguments
    va_list ap;
    va_start(ap, number);
    long a1 = va_arg(ap, long);
    long a2 = va_arg(ap, long);
    long a3 = va_arg(ap, long);
    long a4 = va_arg(ap, long);
    long a5 = va_arg(ap, long);
    long a6 = va_arg(ap, long);
    va_end(ap);

    return real_syscall(number, a1, a2, a3, a4, a5, a6);
}

// Provides a stub implementation for getentropy
int getentropy(void *buf, size_t buflen)
{
    if (buflen > 256) {
        errno = EIO;
        return -1;
    }

    ssize_t ret = urandom_read(buf, buflen);
    return ret == (ssize_t)buflen ? 0 : -1;
}