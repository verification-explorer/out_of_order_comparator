class alter_txn extends uvm_callback;

    `uvm_object_utils(alter_txn)

    function new (string name = "alter_txn");
        super.new(name);
    endfunction

    virtual function void call_pre_write (txn item);
    endfunction

endclass

class alter_data extends alter_txn;

    `uvm_object_utils(alter_data)

    function new (string name = "alter_data");
        super.new(name);
    endfunction

    function void call_pre_write (txn item);
        if(item.get_data() inside {1,78, [200:255]}) item.set_data(item.get_data() + 1);
    endfunction

endclass

