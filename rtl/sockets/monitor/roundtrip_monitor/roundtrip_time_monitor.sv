//----------------------------------------------------------------------------
//  This file is a part of the VESPA SoC Prototyping Framework
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Apache 2.0 License.
//
// File:    roundtrip_time_monitor.sv
// Authors: Gabriele Montanaro
//          Andrea Galimberti
//          Davide Zoni
// Company: Politecnico di Milano
// Mail:    name.surname@polimi.it
//----------------------------------------------------------------------------

//This module calculates the average roundtrip time of a data requests from an accelerator for a batch of data.
//It sums all the roundtrip times of the batch, and then performs a division for the number of requests.
//
//SUFFIXES:
//i: input
//o: output
//n: input of a register (assigned in combinatorial processes, read in sequential processes)
//r: output of a register (read in combinatorial processes, assigned in sequential processes)
//w: wire (used only in combinatorial processes)
//t: type
//cs: current state (read in combinatorial processes, assigned in sequential processes)
//ns: next state (assigned in combinatorial processes, read in sequential processes)
//S: state

module roundtrip_time_monitor #(
    parameter DATA_WIDTH    = 16,
    parameter LOG2_N_CORES  = 0
)
(
  input  logic                      clk_i,
  input  logic                      rstn_i,
  input  logic                      acc_req_valid_i,
  input  logic                      mem_data_valid_i,
  input  logic   [DATA_WIDTH-1:0]   batch_length_i,
  output logic   [DATA_WIDTH-1:0]   mon_acc_roundtrip_time
  //output logic   [DATA_WIDTH-1:0]   local_apb_snd_data_o,
  //output logic                      local_apb_snd_wrreq_o,
  //input  logic                      local_apb_snd_full_i
  );

  logic [DATA_WIDTH-1:0] requests_num_w;

  logic [DATA_WIDTH-1:0] average_data_w;
  logic average_valid_w;
  logic average_ready_w;

  logic [DATA_WIDTH-1:0] average_data_r, average_data_n;


  //Simple shift to obtain the number of expected requests
  generate
    if (LOG2_N_CORES == 0)
      assign requests_num_w = batch_length_i;
    else if(LOG2_N_CORES == 1)
      always_comb
      begin
        if(batch_length_i[0] == 0)
          requests_num_w = batch_length_i >> LOG2_N_CORES;
        else
          requests_num_w = (batch_length_i >> LOG2_N_CORES) + 1;
      end
    else
      always_comb
      begin
      if (batch_length_i[LOG2_N_CORES-1:0] == 0)
        requests_num_w = batch_length_i >> LOG2_N_CORES;
      else
        requests_num_w = (batch_length_i >> LOG2_N_CORES) + 1;
      end
  endgenerate

  //always_comb begin
  //  if (LOG2_N_CORES == 0) begin
  //    requests_num_w = batch_length_i;
  //  end
  //  else if(LOG2_N_CORES == 1) begin
  //    if(batch_length_i[0] == 0) begin
  //      requests_num_w = batch_length_i >> LOG2_N_CORES;
  //    end
  //    else begin
  //      requests_num_w = (batch_length_i >> LOG2_N_CORES) + 1;
  //    end
  //  end
  //  else begin
  //    if (batch_length_i[LOG2_N_CORES-1:0] == 0) begin
  //      requests_num_w = batch_length_i >> LOG2_N_CORES;
  //    end
  //    else begin
  //      requests_num_w = (batch_length_i >> LOG2_N_CORES) + 1;
  //    end
  //  end
    //begin
    //  requests_num_w = batch_length_i >> LOG2_N_CORES;
    //  for (logic [7:0] i=0; i<LOG2_N_CORES; i++)
    //    if (requests_num_w[i] == 1'b1)
    //      requests_num_w = (batch_length_i >> LOG2_N_CORES) + 1;
    //end
    //if (batch_length_i[LOG2_N_CORES-1:0] == '0)
    //  requests_num_w = batch_length_i >> LOG2_N_CORES;
    //else
    //  requests_num_w = (batch_length_i >> LOG2_N_CORES) + 1;
  //end

  //A module that computes the average of the times
  //It counts every clock cycle increasing the average every requests_num_w cycles
  roundtrip_time_average #(
    .DATA_WIDTH (DATA_WIDTH)
  ) averager_inst (
    .clk_i             (clk_i),
    .rstn_i             (rstn_i),
    .start_count_i     (acc_req_valid_i),
    .stop_count_i      (mem_data_valid_i),
    .n_windows_i       (requests_num_w),
    .average_data_o    (average_data_w)  ,
    .average_valid_o   (average_valid_w),
    .average_ready_i   (average_ready_w)
  );

  //Ready is always high
  assign average_ready_w = '1;

  //Simple register to keep the result
  always_ff @(posedge clk_i)
  begin
    if (rstn_i==0)
      average_data_r <= '0;
    else
      average_data_r <= average_data_n;
  end

  always_comb
  begin
    if(average_valid_w)
      average_data_n <= average_data_w;
    else
      average_data_n <= average_data_r;
  end

  assign mon_acc_roundtrip_time = average_data_r;
  //A module that convert the average in a packet and send it to the csr register through the NoC
  //roundtrip_time_packetizer #(
  //  .DATA_WIDTH    (DATA_WIDTH),
  //  .THIS_TILE_ID  (THIS_TILE_ID)
  //) packetizer_inst (
  //  .clk_i                   (clk_i),
  //  .rst_i                   (rst_i),
  //  .average_data_i          (average_data_w),
  //  .average_valid_i         (average_valid_w),
  //  .average_ready_o         (average_ready_w),
  //  .local_apb_snd_data_o    (local_apb_snd_data_o),
  //  .local_apb_snd_wrreq_o   (local_apb_snd_wrreq_o),
  //  .local_apb_snd_full_i    (local_apb_snd_full_i)
  //);

endmodule
