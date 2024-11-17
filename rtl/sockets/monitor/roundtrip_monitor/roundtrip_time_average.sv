//----------------------------------------------------------------------------
//  This file is a part of the VESPA SoC Prototyping Framework
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Apache 2.0 License.
//
// File:    roundtrip_time_average.sv
// Authors: Gabriele Montanaro
//          Andrea Galimberti
//          Davide Zoni
// Company: Politecnico di Milano
// Mail:    name.surname@polimi.it
//----------------------------------------------------------------------------

//This module calculates the average number of cycles over a set of windows.
//Basically it counts every clock cycle when the window is open, but increases the average only after a number of counts equal to the total number of windows.
//(It is the same operation of summing all the windows length and dividing by the number of windows, but avoids the use of a divider)
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

module roundtrip_time_average #(
    parameter DATA_WIDTH = 16
)
(
  input  logic                    clk_i,
  input  logic                    rstn_i,
  input  logic                    start_count_i,
  input  logic                    stop_count_i,
  input  logic   [DATA_WIDTH-1:0] n_windows_i,
  output logic   [DATA_WIDTH-1:0] average_data_o,
  output logic                    average_valid_o,
  input  logic                    average_ready_i
  );

  //State machine
  typedef enum logic [1:0] {IDLE_S, WINDOW_HIGH_S, WINDOW_LOW_S, SEND_RESULT_S} state_t;
  state_t fsm_cs, fsm_ns;

  //Cycle counter
  logic [DATA_WIDTH-1:0] cycleCounter_n, cycleCounter_r;
  //Average counter
  logic [DATA_WIDTH-1:0] averageCounter_n, averageCounter_r;
  //Windows counter
  logic [DATA_WIDTH-1:0] windowCounter_n, windowCounter_r;
  //Register for the number of windows
  logic [DATA_WIDTH-1:0] totalWindowsNum_n, totalWindowsNum_r;

  //FSM implementation
  always_comb
  begin

    fsm_ns = fsm_cs;
    cycleCounter_n = cycleCounter_r;
    averageCounter_n = averageCounter_r;
    windowCounter_n = windowCounter_r;
    totalWindowsNum_n = totalWindowsNum_r;

    average_data_o = '0;
    average_valid_o = '0;

    case(fsm_cs)

      //IDLE: waiting for the first request of the batch
      IDLE_S:
      begin
        cycleCounter_n = '0;
        averageCounter_n = '0;
        windowCounter_n = '0;
        //When the first valid is issued, register the total number of windows and start counting
        if (start_count_i)
        begin
          totalWindowsNum_n = n_windows_i;
          windowCounter_n = windowCounter_r + 1;
          fsm_ns = WINDOW_HIGH_S;
        end
      end

      //WINDOW_HIGH: increasing the counters
      WINDOW_HIGH_S:
      begin
        //When a valid data is coming from the memory, stop the window
        if(stop_count_i)
        begin
          if (windowCounter_r == totalWindowsNum_r)
            fsm_ns = SEND_RESULT_S;
          else
            fsm_ns = WINDOW_LOW_S;
        end
        else
        begin
          cycleCounter_n = cycleCounter_r + 1;
          //When the number of the windows is reached, increase the average counter
          if(cycleCounter_r == totalWindowsNum_r-1)
          begin
            cycleCounter_n = '0;
            averageCounter_n = averageCounter_r + 1;
          end
        end
      end

      //WINDOW_LOW: counters are freezed
      WINDOW_LOW_S:
      begin
        //When a valid request is issued from the accelerator, increase the number of windows and restart the counting
        if (start_count_i)
        begin
          windowCounter_n = windowCounter_r + 1;
          fsm_ns = WINDOW_HIGH_S;
        end
      end

      //SEND_RESULT: sending the result with an axi-stream handshake
      SEND_RESULT_S:
      begin
        average_data_o = averageCounter_r;
        average_valid_o = 'b1;
        if(average_ready_i)
          fsm_ns = IDLE_S;
      end


      //DEFAULT: return to IDLE
      default:
      begin
        fsm_ns = IDLE_S;
      end
    endcase
  end

  always_ff @(posedge clk_i)
  begin
    if(rstn_i==0)
    begin
      fsm_cs <= IDLE_S;
      cycleCounter_r <= '0;
      averageCounter_r <= '0;
      windowCounter_r <= '0;
      totalWindowsNum_r <= '0;
    end
    else
    begin
      fsm_cs <= fsm_ns;
      cycleCounter_r <= cycleCounter_n;
      averageCounter_r <= averageCounter_n;
      windowCounter_r <= windowCounter_n;
      totalWindowsNum_r <= totalWindowsNum_n;
    end
  end
endmodule
