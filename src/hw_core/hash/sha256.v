/*
 *  
 *
 * Copyright (C) 2019
 * Authors: Bernhard Jungk <bernhard@projectstarfire.de>
 *          Wen Wang <wen.wang.ww349@yale.edu>
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

// general-purpose SHA-256 hash core

module sha256
(
  input wire clk,
  input wire reset,
  input wire start, // start signal, one clock high
  input wire init_message,  // reset state to IV
  input wire [511:0] data_in, // input data
  input wire init_iv, // compatible interface with store variant
  output wire [255:0] data_out, // output data, buffered and do not changed unless updated as the next result
  output wire data_out_valid, // stay high as long as the output is valid
  output wire done, // one clock high, done signal
  output wire busy // showing if hash function is busy or not
);

  // logic defined here:
  // ******************************

  // requirements:
  //    hash core can only be triggered when busy = 1'b0
  //    data_out changes when done is raised

  // ******************************

// registers and wires
reg [5:0] round_counter;
reg [31:0] H_reg [7:0];
reg [31:0] block [15:0];
reg [31:0] W_reg [15:0];
reg [31:0] a_reg;
reg [31:0] b_reg;
reg [31:0] c_reg;
reg [31:0] d_reg;
reg [31:0] e_reg;
reg [31:0] f_reg;
reg [31:0] g_reg;
reg [31:0] h_reg;

// state machine register and signal
parameter s_idle=0, s_processing=1;
reg current_state;

// inputs and outputs of round function
wire [31:0] W [15:0];

wire [31:0] W_sr_input;

wire [31:0] a;
wire [31:0] b;
wire [31:0] c;
wire [31:0] d;
wire [31:0] e;
wire [31:0] f;
wire [31:0] g;
wire [31:0] h;

wire [31:0] a_round_out;
wire [31:0] e_round_out;

// control signals
wire last_round;

// register for outside control signals that have to be stored
reg done_reg;
reg data_out_valid_reg;
reg busy_reg;

// constants for SHA-256
reg [31:0] constants[63:0];

  always @(posedge clk)
    begin
      if (reset)
        begin
          constants[ 0] <= 32'h428a2f98;
          constants[ 1] <= 32'h71374491;
          constants[ 2] <= 32'hb5c0fbcf;
          constants[ 3] <= 32'he9b5dba5;
          constants[ 4] <= 32'h3956c25b;
          constants[ 5] <= 32'h59f111f1;
          constants[ 6] <= 32'h923f82a4;
          constants[ 7] <= 32'hab1c5ed5;
          constants[ 8] <= 32'hd807aa98;
          constants[ 9] <= 32'h12835b01;
          constants[10] <= 32'h243185be;
          constants[11] <= 32'h550c7dc3;
          constants[12] <= 32'h72be5d74;
          constants[13] <= 32'h80deb1fe;
          constants[14] <= 32'h9bdc06a7;
          constants[15] <= 32'hc19bf174;
          constants[16] <= 32'he49b69c1;
          constants[17] <= 32'hefbe4786;
          constants[18] <= 32'h0fc19dc6;
          constants[19] <= 32'h240ca1cc;
          constants[20] <= 32'h2de92c6f;
          constants[21] <= 32'h4a7484aa;
          constants[22] <= 32'h5cb0a9dc;
          constants[23] <= 32'h76f988da;
          constants[24] <= 32'h983e5152;
          constants[25] <= 32'ha831c66d;
          constants[26] <= 32'hb00327c8;
          constants[27] <= 32'hbf597fc7;
          constants[28] <= 32'hc6e00bf3;
          constants[29] <= 32'hd5a79147;
          constants[30] <= 32'h06ca6351;
          constants[31] <= 32'h14292967;
          constants[32] <= 32'h27b70a85;
          constants[33] <= 32'h2e1b2138;
          constants[34] <= 32'h4d2c6dfc;
          constants[35] <= 32'h53380d13;
          constants[36] <= 32'h650a7354;
          constants[37] <= 32'h766a0abb;
          constants[38] <= 32'h81c2c92e;
          constants[39] <= 32'h92722c85;
          constants[40] <= 32'ha2bfe8a1;
          constants[41] <= 32'ha81a664b;
          constants[42] <= 32'hc24b8b70;
          constants[43] <= 32'hc76c51a3;
          constants[44] <= 32'hd192e819;
          constants[45] <= 32'hd6990624;
          constants[46] <= 32'hf40e3585;
          constants[47] <= 32'h106aa070;
          constants[48] <= 32'h19a4c116;
          constants[49] <= 32'h1e376c08;
          constants[50] <= 32'h2748774c;
          constants[51] <= 32'h34b0bcb5;
          constants[52] <= 32'h391c0cb3;
          constants[53] <= 32'h4ed8aa4a;
          constants[54] <= 32'h5b9cca4f;
          constants[55] <= 32'h682e6ff3;
          constants[56] <= 32'h748f82ee;
          constants[57] <= 32'h78a5636f;
          constants[58] <= 32'h84c87814;
          constants[59] <= 32'h8cc70208;
          constants[60] <= 32'h90befffa;
          constants[61] <= 32'ha4506ceb;
          constants[62] <= 32'hbef9a3f7;
          constants[63] <= 32'hc67178f2;
        end
    end


//// MUX for selecting W
assign W[ 0] = (round_counter == 0) ? block[ 0] : W_reg[ 0];
assign W[ 1] = (round_counter == 0) ? block[ 1] : W_reg[ 1];
assign W[ 2] = (round_counter == 0) ? block[ 2] : W_reg[ 2];
assign W[ 3] = (round_counter == 0) ? block[ 3] : W_reg[ 3];
assign W[ 4] = (round_counter == 0) ? block[ 4] : W_reg[ 4];
assign W[ 5] = (round_counter == 0) ? block[ 5] : W_reg[ 5];
assign W[ 6] = (round_counter == 0) ? block[ 6] : W_reg[ 6];
assign W[ 7] = (round_counter == 0) ? block[ 7] : W_reg[ 7];
assign W[ 8] = (round_counter == 0) ? block[ 8] : W_reg[ 8];
assign W[ 9] = (round_counter == 0) ? block[ 9] : W_reg[ 9];
assign W[10] = (round_counter == 0) ? block[10] : W_reg[10];
assign W[11] = (round_counter == 0) ? block[11] : W_reg[11];
assign W[12] = (round_counter == 0) ? block[12] : W_reg[12];
assign W[13] = (round_counter == 0) ? block[13] : W_reg[13];
assign W[14] = (round_counter == 0) ? block[14] : W_reg[14];
assign W[15] = (round_counter == 0) ? block[15] : W_reg[15];

// MUX for selecting a,b,c,d,e,f,g,h input
assign a = (round_counter == 0) ? H_reg[0] : a_reg;
assign b = (round_counter == 0) ? H_reg[1] : b_reg;
assign c = (round_counter == 0) ? H_reg[2] : c_reg;
assign d = (round_counter == 0) ? H_reg[3] : d_reg;
assign e = (round_counter == 0) ? H_reg[4] : e_reg;
assign f = (round_counter == 0) ? H_reg[5] : f_reg;
assign g = (round_counter == 0) ? H_reg[6] : g_reg;
assign h = (round_counter == 0) ? H_reg[7] : h_reg;

// round function
assign e_round_out = d + h + ({e[5:0],e[31:6]} ^ {e[10:0],e[31:11]} ^ {e[24:0],e[31:25]})
               + ((e & f) ^ ((~e) & g))
               + constants[round_counter]
               + W[0];

assign a_round_out = h + ({e[5:0],e[31:6]} ^ {e[10:0],e[31:11]} ^ {e[24:0],e[31:25]})
               + ((e & f) ^ ((~e) & g))
               + constants[round_counter]
               + W[0]
               + ({a[1:0],a[31:2]} ^ {a[12:0],a[31:13]} ^ {a[21:0],a[31:22]})
               + ((a & b) ^ (a & c) ^ (b & c));

  // W is implemented as a shift register in principle,
  // i.e. we advance the message schedule by one block per clock cycle
assign W_sr_input = ({W[14][16:0],W[14][31:17]} ^ {W[14][18:0],W[14][31:19]} ^ {10'b0,W[14][31:10]})
              + W[9]
              + ({W[1][6:0],W[1][31:7]} ^ {W[1][17:0],W[1][31:18]} ^ {3'b0,W[1][31:3]})
              + W[0];

// switch state on clock edge
always@(posedge clk)
begin
  if(reset)
  begin
    current_state <= s_idle;
  end
  else
  begin
    case(current_state)
      s_idle:
        if(start)
        begin
          current_state <= s_processing;
        end
        else
        begin
          current_state <= s_idle;
        end
      s_processing:
        if(round_counter > 62)
        begin
          current_state <= s_idle;
        end
        else
        begin
          current_state <= s_processing;
        end
      default:
        current_state <= s_idle;
    endcase
  end
end

// combinational control signals 
assign last_round = (current_state == s_processing) && (round_counter > 62) ? 1'b1 : 1'b0;

// round counter
always@(posedge clk)
begin
  if(reset)
  begin
    round_counter <= 6'b0;
  end
  else
  begin 
    if (current_state == s_processing)
    begin
      round_counter <= (round_counter + 1);
    end
    else
    begin
      round_counter <= 6'b0;
    end
  end
end

// registered control signals
always@(posedge clk)
begin
  if(reset)
  begin
    data_out_valid_reg <= 0;
    busy_reg <= 0;
    done_reg <= 0;
  end
  else
  begin
    case(current_state)
      s_idle:
        if(start)
        begin
          busy_reg <= 1;
          done_reg <= 0;
        end
        else
        begin
          busy_reg <= 0;
          done_reg <= 0;
        end
      s_processing:
        begin
          data_out_valid_reg <= 0;

          if(round_counter > 62)
          begin
            data_out_valid_reg <= 1;
            done_reg <= 1;
          end
        end
      default:
        begin
        end
    endcase
  end
end

// register for next block and partial message
// includes a fixed padding for both 768 bit and 1024 bit messages
always@(posedge clk)
begin
  if(reset)
  begin
    // reset all registers to 0
    block[ 0] <= 32'b0;
    block[ 1] <= 32'b0;
    block[ 2] <= 32'b0;
    block[ 3] <= 32'b0;
    block[ 4] <= 32'b0;
    block[ 5] <= 32'b0;
    block[ 6] <= 32'b0;
    block[ 7] <= 32'b0;
    block[ 8] <= 32'b0;
    block[ 9] <= 32'b0;
    block[10] <= 32'b0;
    block[11] <= 32'b0;
    block[12] <= 32'b0;
    block[13] <= 32'b0;
    block[14] <= 32'b0;
    block[15] <= 32'b0;
  end
  else
  begin
    case(current_state)
      s_idle:
        if(start)
        begin
          block[ 0] <= data_in[511:480];
          block[ 1] <= data_in[479:448];
          block[ 2] <= data_in[447:416];
          block[ 3] <= data_in[415:384];
          block[ 4] <= data_in[383:352];
          block[ 5] <= data_in[351:320];
          block[ 6] <= data_in[319:288];
          block[ 7] <= data_in[287:256];
          block[ 8] <= data_in[255:224];
          block[ 9] <= data_in[223:192];
          block[10] <= data_in[191:160];
          block[11] <= data_in[159:128];
          block[12] <= data_in[127:96];
          block[13] <= data_in[95:64];
          block[14] <= data_in[63:32];
          block[15] <= data_in[31:0];
        end
    endcase
  end
end

// register for a,b,c,d,e,f,g,h
always@(posedge clk)
begin
  if(reset)
  begin
    // reset all registers to 0
    a_reg <= 32'b0;
    b_reg <= 32'b0;
    c_reg <= 32'b0;
    d_reg <= 32'b0;
    e_reg <= 32'b0;
    f_reg <= 32'b0;
    g_reg <= 32'b0;
    h_reg <= 32'b0;
  end
  else
  begin
    // save new content for a and e, shift other results one position "down".
    a_reg <= a_round_out;
    b_reg <= a;
    c_reg <= b;
    d_reg <= c;
    e_reg <= e_round_out;
    f_reg <= e;
    g_reg <= f;
    h_reg <= g;
  end
end

// shift register for message schedule W
always@(posedge clk)
begin
  if(reset)
  begin
    W_reg[ 0] <= 32'b0;
    W_reg[ 1] <= 32'b0;
    W_reg[ 2] <= 32'b0;
    W_reg[ 3] <= 32'b0;
    W_reg[ 4] <= 32'b0;
    W_reg[ 5] <= 32'b0;
    W_reg[ 6] <= 32'b0;
    W_reg[ 7] <= 32'b0;
    W_reg[ 8] <= 32'b0;
    W_reg[ 9] <= 32'b0;
    W_reg[10] <= 32'b0;
    W_reg[11] <= 32'b0;
    W_reg[12] <= 32'b0;
    W_reg[13] <= 32'b0;
    W_reg[14] <= 32'b0;
    W_reg[15] <= 32'b0;
  end
  else
  begin
    // shift register input for W_reg
    W_reg[ 0] <= W[ 1];
    W_reg[ 1] <= W[ 2];
    W_reg[ 2] <= W[ 3];
    W_reg[ 3] <= W[ 4];
    W_reg[ 4] <= W[ 5];
    W_reg[ 5] <= W[ 6];
    W_reg[ 6] <= W[ 7];
    W_reg[ 7] <= W[ 8];
    W_reg[ 8] <= W[ 9];
    W_reg[ 9] <= W[10];
    W_reg[10] <= W[11];
    W_reg[11] <= W[12];
    W_reg[12] <= W[13];
    W_reg[13] <= W[14];
    W_reg[14] <= W[15];
    W_reg[15] <= W_sr_input;
  end
end

// registers for state H and intermediate state registers
always@(posedge clk)
begin
  if(reset)
  begin
    // reset state directly to IV
    H_reg[0] <= 32'h6a09e667;
    H_reg[1] <= 32'hbb67ae85;
    H_reg[2] <= 32'h3c6ef372;
    H_reg[3] <= 32'ha54ff53a;
    H_reg[4] <= 32'h510e527f;
    H_reg[5] <= 32'h9b05688c;
    H_reg[6] <= 32'h1f83d9ab;
    H_reg[7] <= 32'h5be0cd19;
  end
  else 
  begin 
    if(init_message)
    begin
    // reset state directly to IV
    H_reg[0] <= 32'h6a09e667;
    H_reg[1] <= 32'hbb67ae85;
    H_reg[2] <= 32'h3c6ef372;
    H_reg[3] <= 32'ha54ff53a;
    H_reg[4] <= 32'h510e527f;
    H_reg[5] <= 32'h9b05688c;
    H_reg[6] <= 32'h1f83d9ab;
    H_reg[7] <= 32'h5be0cd19;
    end
    else if(init_iv)
    begin
      H_reg[0] <= data_in[511:480];
      H_reg[1] <= data_in[479:448];
      H_reg[2] <= data_in[447:416];
      H_reg[3] <= data_in[415:384];
      H_reg[4] <= data_in[383:352];
      H_reg[5] <= data_in[351:320];
      H_reg[6] <= data_in[319:288];
      H_reg[7] <= data_in[287:256];
    end

    else if(last_round)
    begin
      // update state only in the last round
      H_reg[0] <= H_reg[0] + a_round_out;
      H_reg[1] <= H_reg[1] + a;
      H_reg[2] <= H_reg[2] + b;
      H_reg[3] <= H_reg[3] + c;
      H_reg[4] <= H_reg[4] + e_round_out;
      H_reg[5] <= H_reg[5] + e;
      H_reg[6] <= H_reg[6] + f;
      H_reg[7] <= H_reg[7] + g;
    end
  end
end

assign busy = busy_reg;
assign done = done_reg;
assign data_out_valid = data_out_valid_reg;
assign data_out[255:224] = H_reg[0];
assign data_out[223:192] = H_reg[1];
assign data_out[191:160] = H_reg[2];
assign data_out[159:128] = H_reg[3];
assign data_out[127: 96] = H_reg[4];
assign data_out[ 95: 64] = H_reg[5];
assign data_out[ 63: 32] = H_reg[6];
assign data_out[ 31:  0] = H_reg[7];

endmodule

