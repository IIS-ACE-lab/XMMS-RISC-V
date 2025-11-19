/*
 * Function: bridge module
 *
 * Copyright (C) 2019
 * Authors: Ruben Niederhagen <ruben@polycephaly.org>
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

module BlockRam
#(
  parameter DATA_WIDTH = 10,
  parameter ADDR_WIDTH = 8
)
(
  input  wire                  clk,
  input  wire [DATA_WIDTH-1:0] din,
  input  wire [ADDR_WIDTH-1:0] addr,
  input  wire                  we,
  output reg  [DATA_WIDTH-1:0] dout
);

  localparam SIZE = 2**ADDR_WIDTH;

  reg [DATA_WIDTH-1:0] mem [0:SIZE-1];

  always @ (posedge clk)
  begin
    if (we)
      mem[addr] <= din;
  end

  always @ (posedge clk)
  begin
    dout <= mem[addr];
  end

endmodule

