class txn_drv extends uvm_driver #(txn);

    uvm_analysis_port #(txn) txn_port;

    `uvm_component_utils(txn_drv)

    function new (string name, uvm_component parent);
        super.new(name,parent);
        txn_port = new("txn_port",this);
    endfunction

    task run_phase (uvm_phase phase);
        super.run_phase(phase);
        forever begin
            seq_item_port.get_next_item(req);
            #1ns
            txn_port.write(req);
            seq_item_port.item_done();
        end
    endtask

endclass
