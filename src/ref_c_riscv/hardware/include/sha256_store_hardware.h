/*
 * Function: bridge module
 *
 * Copyright (C) 2019
 * Authors: Wen Wang <wen.wang.ww349@yale.edu> 
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

#ifndef SHA256_STORE_HARDWARE_H
#define SHA256_STORE_HARDWARE_H


#include <stddef.h>
#include <stdint.h>

#define CONTROL_BIT 1 // address offset = 4
#define DATA_BIT 4 // address offset = 16
#define START 8  
#define BUSY 1
#define SECOND_BLOCK_AVAILABLE 2

/**
 * \brief          This function communicates with the sha256 hardware core(with store functionality).
 * \input          data_in, message_length, store_intermediate, continue_intermediate 
 * \return         data_out
**/

int sha256_store_hardware(const unsigned char *data_in, //1024-bits  
                          unsigned char message_length, //1 or 0
                          unsigned char store_intermediate, // 1 or 0
                          unsigned char continue_intermediate, // 1 or 0
                          unsigned char *data_out);

#endif /* sha256_store_hardware.h */
