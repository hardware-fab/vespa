
## Installation

This instructions have been tested on Ubuntu 22.04.


To install VESPA, first copy the repository on your machine:

    git clone https://github.com/hardware-fab/vespa

Then, install the dependencies running the bash script in the main folder:

    cd vespa

    ./dependencies.sh

and make sure to have installed the necessary software:

* Vivado 2019.2

* Cadence Xcelium 23.03.007

* ProFPGA Builder 2019A-SP2

Now, install the toolchain relative to one or more of the available processors:

    cd vespa

    # Leon3 toolchain

    ./utils/toolchain/build_leon3_toolchain.sh

    # RISC-V 64-bit toolchain (for the Ariane processor)

    ./utils/toolchain/build_riscv_toolchain.sh

    # RISC-V 32-bit toolchain (for the Ibex processor)

    ./utils/toolchain/build_riscv32imc_toolchain.sh

After this, you should edit the initialize.sh located in the main vespa folder
with your paths and source it in order to be able to use the tools:

    cd vespa

    source ./initialize.sh

Now you should be able to use the VESPA tool.


## Tutorials

You can refer to https://www.esp.cs.columbia.edu/docs/ for the ESP guide.
For the most part, the ESP instructions can be used also for VESPA.

Major differences:

* There are several differences in the GUI, but they are self-explaining.

* The programming of the board now happens through UART. Be sure to update the `esplink`
tool with the correct UART port name (go to ./tools/esplink/src/edcl.h and edit the
`SERIAL_PORT` define with the name of your port).

* The DFS is now managed by software. To use it, create a pointer in your program
to the specific domain register (to get its address, refer to the csr code in
./rtl/sockets/csr) and give it a value from 0 to 19. The actual frequency will be
FREQ = (X+1)*5 MHz.


## Accelerators

To install the CHStone accelerators used in the overview paper:

    cd ./socs/profpga-xc7v2000t
    ./accelerators.sh

You can install other accelerators following the ESP guides
(https://www.esp.cs.columbia.edu/docs/). However, the multi-replica architecture of
VESPA needs a batch register. So, during the creation of the accelerator, be sure
to include a register named "acc_name"_n, and give it the value of the size of the
data batches that this accelerator expects (the value can be modified later via software).




