open_checkpoint "inputs/${sc_topmodule}.dcp"

foreach sc_pre_script [sc_cfg_tool_task_get prescript] {
    puts "Sourcing pre script: ${sc_pre_script}"
    source $sc_pre_script
}

write_bitstream -force -file "outputs/${sc_topmodule}.bit"


# Program FPGA
set program_fpga [sc_cfg_tool_task_get var program_fpga]
if { $program_fpga == "true" } {
    set program_target [sc_cfg_tool_task_get var program_target]
    set bit_file "outputs/${sc_topmodule}.bit"

    puts "INFO: Opening Hardware Manager..."
    open_hw_manager

    puts "INFO: Connecting to hardware server..."
    connect_hw_server

    puts "INFO: Opening hardware target..."
    open_hw_target

    set hw_device [get_hw_devices -filter "PART=~${program_target}"]
    if { [llength $hw_device] == 0 } {
        puts "ERROR: No FPGA device found matching '${program_target}'"
        puts "ERROR: Available devices:"
        foreach d [get_hw_devices] {
            puts "  - $d ([get_property PART $d])"
        }
    } else {
        current_hw_device $hw_device
        set_property PROGRAM.FILE $bit_file $hw_device
        puts "INFO: Programming device ${hw_device}..."
        program_hw_devices $hw_device
        puts "INFO: FPGA programmed successfully!"
    }

    close_hw_manager
}

foreach sc_post_script [sc_cfg_tool_task_get postscript] {
    puts "Sourcing post script: ${sc_post_script}"
    source $sc_post_script
}
