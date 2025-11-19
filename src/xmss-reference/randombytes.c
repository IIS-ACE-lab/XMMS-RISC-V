/*
This code was taken from the SPHINCS reference implementation and is public domain.
*/

#include <fcntl.h>
#include <unistd.h>

#include <stdint.h>

unsigned long long x = 88172645463325252LL;

unsigned long long xor64()
{
  x^=(x<<13);
  x^=(x>>7);
  return (x^=(x<<17));
}

void randombytes(unsigned char *x, unsigned long long xlen)
{
  for (unsigned long long i = 0; i < xlen; i++)
  {
    uint64_t val = xor64();

    x[i] = val ^ (val >> 8) ^ (val >> 16) ^ (val >> 24);
  }
}

//static int fd = -1;
//
//void randombytes(unsigned char *x, unsigned long long xlen)
//{
//    int i;
//
//    if (fd == -1) {
//        for (;;) {
//            fd = open("/dev/urandom", O_RDONLY);
//            if (fd != -1) {
//                break;
//            }
//            sleep(1);
//        }
//    }
//
//    while (xlen > 0) {
//        if (xlen < 1048576) {
//            i = xlen;
//        }
//        else {
//            i = 1048576;
//        }
//
//        i = read(fd, x, i);
//        if (i < 1) {
//            sleep(1);
//            continue;
//        }
//
//        x += i;
//        xlen -= i;
//    }
//}

