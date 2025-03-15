class txn_route extends uvm_subscriber # (txn);

    uvm_analysis_port #(txn) ap_route; // Analysis port connects to stim driver
    bit [7:0] delay;                   // Time between transmission
    int num_of_txns=0;                 // Number of transmited items
    int txn_num;                       // Total number of transaction get from test

    q_of_txn_t q_of_txn[int];          // Associative array that hold queues of items
    int num_of_items_in_aa=0;          // How much items are stored in the AA

    `uvm_component_utils(txn_route)        // Provide implementations of virtual methods such as get_type_name and create
    `uvm_register_cb(txn_route, alter_txn) // Register the callback class for this component

    // Contruct the component and create analysis port
    function new (string name, uvm_component parent);
        super.new(name,parent);
        ap_route = new("route_ap", this);
    endfunction

    function void write (txn t);

        // Recived item from stim driver
        txn received;

        // Pointer safety is critical here becuase
        // this item is pushed in to a queue
        $cast(received,t.clone());

        `uvm_info(get_name(),$sformatf("push id: %0d data: %0h to queue\n",
                received.get_id(),received.data),UVM_DEBUG)

        // Store the item in a queue of relevant id associative array
        q_of_txn[received.get_id()].push_back(received);

        // Update number of items in data structure
        num_of_items_in_aa++;

    endfunction

    task run_phase (uvm_phase phase);
        super.run_phase(phase);

        // Get the total number of transactions from the test
        // This variable will be used for end of test mechanizm
        assert(uvm_config_int::get(this,"*","txn_num",txn_num));

        fork
            forever begin
                txn send_txn;    // The item to be sent
                int id_to_trans; // Hold the id of the transaction

                // Randomize delay and send transaction
                assert (std::randomize(delay) with {delay > 1;});
                #(delay * 1ns)

                // Wait for at least 1 item in the aa
                wait (num_of_items_in_aa > 0);

                // Select transaction from stored ids
                id_to_trans = select_id_to_trans(q_of_txn);

                // pop item to be sent
                send_txn = q_of_txn[id_to_trans].pop_front();

                // Alter sent item
                `uvm_do_callbacks(txn_route, alter_txn, call_pre_write(send_txn));

                // Transmit transaction from slected id in FIFO order
                if (!is_drop(send_txn)) ap_route.write(send_txn);

                // Reduce the number of items by 1
                num_of_items_in_aa--;

                // Check if any more items exist for that key
                // remove key if no more items
                if (q_of_txn[id_to_trans].size() == 0) q_of_txn.delete(id_to_trans);

                // Count number of transactions
                num_of_txns++;
            end

            begin
                // Continue test until all item were transmitted
                phase.raise_objection(this);
                phase.phase_done.set_drain_time(phase, 50);
                wait (num_of_txns==txn_num);
                phase .drop_objection(this);
            end

        join

    endtask

    // Select send item with arbitrary selected id
    function int select_id_to_trans(q_of_txn_t q[int]);

        int q_of_ids[$];  // Queue of all stored ids
        int id;           // loop index
        int random_index; // hold random index of id queue

        // Create a queue with all avalibale ids
        if (q.first(id))
            do
                q_of_ids.push_back(id);
            while (q.next(id));

        // Randomaly select an id from queue
        random_index = $urandom_range(0, q.size() - 1);

        // Ruturn the selected id
        return q_of_ids[random_index];

    endfunction

    virtual function bit is_drop (txn item);
        return 1'b0;
    endfunction

    function void report_phase (uvm_phase phase);
        `uvm_info(get_name(),$sformatf("Total number of %0d transactions were sent", txn_num),UVM_HIGH)
    endfunction

endclass

class drop_txn extends txn_route;

    `uvm_component_utils(drop_txn)

    function new (string name, uvm_component parent);
        super.new(name,parent);
    endfunction

    virtual function bit is_drop (txn item);
        randcase
            5 : return 0;
            1 : return 1;
        endcase
    endfunction

endclass
