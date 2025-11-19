module sha256XMSS_with_sha256
(
  input wire clk,
  input wire reset,
  input wire start, // start signal, one clock high
  input wire init_iv, // compatible interface with store variant,
  input wire second_block_data_available, // the second block of input data (256 or 512 bits) is received, and current computation is NOT busy, set as HIGH all the time when used in Chain/Leaf modules 
  input wire [1023:0] data_in, // input data, stay valid
  input wire message_length, // 0 -> 768 bit, 1 -> 1024 bit. stay valid 
  input wire store_intermediate, // compatible interface with store variant
  input wire continue_intermediate, // compatible interface with store variant
  output wire [255:0] data_out, // output data, buffered and do not changed unless updated as the next result
  output wire data_out_valid, // stay high as long as the output is valid
  output wire done, // one clock high, done signal
  output wire busy 
);

  wire sha256_start;
  wire sha256_init_message;
  wire sha256_init_iv;
  wire [511:0] sha256_data_in;
  // outputs
  wire [255:0] sha256_data_out;
  wire sha256_data_out_valid;
  wire sha256_done;
  wire sha256_busy;

sha256XMSS sha256XMSS_core_inst (
  .clk(clk),
  .reset(reset),
  .start(start),
  .init_iv(init_iv),
  .second_block_data_available(second_block_data_available),
  .data_in(data_in),
  .message_length(message_length),
  .store_intermediate(store_intermediate),
  .continue_intermediate(continue_intermediate),
  .data_out(data_out),
  .data_out_valid(data_out_valid),
  .done(done),
  .busy(busy),
  .sha256_start(sha256_start),
  .sha256_init_message(sha256_init_message),
  .sha256_init_iv(sha256_init_iv),
  .sha256_data_in(sha256_data_in),
  .sha256_data_out(sha256_data_out),
  .sha256_data_out_valid(sha256_data_out_valid),
  .sha256_done(sha256_done),
  .sha256_busy(sha256_busy)
  );

sha256 sha256_plain_inst (
    .clk(clk),
    .reset(reset),
    .start(sha256_start),
    .init_message(sha256_init_message),
    .data_in(sha256_data_in),
    .init_iv(sha256_init_iv),
    .data_out(sha256_data_out),
    .data_out_valid(sha256_data_out_valid),
    .done(sha256_done),
    .busy(sha256_busy)
  );

endmodule