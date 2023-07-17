class tb_riscv_test_base #(
  type  BASE  = uvm_test
) extends BASE;
  tb_rice_bus_slave_sequencer inst_bus_sequencer;
  tb_rice_bus_slave_sequencer data_bus_sequencer;

  const tb_rice_bus_address START_ADDRESS   = 'h8000_0000;
  const tb_rice_bus_address TOHOST_ADDRESS  = START_ADDRESS + 'h1000;

  task pre_reset_phase(uvm_phase phase);
    phase.raise_objection(this);
    load_inst_data();
    phase.drop_objection(this);
  endtask

  task main_phase(uvm_phase phase);
    phase.raise_objection(this);
    monitor_finish_condition();
    phase.drop_objection(this);
  endtask

  protected virtual task load_inst_data();
    string              riscv_test_file;
    int                 fp;
    tb_rice_bus_status  bus_status;
    tb_rice_bus_address address;
    int                 byte_data;

    `tue_define_plusarg_string(+RISCV_TEST_FILE, riscv_test_file);
    `uvm_info(
      "LOAD_INST_DATA",
      $sformatf("load inst data from %s", riscv_test_file),
      UVM_MEDIUM
    )

    fp  = $fopen(riscv_test_file, "r");
    if (fp == 0) begin
      `uvm_fatal(
        "LOAD_INST_DATA",
        $sformatf("cannot open such file: %s", riscv_test_file)
      )
    end

    bus_status  = inst_bus_sequencer.get_status();
    address     = START_ADDRESS;
    while (1) begin
      byte_data = $fgetc(fp);
      if (byte_data == -1) begin
        break;
      end

      bus_status.memory.put(byte_data, 1'b1, 1, address, 0);
      address += 1;
    end

    $fclose(fp);
  endtask

  protected virtual task monitor_finish_condition();
    tb_rice_bus_item  bus_item;

    do begin
      data_bus_sequencer.get_item(bus_item);
    end while (!end_of_test_pattern(bus_item));

    if (bus_item.data == 1) begin
      `uvm_info(
        "CHECK_RESULT",
        "all tests are passed",
        UVM_MEDIUM
      )
    end
    else begin
      int test_no = bus_item.data >> 1;
      `uvm_error(
        "CHECK_RESULT",
        $sformatf("test no %0d is faield", test_no)
      )
    end
  endtask

  protected virtual function bit end_of_test_pattern(
    tb_rice_bus_item  bus_item
  );
    return bus_item.is_write() && (bus_item.address == TOHOST_ADDRESS);
  endfunction

  `tue_component_default_constructor(tb_riscv_test_base)
endclass
