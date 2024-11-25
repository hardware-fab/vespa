/**************************************************************************
 *                                                                        *
 *  Catapult(R) MatchLib Toolkit Example Design Library                   *
 *                                                                        *
 *  Software Version: 1.2                                                 *
 *                                                                        *
 *  Release Date    : Thu Aug 11 16:24:59 PDT 2022                        *
 *  Release Type    : Production Release                                  *
 *  Release Build   : 1.2.9                                               *
 *                                                                        *
 *  Copyright 2020 Siemens                                                *
 *                                                                        *
 **************************************************************************
 *  Licensed under the Apache License, Version 2.0 (the "License");       *
 *  you may not use this file except in compliance with the License.      * 
 *  You may obtain a copy of the License at                               *
 *                                                                        *
 *      http://www.apache.org/licenses/LICENSE-2.0                        *
 *                                                                        *
 *  Unless required by applicable law or agreed to in writing, software   * 
 *  distributed under the License is distributed on an "AS IS" BASIS,     * 
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or       *
 *  implied.                                                              * 
 *  See the License for the specific language governing permissions and   * 
 *  limitations under the License.                                        *
 **************************************************************************
 *                                                                        *
 *  The most recent version of this package is available at github.       *
 *                                                                        *
 *************************************************************************/

// Autogenerated from wrapper_gen.py on Mon, 07 Dec 2020 21:53:04 +0000
// Arguments: Namespace(clock_name='clk', clock_period='10', exec_args=None, exec_name='../08_dma/sim_sc', header=None, not_top_level='true', obj_name='top.ram1', start_clk_low=None)

#include "ram.h"


class ram_wrap : public sc_module {
public:
  ram CCS_INIT_S1(ram_inst);
  
  sc_core::sc_in<bool>  CCS_INIT_S1(clk);
  sc_core::sc_in<bool>  CCS_INIT_S1(rst_bar);
  sc_in<sc_lv<44>> CCS_INIT_S1(r_slave0_ar_msg);
  sc_in<bool>      CCS_INIT_S1(r_slave0_ar_val);
  sc_out<bool>     CCS_INIT_S1(r_slave0_ar_rdy);
  sc_out<sc_lv<71>> CCS_INIT_S1(r_slave0_r_msg);
  sc_out<bool>     CCS_INIT_S1(r_slave0_r_val);
  sc_in<bool>      CCS_INIT_S1(r_slave0_r_rdy);
  sc_in<sc_lv<44>> CCS_INIT_S1(w_slave0_aw_msg);
  sc_in<bool>      CCS_INIT_S1(w_slave0_aw_val);
  sc_out<bool>     CCS_INIT_S1(w_slave0_aw_rdy);
  sc_in<sc_lv<73>> CCS_INIT_S1(w_slave0_w_msg);
  sc_in<bool>      CCS_INIT_S1(w_slave0_w_val);
  sc_out<bool>     CCS_INIT_S1(w_slave0_w_rdy);
  sc_out<sc_lv<6>> CCS_INIT_S1(w_slave0_b_msg);
  sc_out<bool>     CCS_INIT_S1(w_slave0_b_val);
  sc_in<bool>      CCS_INIT_S1(w_slave0_b_rdy);
 
  sc_clock connections_clk;
  sc_event check_event;
 
  virtual void start_of_simulation() {
    Connections::get_sim_clk().add_clock_alias(
      connections_clk.posedge_event(), clk.posedge_event());
  }
 
  SC_CTOR(ram_wrap)
   : connections_clk("connections_clk", 10, SC_NS, 0.5,0,SC_NS,true)
  {
    SC_METHOD(check_clock);
    sensitive << connections_clk;
    sensitive << clk;
    
    SC_METHOD(check_event_method);
    sensitive << check_event;
    
    ram_inst.clk(clk);
    ram_inst.rst_bar(rst_bar);
    ram_inst.r_slave0.ar.msg(r_slave0_ar_msg);
    ram_inst.r_slave0.ar.val(r_slave0_ar_val);
    ram_inst.r_slave0.ar.rdy(r_slave0_ar_rdy);
    ram_inst.r_slave0.r.msg(r_slave0_r_msg);
    ram_inst.r_slave0.r.val(r_slave0_r_val);
    ram_inst.r_slave0.r.rdy(r_slave0_r_rdy);
    ram_inst.w_slave0.aw.msg(w_slave0_aw_msg);
    ram_inst.w_slave0.aw.val(w_slave0_aw_val);
    ram_inst.w_slave0.aw.rdy(w_slave0_aw_rdy);
    ram_inst.w_slave0.w.msg(w_slave0_w_msg);
    ram_inst.w_slave0.w.val(w_slave0_w_val);
    ram_inst.w_slave0.w.rdy(w_slave0_w_rdy);
    ram_inst.w_slave0.b.msg(w_slave0_b_msg);
    ram_inst.w_slave0.b.val(w_slave0_b_val);
    ram_inst.w_slave0.b.rdy(w_slave0_b_rdy);
  }
  
  void check_clock() { check_event.notify(2, SC_PS);} // Let SC and Vlog delta cycles settle.
  
  void check_event_method() {
    if (connections_clk.read() == clk.read()) return;
    CCS_LOG("clocks misaligned!:"  << connections_clk.read() << " " << clk.read());
  }
};
