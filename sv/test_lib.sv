class txn_base_test extends uvm_test;

    txn_drv stim_driver;
    txn_sqr stim_sqr;

    txn_route first_route;
    txn_route second_route;

    txn_ooo_comp comparator;
    ooo_comparator#(txn,int) mentor_comp;

    int txn_num;

    `uvm_component_utils(txn_base_test)

    function new (string name, uvm_component parent);
        super.new(name,parent);
    endfunction

    function void build_phase (uvm_phase phase);
        super.build_phase (phase);

        // Build the components
        stim_sqr = txn_sqr::type_id::create("stim_sqr",this);
        stim_driver = txn_drv::type_id::create("stim_driver",this);
        first_route = txn_route::type_id::create("first_route",this);
        second_route = txn_route::type_id::create("second_route",this);
        comparator = txn_ooo_comp::type_id::create("comparator",this);
        mentor_comp = ooo_comparator#(txn,int)::type_id::create("mentor_comp",this);
    endfunction

    function void connect_phase (uvm_phase phase);
        stim_driver.seq_item_port.connect(stim_sqr.seq_item_export);
        stim_driver.txn_port.connect(first_route.analysis_export);
        stim_driver.txn_port.connect(second_route.analysis_export);
        first_route.ap_route.connect(comparator.first_route);
        second_route.ap_route.connect(comparator.second_route);
        first_route.ap_route.connect(mentor_comp.before_axp);
        second_route.ap_route.connect(mentor_comp.after_axp);
    endfunction

    function void end_of_elaboration_phase(uvm_phase phase);
        uvm_top.print_topology();
    endfunction

endclass

class txn_test extends txn_base_test;

    txn_seq_rand stim_seq;
    alter_data   m_alter_data;

    `uvm_component_utils(txn_test)

    function new (string name, uvm_component parent);
        super.new(name,parent);
    endfunction

    function void build_phase (uvm_phase phase);

        // Drop transaction indications
        if ($test$plusargs("drop_txn"))
        txn_route::type_id::set_inst_override(drop_txn::get_type(),"uvm_test_top.second_route");

        super.build_phase (phase);

        // Get the number of transaction per this test
        if ($value$plusargs("txn_num=%d", txn_num)) begin
            `uvm_info(get_name(),$sformatf("Transmit: %0d transactions",txn_num),UVM_MEDIUM)
        end else begin
            txn_num = 10;
        end
        uvm_config_int::set(this,"*","txn_num",txn_num);

        // Alter transaction data
        if($test$plusargs("alter_data")) begin
            m_alter_data = alter_data::type_id::create("m_alter_data",this);
            uvm_callbacks#(txn_route)::add(first_route, m_alter_data);
        end

    endfunction

    function void start_of_simulation_phase (uvm_phase phase);
        super.start_of_simulation_phase(phase);
        stim_seq = txn_seq_rand::type_id::create("act_seq",this);
    endfunction

    task run_phase (uvm_phase phase);
        super.run_phase(phase);
        phase.raise_objection(this);
        `uvm_info(get_name(),"Start Run Phase",UVM_MEDIUM)
        fork
            begin
                assert(stim_seq.randomize() with {txn_num==local::txn_num;});
                stim_seq.start(stim_sqr);
            end
        join
        phase.drop_objection(this);
    endtask

endclass
