class txn_seq_rand extends uvm_sequence #(txn);

    rand bit [7:0] txn_num;

    `uvm_object_utils(txn_seq_rand)

    function new (string name = "seq_rand");
        super.new(name);
    endfunction

    task body();
        repeat (txn_num) `uvm_do(req)
    endtask

endclass
