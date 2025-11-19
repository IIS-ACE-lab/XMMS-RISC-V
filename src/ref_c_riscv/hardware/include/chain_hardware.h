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

#ifndef CHAIN_HARDWARE_H
#define CHAIN_HARDWARE_H
 
#include <stddef.h>
#include <stdint.h>

#define CONTROL_BIT 2 // address offset = 8
#define DATA_BIT 4 // address offset = 16
#define START 1  
#define BUSY 1
#define CMD_BIT 1
#define BUSY_BIT 1
 
/**
 * \brief          This function communicates with the wots hardware core.
 * \input          start, data_in, pub_seed and hash_addr
 * \return         data_out, hash_addr
**/

int chain_hardware( const unsigned char *data_in,
                    const unsigned char *pub_seed,
                    const uint32_t start,
                    const uint32_t steps,
                    unsigned char *hash_addr,
                    unsigned char *data_out);
                    
#endif /* chain_hardware.h */
