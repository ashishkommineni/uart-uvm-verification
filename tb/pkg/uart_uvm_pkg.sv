`timescale 1ns / 1ps
package uart_uvm_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  localparam int DATA_BITS = 8;
  localparam int CLKS_PER_BIT = 16;
  class uart_item extends uvm_sequence_item;
    rand bit [DATA_BITS-1:0] data;
    rand bit parity_en;
    rand bit parity_odd;
    bit [DATA_BITS-1:0] rx_data;
    bit parity_error, frame_error;
    constraint c_parity_mode {
      !parity_en -> !parity_odd;
      parity_en dist {
        0 := 4,
        1 := 6
      };
    }
    constraint c_payload {
      data dist {
        8'h00 := 1,
        8'hff := 1,
        8'h55 := 1,
        8'haa := 1,
        [8'h01 : 8'hfe] := 12
      };
    }
    `uvm_object_utils_begin(uart_item)
      `uvm_field_int(data, UVM_HEX)
      `uvm_field_int(parity_en, UVM_DEFAULT)
      `uvm_field_int(parity_odd, UVM_DEFAULT)
      `uvm_field_int(rx_data, UVM_HEX)
      `uvm_field_int(parity_error, UVM_DEFAULT)
      `uvm_field_int(frame_error, UVM_DEFAULT)
    `uvm_object_utils_end
    function new(string name = "uart_item");
      super.new(name);
    endfunction
  endclass
  class uart_sequencer extends uvm_sequencer #(uart_item);
    `uvm_component_utils(uart_sequencer)
    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction
  endclass
  class uart_driver extends uvm_driver #(uart_item);
    `uvm_component_utils(uart_driver)
    virtual uart_if #(DATA_BITS) vif;
    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction
    function void build_phase(uvm_phase phase);
      if (!uvm_config_db#(virtual uart_if #(DATA_BITS))::get(this, "", "vif", vif))
        `uvm_fatal("NOVIF", "uart_if missing")
    endfunction
    task run_phase(uvm_phase phase);
      vif.drv_cb.tx_start <= 0;
      vif.drv_cb.tx_data <= '0;
      vif.drv_cb.parity_en <= 0;
      vif.drv_cb.parity_odd <= 0;
      wait (vif.rst_n === 1);
      forever begin
        seq_item_port.get_next_item(req);
        while (vif.tx_busy) @(vif.drv_cb);
        vif.drv_cb.tx_data <= req.data;
        vif.drv_cb.parity_en <= req.parity_en;
        vif.drv_cb.parity_odd <= req.parity_odd;
        vif.drv_cb.tx_start <= 1;
        @(vif.drv_cb);
        vif.drv_cb.tx_start <= 0;
        seq_item_port.item_done();
      end
    endtask
  endclass
  class uart_monitor extends uvm_monitor;
    `uvm_component_utils(uart_monitor)
    virtual uart_if #(DATA_BITS)   vif;
    uvm_analysis_port #(uart_item) ap;
    function new(string name, uvm_component parent);
      super.new(name, parent);
      ap = new("ap", this);
    endfunction
    function void build_phase(uvm_phase phase);
      if (!uvm_config_db#(virtual uart_if #(DATA_BITS))::get(this, "", "vif", vif))
        `uvm_fatal("NOVIF", "uart_if missing")
    endfunction
    task run_phase(uvm_phase phase);
      uart_item tr;
      wait (vif.rst_n === 1);
      forever begin
        @(posedge vif.clk iff (vif.tx_start && !vif.tx_busy));
        tr = uart_item::type_id::create("tr");
        tr.data = vif.tx_data;
        tr.parity_en = vif.parity_en;
        tr.parity_odd = vif.parity_odd;
        @(posedge vif.clk iff vif.rx_valid);
        #1ps;
        tr.rx_data = vif.rx_data;
        tr.parity_error = vif.rx_parity_error;
        tr.frame_error = vif.rx_frame_error;
        ap.write(tr);
      end
    endtask
  endclass
  class uart_agent extends uvm_agent;
    `uvm_component_utils(uart_agent)
    uart_sequencer sqr;
    uart_driver drv;
    uart_monitor mon;
    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction
    function void build_phase(uvm_phase phase);
      sqr = uart_sequencer::type_id::create("sqr", this);
      drv = uart_driver::type_id::create("drv", this);
      mon = uart_monitor::type_id::create("mon", this);
    endfunction
    function void connect_phase(uvm_phase phase);
      drv.seq_item_port.connect(sqr.seq_item_export);
    endfunction
  endclass
  class uart_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(uart_scoreboard)
    uvm_analysis_imp #(uart_item, uart_scoreboard) analysis_export;
    int checked;
    function new(string name, uvm_component parent);
      super.new(name, parent);
      analysis_export = new("analysis_export", this);
    endfunction
    function void write(uart_item tr);
      checked++;
      if (tr.rx_data !== tr.data)
        `uvm_error("DATA", $sformatf("expected=%02h actual=%02h", tr.data, tr.rx_data))
      if (tr.parity_error || tr.frame_error)
        `uvm_error("UART_ERR", $sformatf("parity=%0b frame=%0b", tr.parity_error, tr.frame_error))
    endfunction
    function void check_phase(uvm_phase phase);
      if (checked == 0) `uvm_error("NO_DATA", "No UART frames checked")
    endfunction
    function void report_phase(uvm_phase phase);
      `uvm_info("UART_SUMMARY", $sformatf("Checked %0d loopback frames", checked), UVM_LOW)
    endfunction
  endclass
  class uart_coverage extends uvm_subscriber #(uart_item);
    `uvm_component_utils(uart_coverage)
    uart_item tr;
    covergroup cg;
      cp_data: coverpoint tr.data {
        bins zero = {8'h00};
        bins ones = {8'hff};
        bins alt0 = {8'h55};
        bins alt1 = {8'haa};
        bins other = default;
      }
      cp_parity: coverpoint {
        tr.parity_en, tr.parity_odd
      } {
        bins none = {2'b00, 2'b01}; bins even = {2'b10}; bins odd = {2'b11};
      }
      cx: cross cp_data, cp_parity;
    endgroup
    function new(string name, uvm_component parent);
      super.new(name, parent);
      cg = new();
    endfunction
    function void write(uart_item t);
      tr = t;
      cg.sample();
    endfunction
  endclass
  class uart_env extends uvm_env;
    `uvm_component_utils(uart_env)
    uart_agent agent;
    uart_scoreboard sb;
    uart_coverage cov;
    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction
    function void build_phase(uvm_phase phase);
      agent = uart_agent::type_id::create("agent", this);
      sb = uart_scoreboard::type_id::create("sb", this);
      cov = uart_coverage::type_id::create("cov", this);
    endfunction
    function void connect_phase(uvm_phase phase);
      agent.mon.ap.connect(sb.analysis_export);
      agent.mon.ap.connect(cov.analysis_export);
    endfunction
  endclass
  class uart_sequence extends uvm_sequence #(uart_item);
    `uvm_object_utils(uart_sequence)
    function new(string name = "uart_sequence");
      super.new(name);
    endfunction
    task body();
      bit [7:0] directed[4] = '{8'h00, 8'h55, 8'haa, 8'hff};
      foreach (directed[i]) begin
        req = uart_item::type_id::create("directed");
        start_item(req);
        req.data = directed[i];
        req.parity_en = i != 0;
        req.parity_odd = i[0];
        finish_item(req);
      end
      repeat (40) begin
        req = uart_item::type_id::create("random");
        start_item(req);
        if (!req.randomize()) `uvm_fatal("RAND", "randomization failed")
        finish_item(req);
      end
    endtask
  endclass
  class uart_test extends uvm_test;
    `uvm_component_utils(uart_test)
    uart_env env;
    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction
    function void build_phase(uvm_phase phase);
      env = uart_env::type_id::create("env", this);
    endfunction
    task run_phase(uvm_phase phase);
      uart_sequence seq;
      phase.raise_objection(this);
      seq = uart_sequence::type_id::create("seq");
      seq.start(env.agent.sqr);
      wait (!env.agent.mon.vif.tx_busy);
      repeat (CLKS_PER_BIT * 2) @(posedge env.agent.mon.vif.clk);
      phase.drop_objection(this);
    endtask
  endclass
endpackage
