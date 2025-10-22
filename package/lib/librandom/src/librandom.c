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

static ssize_t urandom_read(void *buf, size_t buflen)
{
    int fd = open("/dev/urandom", O_RDONLY);
    if (fd < 0)
    {
        return -1;
    }

    size_t total = 0;
    while (total < buflen)
    {
        ssize_t n = read(fd, (unsigned char *)buf + total, buflen - total);
        if (n < 0)
        {
            if (errno == EINTR)
            {
                continue; // retry
            }
            close(fd);
            return -1;
        }
        if (n == 0)
        {
            close(fd);
            errno = EIO;
            return -1;
        }
        total += n;
    }

    close(fd);
    return (ssize_t)total;
}

typedef long (*syscall_t)(long number, ...);

long syscall(long number, ...)
{
    static syscall_t real_syscall = NULL;
    if (!real_syscall)
    {
        real_syscall = (syscall_t)dlsym(RTLD_NEXT, "syscall");
    }

    if (number == SYS_getrandom)
    {
        void *buf;
        size_t buflen;
        unsigned int flags;
        va_list args;
        va_start(args, number);
        buf = va_arg(args, void *);
        buflen = va_arg(args, size_t);
        flags = va_arg(args, unsigned int);
        va_end(args);

        return urandom_read(buf, buflen);
    }

    va_list args;
    va_start(args, number);
    long a1 = va_arg(args, long);
    long a2 = va_arg(args, long);
    long a3 = va_arg(args, long);
    long a4 = va_arg(args, long);
    long a5 = va_arg(args, long);
    long a6 = va_arg(args, long);
    va_end(args);

    // Correctly forwards variadic arguments
    // syscall accepts up to 6 arguments
    return real_syscall(number, a1, a2, a3, a4, a5, a6);
}

int getentropy(void *buf, size_t buflen)
{
    if (buflen > 256)
    {
        errno = EIO;
        return -1;
    }
    ssize_t ret = urandom_read(buf, buflen);
    return ret == (ssize_t)buflen ? 0 : -1;
}
