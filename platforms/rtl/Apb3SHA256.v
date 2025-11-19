/*
 * Function: bridge module
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

module Apb3HW (
      input  wire [6:0]  io_apb_PADDR,
      input  wire [0:0]  io_apb_PSEL,
      input  wire        io_apb_PENABLE,
      output wire        io_apb_PREADY,
      input  wire        io_apb_PWRITE,
      input  wire [31:0] io_apb_PWDATA,
      output reg  [31:0] io_apb_PRDATA,
      output wire        io_apb_PSLVERROR,
      input  wire        io_mainClk,
      input  wire        io_systemReset
);

  wire [255:0] output_data;
  wire         module_busy;
  reg [511:0] input_data_reg;
  reg         sha256_start;
  reg         sha256_init_message;
  reg         sha256_init_iv;
  reg [2:0]   cmd_reg;
 

  wire  ctrl_doWrite;  
  
  assign io_apb_PREADY = 1'b1;
  assign io_apb_PSLVERROR = 1'b0; 
  assign ctrl_doWrite = (((io_apb_PSEL[0] && io_apb_PENABLE) && io_apb_PREADY) && io_apb_PWRITE);  
 
  always @ (*) begin
    io_apb_PRDATA = (32'd0);
    case(io_apb_PADDR) 

    7'b0000100 : begin
      io_apb_PRDATA[31 : 0] = {{31 {1'b0}}, module_busy};
      end
     
    7'b0010000 : begin
      io_apb_PRDATA[31 : 0] = {output_data[231:224], output_data[239:232], output_data[247:240], output_data[255:248]}; 
      end

    7'b0010100 : begin
      io_apb_PRDATA[31 : 0] = {output_data[199:192], output_data[207:200], output_data[215:208], output_data[223:216]}; 
      end

    7'b0011000 : begin
      io_apb_PRDATA[31 : 0] = {output_data[167:160], output_data[175:168], output_data[183:176], output_data[191:184]}; 
      end

    7'b0011100 : begin
      io_apb_PRDATA[31 : 0] = {output_data[135:128], output_data[143:136], output_data[151:144], output_data[159:152]}; 
      end

    7'b0100000 : begin
      io_apb_PRDATA[31 : 0] = {output_data[103:96], output_data[111:104], output_data[119:112], output_data[127:120]}; 
      end

    7'b0100100 : begin
      io_apb_PRDATA[31 : 0] = {output_data[71:64], output_data[79:72], output_data[87:80], output_data[95:88]}; 
      end

    7'b0101000 : begin
      io_apb_PRDATA[31 : 0] = {output_data[39:32], output_data[47:40], output_data[55:48], output_data[63:56]}; 
      end

    7'b0101100 : begin
      io_apb_PRDATA[31 : 0] = {output_data[7:0], output_data[15:8], output_data[23:16], output_data[31:24]}; 
      end

    default : begin
      end
    endcase
  end 


  always @ (posedge io_mainClk or posedge io_systemReset) begin
    if (io_systemReset) begin 
      input_data_reg <= {512{1'b0}};
      sha256_init_message <= 1'b0;
      sha256_start <= 1'b0;
      sha256_init_iv <= 1'b0;
      cmd_reg <= 3'b000;
    end else begin
      // make sure: important signals sha256_init_message, sha256_start and sha256_init_iv are only one clock high
      sha256_init_message <= 1'b0;
      sha256_start <= 1'b0;
      sha256_init_iv <= 1'b0;

      case(io_apb_PADDR) 

        7'b0000100 : begin
                      if(ctrl_doWrite) begin 
                        sha256_init_message <= io_apb_PWDATA[0];  
                        sha256_start <= io_apb_PWDATA[1];  
                        sha256_init_iv <= io_apb_PWDATA[2]; 
                        cmd_reg <= (io_apb_PWDATA[10:8] == 3'd0) ? cmd_reg : io_apb_PWDATA[10:8];
                      end
                    end
         
        7'b0010000 : begin
                      if(ctrl_doWrite) begin
                         input_data_reg[511:480] <= {io_apb_PWDATA[7:0], io_apb_PWDATA[15:8], io_apb_PWDATA[23:16], io_apb_PWDATA[31:24]};
                      end
                    end

        7'b0010100 : begin
                      if(ctrl_doWrite) begin
                         input_data_reg[479:448] <= {io_apb_PWDATA[7:0], io_apb_PWDATA[15:8], io_apb_PWDATA[23:16], io_apb_PWDATA[31:24]};
                      end
                    end

        7'b0011000 : begin
                      if(ctrl_doWrite) begin
                         input_data_reg[447:416] <= {io_apb_PWDATA[7:0], io_apb_PWDATA[15:8], io_apb_PWDATA[23:16], io_apb_PWDATA[31:24]};
                      end
                    end

        7'b0011100 : begin
                      if(ctrl_doWrite) begin
                         input_data_reg[415:384] <= {io_apb_PWDATA[7:0], io_apb_PWDATA[15:8], io_apb_PWDATA[23:16], io_apb_PWDATA[31:24]};
                      end
                    end

        7'b0100000 : begin
                      if(ctrl_doWrite) begin
                         input_data_reg[383:352] <= {io_apb_PWDATA[7:0], io_apb_PWDATA[15:8], io_apb_PWDATA[23:16], io_apb_PWDATA[31:24]};
                      end
                    end

        7'b0100100 : begin
                      if(ctrl_doWrite) begin
                         input_data_reg[351:320] <= {io_apb_PWDATA[7:0], io_apb_PWDATA[15:8], io_apb_PWDATA[23:16], io_apb_PWDATA[31:24]};
                      end
                    end

        7'b0101000 : begin
                      if(ctrl_doWrite) begin
                         input_data_reg[319:288] <= {io_apb_PWDATA[7:0], io_apb_PWDATA[15:8], io_apb_PWDATA[23:16], io_apb_PWDATA[31:24]};
                      end
                    end

        7'b0101100 : begin
                      if(ctrl_doWrite) begin
                         input_data_reg[287:256] <= {io_apb_PWDATA[7:0], io_apb_PWDATA[15:8], io_apb_PWDATA[23:16], io_apb_PWDATA[31:24]};
                      end
                    end

        7'b0110000 : begin
                      if(ctrl_doWrite) begin
                         input_data_reg[255:224] <= {io_apb_PWDATA[7:0], io_apb_PWDATA[15:8], io_apb_PWDATA[23:16], io_apb_PWDATA[31:24]};
                      end
                    end

        7'b0110100 : begin
                      if(ctrl_doWrite) begin
                         input_data_reg[223:192] <= {io_apb_PWDATA[7:0], io_apb_PWDATA[15:8], io_apb_PWDATA[23:16], io_apb_PWDATA[31:24]};
                      end
                    end

        7'b0111000 : begin
                      if(ctrl_doWrite) begin
                         input_data_reg[191:160] <= {io_apb_PWDATA[7:0], io_apb_PWDATA[15:8], io_apb_PWDATA[23:16], io_apb_PWDATA[31:24]};
                      end
                    end

        7'b0111100 : begin
                      if(ctrl_doWrite) begin
                         input_data_reg[159:128] <= {io_apb_PWDATA[7:0], io_apb_PWDATA[15:8], io_apb_PWDATA[23:16], io_apb_PWDATA[31:24]};
                      end
                    end

        7'b1000000 : begin
                      if(ctrl_doWrite) begin
                         input_data_reg[127:96] <= {io_apb_PWDATA[7:0], io_apb_PWDATA[15:8], io_apb_PWDATA[23:16], io_apb_PWDATA[31:24]};
                      end
                    end

        7'b1000100 : begin
                      if(ctrl_doWrite) begin
                         input_data_reg[95:64] <= {io_apb_PWDATA[7:0], io_apb_PWDATA[15:8], io_apb_PWDATA[23:16], io_apb_PWDATA[31:24]};
                      end
                    end

        7'b1001000 : begin
                      if(ctrl_doWrite) begin
                         input_data_reg[63:32] <= {io_apb_PWDATA[7:0], io_apb_PWDATA[15:8], io_apb_PWDATA[23:16], io_apb_PWDATA[31:24]};
                      end
                    end

        7'b1001100 : begin
                      if(ctrl_doWrite) begin
                         input_data_reg[31:0] <= {io_apb_PWDATA[7:0], io_apb_PWDATA[15:8], io_apb_PWDATA[23:16], io_apb_PWDATA[31:24]}; 
                      end
                    end

        default : begin
        end
      endcase
    end
  end

  sha256_wrapper sha256_wrapper_inst (
    .io_mainClk(io_mainClk),
    .io_systemReset(io_systemReset),
    .output_data(output_data),
    .module_busy(module_busy),
    .input_data_reg(input_data_reg),
    .sha256_start(sha256_start),
    .sha256_init_message(sha256_init_message),
    .sha256_init_iv(sha256_init_iv),
    .cmd_reg(cmd_reg)
  );

endmodule
