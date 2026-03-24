foreach sc_pre_script [sc_cfg_tool_task_get prescript] {
    puts "Sourcing pre script: ${sc_pre_script}"
    source $sc_pre_script
}

set bit_file "inputs/${sc_topmodule}.bit"
set program_target [sc_cfg_tool_task_get var program_target]

if { ![file exists $bit_file] } {
    puts "ERROR: Bitstream file '${bit_file}' not found"
    exit 1
}

puts "INFO: Opening Hardware Manager..."
open_hw_manager

puts "INFO: Connecting to hardware server..."
connect_hw_server

puts "INFO: Opening hardware target..."
open_hw_target

puts "INFO: Looking for device matching '${program_target}'..."
set hw_device [get_hw_devices -filter "PART=~${program_target}"]
if { [llength $hw_device] == 0 } {
    puts "ERROR: No FPGA device found matching '${program_target}'"
    puts "ERROR: Available devices:"
    foreach d [get_hw_devices] {
        puts "  - $d ([get_property PART $d])"
    }
    close_hw_manager
    exit 1
}

current_hw_device $hw_device
set_property PROGRAM.FILE $bit_file $hw_device
puts "INFO: Programming device ${hw_device}..."
program_hw_devices $hw_device
puts "INFO: FPGA programmed successfully!"

close_hw_manager

foreach sc_post_script [sc_cfg_tool_task_get postscript] {
    puts "Sourcing post script: ${sc_post_script}"
    source $sc_post_script
}