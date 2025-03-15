class txn extends uvm_sequence_item;

    rand bit [7:0] id;
    rand bit [7:0] data;

    `uvm_object_utils_begin(txn)
        `uvm_field_int(id,UVM_DEFAULT)
        `uvm_field_int(data,UVM_DEFAULT)
    `uvm_object_utils_end

    function new (string name = "txn");
        super.new(name);
    endfunction

    function string convert2string();
        string s="";
        $sformat(s,"%s id\t%0h data\t%0h\n",s,id,data);
        return s;
    endfunction

    function bit[7:0] get_id();
        return id;
    endfunction : get_id

    function void set_id(bit[7:0] id);
        this.id = id;
    endfunction : set_id

    function bit[7:0] get_data();
        return data;
    endfunction : get_data

    function void set_data(bit[7:0] data);
        this.data = data;
    endfunction : set_data

    // For mentor use
    function bit[7:0] index_id();
        return id;
    endfunction : index_id

endclass
