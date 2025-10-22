#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <sys/param.h>
#include <sys/random.h>
#include <fcntl.h>
#include <stdatomic.h>
#include <poll.h>
#include <string.h>
#include <stdint.h>
#include <unistd.h>

void arc4random_buf(void *p, size_t n)
{
  if (n == 0)
    return;
  getentropy(p, n);
}

uint32_t
arc4random(void)
{
  uint32_t r;
  arc4random_buf(&r, sizeof(r));
  return r;
}

uint32_t arc4random_uniform(uint32_t upper_bound)
{
  if (upper_bound == 0)
    return 0;
  return arc4random() % upper_bound;
}
