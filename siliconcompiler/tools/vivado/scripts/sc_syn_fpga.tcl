# set up project
create_project $sc_topmodule -force
set_property part $sc_partname [current_project]
set_property target_language Verilog [current_project]

foreach sc_pre_script [sc_cfg_tool_task_get prescript] {
    puts "Sourcing pre script: ${sc_pre_script}"
    source $sc_pre_script
}

# generate clock wizard IP if requested
set clk_wiz_freq [sc_cfg_tool_task_get var clk_wiz_freq]
if { $clk_wiz_freq != "none" } {
    set clk_wiz_name [sc_cfg_tool_task_get var clk_wiz_name]
    puts "INFO: Generating Clock Wizard IP '${clk_wiz_name}' at ${clk_wiz_freq} MHz"

    create_ip -name clk_wiz -vendor xilinx.com -library ip -version 6.0 \
              -module_name $clk_wiz_name

    set_property -dict [list \
        CONFIG.CLKOUT1_DRIVES          {BUFG} \
        CONFIG.CLKOUT1_REQUESTED_OUT_FREQ $clk_wiz_freq \
        CONFIG.MMCM_BANDWIDTH          {OPTIMIZED} \
        CONFIG.MMCM_COMPENSATION       {ZHOLD} \
        CONFIG.PRIMITIVE               {MMCM} \
    ] [get_ips $clk_wiz_name]

    generate_target all [get_ips $clk_wiz_name]
    synth_ip [get_ips $clk_wiz_name]
}

# add imported files
if { [string equal [get_filesets -quiet sources_1] ""] } {
    create_fileset -srcset sources_1
}

# add source files (try SystemVerilog first, then Verilog)
if { [file exists "inputs/${sc_topmodule}.sv"] } {
    add_files -norecurse -fileset [get_filesets sources_1] "inputs/${sc_topmodule}.sv"
    set_property file_type SystemVerilog [get_files "inputs/${sc_topmodule}.sv"]
} else {
    add_files -norecurse -fileset [get_filesets sources_1] "inputs/${sc_topmodule}.v"
    set_property file_type Verilog [get_files "inputs/${sc_topmodule}.v"]
}
set_property top $sc_topmodule [current_fileset]

# add constraints
foreach xdc_file [sc_cfg_get_fileset $sc_designlib [sc_cfg_get option fileset] xdc] {
    if { [string equal [get_filesets -quiet constrs_1] ""] } {
        create_fileset -constrset constrs_1
    }
    add_files -norecurse -fileset [current_fileset] $xdc_file
}

# run synthesis
set synth_args []
lappend synth_args -directive [sc_cfg_tool_task_get var synth_directive]
set synth_mode [sc_cfg_tool_task_get var synth_mode]
if { $synth_mode != "none" } {
    lappend synth_args -mode $synth_mode
}
synth_design -top $sc_topmodule {*}$synth_args

opt_design

foreach sc_post_script [sc_cfg_tool_task_get postscript] {
    puts "Sourcing post script: ${sc_post_script}"
    source $sc_post_script
}
