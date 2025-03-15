class ooo_comparator #(type T = int, type IDX = int) extends uvm_component;

    // Type definitions
    typedef ooo_comparator #(T, IDX) this_type;
    typedef T q_of_T[$];
    typedef IDX q_of_IDX[$];

    uvm_analysis_export #(T) before_axp, after_axp;
    protected uvm_tlm_analysis_fifo #(T) before_fifo, after_fifo;

    bit before_queued = 0;
    bit after_queued = 0;
    protected int m_matches, m_mismatches;
    protected q_of_T received_data[IDX];
    protected int rcv_count[IDX];
    // protected process before_proc = null;
    // protected process after_proc = null;

    `uvm_component_param_utils(this_type)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase( uvm_phase phase );
        before_axp = new("before_axp", this);
        after_axp = new("after_axp", this);
        before_fifo = new("before", this);
        after_fifo = new("after", this);
    endfunction

    function void connect_phase( uvm_phase phase );
        before_axp.connect(before_fifo.analysis_export);
        after_axp.connect(after_fifo.analysis_export);
    endfunction : connect_phase

    // The component forks two concurrent instantiations of this task
    // Each instantiation monitors an input analysis fifo
    protected task get_data(ref uvm_tlm_analysis_fifo #(T) txn_fifo, input bit is_before);

        T txn_data, txn_existing; 
        IDX idx;
        string rs;
        q_of_T tmpq;
        bit need_to_compare;

        forever begin

            // Get the transaction object, block if no transaction available
            txn_fifo.get(txn_data);
            idx = txn_data.index_id();

            // Check to see if there is an existing object to compare
            need_to_compare = (rcv_count.exists(idx) && ((is_before && rcv_count[idx] > 0) || (!is_before && rcv_count[idx] < 0)));

            if (need_to_compare) begin
                // Compare objects using compare() method of transaction
                tmpq = received_data[idx]; 
                txn_existing = tmpq.pop_front(); 
                received_data[idx] = tmpq;
                if (txn_data.compare(txn_existing))
                    m_matches++;
                else
                    m_mismatches++;
            end

            else begin
                // If no compare happened, add the new entry
                if (received_data.exists(idx))
                    tmpq = received_data[idx];
                else
                    tmpq = {};
                tmpq.push_back(txn_data);
                received_data[idx] = tmpq;
            end

            // Update the index count
            if (is_before)

                if (rcv_count.exists(idx)) begin
                    rcv_count[idx]--;
                end

                else
                    rcv_count[idx] = -1;
            else
                if (rcv_count.exists(idx)) begin
                    rcv_count[idx]++;
                end
                else
                    rcv_count[idx] = 1;

            // If index count is balanced, remove entry from the arrays
            if (rcv_count[idx] == 0) begin
                received_data.delete(idx);
                rcv_count.delete(idx);
            end

        end // forever

    endtask

    virtual function int get_matches();
        return m_matches;
    endfunction : get_matches

    virtual function int get_mismatches();
        return m_mismatches;
    endfunction : get_mismatches

    virtual function int get_total_missing();
        int num_missing;
        foreach (rcv_count[i]) begin
            num_missing += (rcv_count[i] < 0 ? -rcv_count[i] : rcv_count[i]);
        end
        return num_missing;
    endfunction : get_total_missing

    virtual function q_of_IDX get_missing_indexes();
         q_of_IDX rv = rcv_count.find_index() with (item != 0); 
         return rv;
    endfunction : get_missing_indexes

    virtual function int get_missing_index_count(IDX i);
        // If count is < 0, more "before" txns were received
        // If count is > 0, more "after" txns were received
        if (rcv_count.exists(i))
            return rcv_count[i];
        else
            return 0;
    endfunction : get_missing_index_count

    task run_phase( uvm_phase phase );
        fork
            get_data(before_fifo, /*before_proc,*/ 1);
            get_data(after_fifo, /*after_proc,*/ 0);
        join
    endtask : run_phase

    function void report_phase (uvm_phase phase);
        `uvm_info(get_name(),$sformatf("n_matches: %0d, n_mismatches: %0d, total_missing: %0d, missing_indexes: %0p"
        ,get_matches, get_mismatches,get_total_missing,get_missing_indexes),UVM_MEDIUM)
    endfunction

endclass : ooo_comparator
