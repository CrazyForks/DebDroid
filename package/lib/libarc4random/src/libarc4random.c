/* Pseudo Random Number Generator
   Copyright (C) 2022-2025 Free Software Foundation, Inc.
   This file is part of the GNU C Library.

   The GNU C Library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.

   The GNU C Library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with the GNU C Library; if not, see
   <https://www.gnu.org/licenses/>.  */

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

// -------------------- glibc internal replacements --------------------

#ifndef __libc_fatal
#define __libc_fatal(msg) do { fprintf(stderr, "%s", msg); } while(0)
#endif

// -------------------- glibc-internal macros --------------------
#define libc_hidden_def(sym)
#define weak_alias(old, new)

void
arc4random_buf (void *p, size_t n)
{
  if (n == 0)
    return;
  getentropy(p, n);
}

uint32_t
arc4random (void)
{
  uint32_t r;
  arc4random_buf(&r, sizeof (r));
  return r;
}

uint32_t arc4random_uniform(uint32_t upper_bound) {
    if (upper_bound == 0) return 0;
    return arc4random() % upper_bound;
}
