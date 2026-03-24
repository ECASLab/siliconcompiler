from siliconcompiler.tools.vivado import VivadoTask


class LoadBitstreamTask(VivadoTask):
    '''Programs an FPGA device with the generated bitstream.'''
    def __init__(self):
        super().__init__()

        self.add_parameter("program_target", "str",
                           "Hardware device filter (e.g. *xc7a35t*)",
                           defvalue="*xc7a35t*")

    def task(self):
        return "load_bitstream"

    def setup(self):
        super().setup()
        self.add_input_file(ext="bit")
        self.add_required_key("var", "program_target")