// Implementation declarations
`uvm_analysis_imp_decl(_first_route)
`uvm_analysis_imp_decl(_second_route)

class txn_ooo_comp extends uvm_component;

    uvm_analysis_imp_first_route#(txn,txn_ooo_comp) first_route;   // Analysis port connects to first router
    uvm_analysis_imp_second_route#(txn,txn_ooo_comp) second_route; // Analysis port connects to second router

    q_of_txn_t q_of_txn_first[int];   // store items from first router
    q_of_txn_t q_of_txn_second[int];  // store items from second router

    int n_matches, n_mismatches;      // count to number of matches and mismatches

    `uvm_component_utils(txn_ooo_comp) // Provide implementations of virtual methods such as get_type_name and create

    // Contruct the component and create analysis ports
    function new (string name, uvm_component parent);
        super.new(name,parent);
        first_route = new ("first_route", this);
        second_route = new ("second_route", this);
    endfunction

    function void write_first_route(txn t);

        // item received from first router
        txn txn_received;

        // Pointer safety is critical here becuase
        // this item is pushed in to a queue
        $cast(txn_received,t.clone());

        `uvm_info(get_name(),$sformatf("@%0t received item from first route id: %0d, data: %0h",
                $realtime,txn_received.id,txn_received.data),UVM_MEDIUM)

        // Main algo, compare or store the item for future comparison
        compare_or_store_txn(.txn_received(txn_received),.store_q(q_of_txn_first),.compare_q(q_of_txn_second));

    endfunction

    function void write_second_route(txn t);

        // item received from first router
        txn txn_received;

        // Pointer safety is critical here becuase
        // this item is pushed in to a queue
        $cast(txn_received,t.clone());
        
        `uvm_info(get_name(),$sformatf("@%0t received item from second route id: %0d, data: %0h",
                $realtime,txn_received.id,txn_received.data),UVM_MEDIUM)

        // Main algo, compare or store the item for future comparison
        compare_or_store_txn(.txn_received(txn_received),.store_q(q_of_txn_second),.compare_q(q_of_txn_first));

    endfunction

    // Check if a transaction exist in other q
    // if yes compare and remove transaction from other q
    function void compare_or_store_txn(txn txn_received, ref q_of_txn_t store_q[int], ref q_of_txn_t compare_q[int]);

        // Checks if the item id exists in the queue that we want to compare to
        if (compare_q.exists(txn_received.get_id())) begin
            // indicats if comparison was succesfull
            bit is_equal;

            // the item that we want to compare to
            txn comparer = compare_q[txn_received.get_id()].pop_front();

            // true if matched items
            is_equal = txn_received.compare(comparer);

            // update counter match and mismatch counters
            if (!is_equal) begin

                // print error messeage if items are mismatched
                `uvm_error(get_name(),$sformatf("txn first id: %0d, data: %0h is not qual to second id: %0d, data: %0h\n",
                        txn_received.id,txn_received.data,comparer.id,comparer.data))

                // increase mismatch counter
                n_mismatches++;


            end else begin
                // print info message if items are matched
                `uvm_info(get_name(),$sformatf("txn first id: %0d, data: %0h is qual to second id: %0d, data: %0h\n",
                        txn_received.id,txn_received.data,comparer.id,comparer.data),UVM_MEDIUM)

                // increase match counter
                n_matches++;
            end

            // Check if any more items exist for a specific key
            // if no remove this id from associative array
            if (compare_q[txn_received.get_id()].size() == 0) compare_q.delete(txn_received.get_id());

            // item doesn't exist in queue, add it to back of the queue
        end else begin
            store_q[txn_received.get_id()].push_back(txn_received);
        end
    endfunction

    // get matched counter
    virtual function int get_matches();
        return n_matches;
    endfunction : get_matches

    // get mismatched counter
    virtual function int get_mismatches();
        return n_mismatches;
    endfunction : get_mismatches

    // get total missing items from all ids
    virtual function int get_total_missing();
        int num_missing;
        foreach(q_of_txn_first[key])
            num_missing+=q_of_txn_first[key].size();
        foreach(q_of_txn_second[key])
            num_missing+=q_of_txn_second[key].size();
        return num_missing;
    endfunction : get_total_missing

    // get missing ids
    virtual function q_of_idx get_missing_indexes();
        q_of_idx rv;
        foreach(q_of_txn_first[key])
            rv.push_back(key);
        foreach(q_of_txn_second[key])
            rv.push_back(key);
        return rv;
    endfunction : get_missing_indexes

    // report summary of all counters
    function void report_phase (uvm_phase phase);
        `uvm_info(get_name(),$sformatf("n_matches: %0d, n_mismatches: %0d, total_missing : %0d, missing_indexes: %0p",
                n_matches, n_mismatches, get_total_missing, get_missing_indexes),UVM_NONE)
    endfunction

endclass
