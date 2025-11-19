/*
 *  
 *
 * Copyright (C) 2019
 * Authors: Wen Wang <wen.wang.ww349@yale.edu>
 *          Ruben Niederhagen <ruben@polycephaly.org>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
*/

#include <stdint.h>
#include <string.h>

#include <mbedtls/sha256.h>

int main()
{
  unsigned char data[500] = {1,2,3,4,5};

  unsigned char *d = data;

  size_t n = 96;
  unsigned char digest[32];

  unsigned char *md = digest;

//  mbedtls_sha256_init( &ctx );

  printf("SHA test\n");

  for (int j = 0; j < 1; j++)
  {
    mbedtls_sha256(d, n, md, 0);

//    if (digest[0] != 0x74) {
      for (int i = 0; i < 32; i++)
        printf("%02x", digest[i]);

      printf("\n");
//    }


    mbedtls_sha256(d, n+32, md, 0);

//    if (digest[0] != 0x58) {
      for (int i = 0; i < 32; i++)
        printf("%02x", digest[i]);

      printf("\n");
//    }
  }

  printf("SHA test done \n\n");
}

