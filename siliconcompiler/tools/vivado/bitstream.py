from siliconcompiler.tools.vivado import VivadoTask


class BitstreamTask(VivadoTask):
    '''Generates bitstream of implemented design.'''

    def __init__(self):
        super().__init__()

        self.add_parameter("program_fpga", "str",
                           "Program FPGA after bitstream: 'true' or 'false'",
                           defvalue="false")
        self.add_parameter("program_target", "str",
                           "Hardware target filter (e.g. *xc7a35t*)",
                           defvalue="*xc7a35t*")

    
    def task(self):
        return "bitstream"

    def setup(self):
        super().setup()

        self.add_input_file(ext="dcp")
        self.add_output_file(ext="vg")
        self.add_output_file(ext="dcp")
        self.add_output_file(ext="xdc")
        self.add_output_file(ext="bit")

        self.add_required_key("var", "program_fpga")
        self.add_required_key("var", "program_target")
