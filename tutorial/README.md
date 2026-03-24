# Introduction

SiliconCompiler is an open-source framework that enables automated hardware design flows across multiple EDA tools. While it is commonly used for ASIC design, it can also be configured to work with FPGA toolchains such as Xilinx Vivado.

In this tutorial, we will show how to use SiliconCompiler to run a synthesis flow using Vivado.

# Installation

Before starting, make sure you have Python 3.9 or newer installed on your system.

First generate the python environment where you want, generally recommended to be inside the project directory.

```bash
python3 -m venv .venv        # Generate virtual environment
source .venv/bin/activate    # Activate the environment   
```

Since this is a modified version, you must install it from source.

```bash
git clone git@github.com:ECASLab/siliconcompiler.git
cd siliconcompiler

pip install --upgrade pip    # Update pip
pip install -e .             # Install siliconcompiler
```

# Setting Up Environment (PATH)

In order for SiliconCompiler to invoke Vivado correctly, you must add Vivado to your system PATH using the settings64.sh script. 

You can manually activate it by running the following command in terminal:

```bash
source /installation-path/<version>/Vivado/settings64.sh
```

If you want this to be set automatically every time you open a terminal, add the command to your `.bashrc` or `.zshrc`:

```bash
echo "source /installation-path/<version>/Vivado/settings64.sh" >> ~/.bashrc
```

## Verifying Vivado

After setting up the environment, verify that Vivado is accessible:

```bash
vivado -version
```
If the command runs successfully, SiliconCompiler will be able to use Vivado for synthesis.

# Running Synthesis Flow with Vivado

Below is a minimal example showing how to use SiliconCompiler with Xilinx Vivado for FPGA synthesis.

## Project Structure

```bash
project/
├── .venv/
├── sources/
│   ├── top_example.sv
│   ├── module1.sv
│   └── module2.sv
├── constraints/
│   └── constraints.xdc
└── build_example.py
```

## Example Script

```python
from siliconcompiler import Design, FPGA, FPGADevice
from siliconcompiler.flows.fpgaflow import FPGAXilinxFlow

def main():
    # 1. Create design 
    design = Design('top_example')

    # 2. Add RTL source
    design.add_file('sources/top_example.sv', fileset='rtl')

    # 2.1 Add multiple files
    design.add_file('sources/module1.sv', fileset='rtl')
    design.add_file('sources/module2.sv', fileset='rtl')
    
    # 3. Set top module name
    design.set_topmodule('top_example', fileset='rtl')

    # 4. Add constraints
    design.add_file('constraints/constraints.xdc', fileset='constraint')

    # 5. Create FPGA project
    project = FPGA(design)
    project.add_fileset(['rtl', 'constraint'])

    # 6. Select FPGA device
    fpga_device = FPGADevice("xc7")
    fpga_device.set_partname("xc7a35tcpg236-1")
    project.set_fpga(fpga_device)

    # 7. Select Vivado flow (Xilinx)
    flow = FPGAXilinxFlow()
    project.set_flow(flow)

    # 8. Run synthesis flow
    project.run()
    project.summary()


if __name__ == "__main__":
    main()  
```


> [!NOTE]
> The FPGA part (xc7a35tcpg236-1) corresponds to boards like the Basys3, but you should change it according to your hardware.

## Optional: Using the Clock Wizard IP

Xilinx Vivado provides an IP called Clocking Wizard (clk_wiz) that allows you to generate internal clocks with specific frequencies.

#### Enabling Clock Wizard in SiliconCompiler

You can enable and configure the Clock Wizard by setting the following variables:

```python
# Output frequency in MHz (Example 10.000)
project.set('tool', 'vivado', 'task', 'syn_fpga', 'var', 'clk_wiz_freq', '10.000')
# Instance name (Example clk_wiz_0)
project.set('tool', 'vivado', 'task', 'syn_fpga', 'var', 'clk_wiz_name', 'clk_wiz_0')
```
This automatically instantiates the Clock Wizard IP, generates a clock with the specified frequency
and integrates it into the synthesis flow

> [!WARNING]
> Your top-level design must be compatible with the generated clock
> You may need to:
> Connect the generated clock signal in your RTL.
> The clk_wiz_name must match how you reference the instance in your design.

## Optional: Programming the FPGA

By default, SiliconCompiler will generate the bitstream, but it will not automatically program the FPGA.
To enable automatic programming using Xilinx Vivado, add the following configuration:

```python
# Enables programming
project.set('tool', 'vivado', 'task', 'bitstream', 'var', 'program_fpga', 'true')
# Target specification
project.set('tool', 'vivado', 'task', 'bitstream', 'var', 'program_target', '*xc7a35t*')
```

> [!WARNING]
> Hardware connection required
> Your FPGA board must be connected via USB cable.
> Correct target pattern
> The program_target string must match your device. Examples:
> *xc7a35t* = Basys3 (Artix-7)
> You may need to adjust this depending on your board

# Full script example

```python
from siliconcompiler import Design, FPGA, FPGADevice
from siliconcompiler.flows.fpgaflow import FPGAXilinxFlow

def main():
    # 1. Create design 
    design = Design('top_example')

    # 2. Add RTL source
    design.add_file('sources/top_example.sv', fileset='rtl')

    # 2.1 Add multiple files
    design.add_file('sources/module1.sv', fileset='rtl')
    design.add_file('sources/module2.sv', fileset='rtl')
    
    # 3. Set top module name
    design.set_topmodule('top_example', fileset='rtl')

    # 4. Add constraints
    design.add_file('constraints/constraints.xdc', fileset='constraint')

    # 5. Create FPGA project
    project = FPGA(design)
    project.add_fileset(['rtl', 'constraint'])

    # 6. Select FPGA device
    fpga_device = FPGADevice("xc7")
    fpga_device.set_partname("xc7a35tcpg236-1")
    project.set_fpga(fpga_device)

    # 7. Select Vivado flow (Xilinx)
    flow = FPGAXilinxFlow()
    project.set_flow(flow)

    # 8. Clocking Wizard IP support
    project.set('tool', 'vivado', 'task', 'syn_fpga', 'var', 'clk_wiz_freq', '10.000')
    project.set('tool', 'vivado', 'task', 'syn_fpga', 'var', 'clk_wiz_name', 'clk_wiz_0')

    # 9. Enables automatic programming
    project.set('tool', 'vivado', 'task', 'bitstream', 'var', 'program_fpga', 'true')
    project.set('tool', 'vivado', 'task', 'bitstream', 'var', 'program_target', '*xc7a35t*')

    # 9. Run synthesis flow
    project.run()
    project.summary()


if __name__ == "__main__":
    main()  
```

# Running the flow

Once your script is ready, you can execute the full synthesis flow with:

```sh
python3 build_example.py
```

This will:

- Run synthesis
- Generate the bitstream
- Produce reports and logs

At the end, a summary will be printed in the terminal.

# Output Files

After running the flow, SiliconCompiler will generate a build directory containing:

- Synthesized netlist
- Implementation results
- Bitstream file (.bit)
- Logs for each step of the flow

Example structure:

```
build/
└── top_example/
    └── job0/
        ├── syn_fpga/
        ├── place/
        ├── route/
        └── bitstream/
```

