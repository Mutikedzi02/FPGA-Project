# FPGA-Project
PC-controlled digital downconverter (DDC) with a built-in test signal

# DE10-Lite Digital Down Converter

A register-controlled digital down converter implemented in Verilog on the Terasic DE10-Lite FPGA board. The project demonstrates digital frequency translation, quadrature mixing, FIR filtering, decimation, sample capture and PC-based analysis.

The system uses an internally generated signal, so no external signal generator or analogue input equipment is required. The board’s USB connection provides programming and JTAG communication with the PC.

## Project overview

The FPGA generates a 20 kHz test signal at a sampling rate of 100 kHz. A selectable local oscillator operates at either 18 kHz or 20 kHz.

The input is mixed with cosine and negative sine oscillator signals to produce the in-phase and quadrature channels. Both channels pass through a nine-tap low-pass FIR filter before decimation by five, giving an output sampling rate of 20 kHz.

Sixteen I/Q sample pairs are stored in FPGA memory. The PC controls acquisition and reads the stored samples through the In-System Sources and Probes JTAG interface. Python scripts process the exported data and generate plots.

The two oscillator settings demonstrate different output conditions.

- **18 kHz LO** produces a nominal 2 kHz baseband signal.
- **20 kHz LO** produces a DC output because the input and oscillator frequencies match.

## Hardware and software

- Terasic DE10-Lite with a MAX 10 FPGA, device `10M50DAF484C7G`
- On-board 50 MHz clock
- USB connection between the board and PC
- Quartus Prime Lite Edition 25.1 Standard
- Questa Altera FPGA Starter Edition 2025.2
- Python with NumPy and Matplotlib

The board ADC and external SDRAM are not used in this implementation.

## Design parameters

| Parameter | Value |
|---|---|
| FPGA clock | 50 MHz |
| Input sampling rate | 100 kHz |
| Internal input frequency | 20 kHz |
| Local oscillator frequencies | 18 kHz and 20 kHz |
| Processing channels | I and Q |
| FIR filter length | 9 taps |
| FIR coefficients | `[1, 2, 3, 4, 5, 4, 3, 2, 1] / 25` |
| Decimation factor | 5 |
| Output sampling rate | 20 kHz |
| Capture length | 16 I/Q pairs |
| Stored sample format | Signed 16-bit integers |
| Useful capture storage | 512 bits |
| PC interface | JTAG |

The FIR uses sequential accumulation and iterative division. This implementation spreads the arithmetic across several FPGA clock cycles while completing each result within the available input-sample interval.

## Repository files

### FPGA design

| File or folder | Purpose |
|---|---|
| `DDC_Board_Project.qpf` | Quartus project file |
| `DDC_Board_Project.qsf` | Project settings, source references and pin assignments |
| `DDC_Board_Project.sdc` | Clock timing constraints |
| `DDC_Board_Project.v` | Board-level integration, control and sample capture |
| `sample_tick.v` | Generates the 100 kHz sample-enable pulse |
| `test_signal.v` | Generates the internal 20 kHz input sequence |
| `nco_phase.v` | Generates the local oscillator phase sequence |
| `nco_lut.v` | Provides sine and cosine lookup values |
| `iq_mixer.v` | Implements signed I/Q mixing |
| `fir_lowpass.v` | Implements low-pass FIR filtering |
| `jtag_control.qsys` | JTAG source and probe IP configuration |
| `jtag_control/` | Generated IP files used by the FPGA design |
| `output_files/` | Quartus compilation outputs |

### Simulation and PC analysis

| File or folder | Purpose |
|---|---|
| `tb_ddc.v` | Testbench for the DDC processing chain |
| `simulation/` | Simulation-related files |
| `SIM_DDC_18kHz.csv` | Simulated output for the 18 kHz LO case |
| `SIM_DDC_20kHz.csv` | Simulated output for the 20 kHz LO case |
| `DDC_18kHz_1791116258309.csv` | Captured hardware output for the 18 kHz LO case |
| `DDC_20kHz_1791117450737.csv` | Captured hardware output for the 20 kHz LO case |
| `analyse_ddc.py` | Numerical analysis of captured output |
| `plot_ddc.py` | Plotting of DDC output |
| `plot_ddc_comparison.py` | Comparison of the two oscillator settings |
| `plot_ddc_sim_hardware.py` | Comparison of simulation and hardware output |
| `Pictures/` | Project figures and supporting evidence |
| `DDC.drawio` | Editable system diagram |

## Building and programming

1. Open `DDC_Board_Project.qpf` in Quartus.
2. Confirm that the target device is `10M50DAF484C7G`.
3. Check that the Verilog modules, timing constraints and generated JTAG IP are included.
4. Regenerate the JTAG IP if Quartus requests it.
5. Run a full compilation.
6. Review the timing and resource reports.
7. Connect the DE10-Lite and program it with the compiled `.sof` file.
8. Open the In-System Sources and Probes Editor to access the control and readout interface.

The generated JTAG synthesis file is located under `jtag_control/synthesis/`. Preserve the project’s relative file paths when downloading or moving the repository.

## Register control

The JTAG IP uses a 10-bit source bus and a 16-bit probe bus. The source bus controls acquisition and selects the stored word returned through the probe.

| Control bit | Function |
|---|---|
| 0 | Run enable |
| 1 | Reset |
| 5:2 | Memory read address, from 0 to 15 |
| 6 | LO selection, 0 for 18 kHz and 1 for 20 kHz |
| 7 | Channel selection, 0 for I and 1 for Q |
| 9:8 | Unused |

Example hexadecimal control words are shown below.

| Command | Value |
|---|---|
| Reset with 18 kHz LO selected | `0x002` |
| Run with 18 kHz LO selected | `0x001` |
| Reset with 20 kHz LO selected | `0x042` |
| Run with 20 kHz LO selected | `0x041` |

Apply reset before each new acquisition. After capture completes, select each memory address and read both channels.

Probe words must be interpreted as signed 16-bit values. For an unsigned readout value of 32768 or greater, subtract 65536 to recover the signed sample.

## Python analysis

Install the required packages.

```bash
python -m pip install numpy matplotlib
```

Run the analysis and plotting scripts from the directory containing their input CSV files. Check the filenames configured in each script if the files have been renamed or moved.

The stored samples are spaced by 50 µs. The sixteen-pair record therefore runs from 0 to 750 µs relative to the first captured pair.

## Verified results

| LO frequency | Expected output | Hardware result |
|---|---|---|
| 18 kHz | 2 kHz baseband signal | Estimated frequency of 2000.01 Hz |
| 20 kHz | DC | I = 5999 and Q = 0 for all 16 pairs |

The 18 kHz case had a mean complex magnitude of approximately 5790.53 integer counts.

RTL simulation reproduced all sixteen captured pairs for each oscillator setting. Across both cases, all thirty-two I/Q pairs matched, with zero difference in either channel.

The testbench verifies the processing chain and reproduces the capture-selection schedule. It does not simulate the complete board-level JTAG interface or physical USB communication. The FPGA does not need to be connected when running this simulation.

## FPGA resource usage

The final Quartus implementation reported the following resource usage.

| Resource | Used | Available | Utilisation |
|---|---:|---:|---:|
| Logic elements | 1571 | 49760 | 3.16% |
| Dedicated logic registers | 721 | 49760 | 1.45% |
| M9K memory blocks | 1 | 182 | 0.55% |
| Embedded multiplier 9-bit elements | 4 | 288 | 1.39% |
| Pins | 21 | 360 | 5.83% |

The final board-clock setup slack was **2.453 ns**, and hold slack was **0.099 ns**. The reported final timing summary showed zero total negative slack for the applicable checks.

## Limitations

This project demonstrates frequency translation using a known internally generated signal. It does not acquire an external analogue or RF input.

The capture buffer stores sixteen pairs and does not provide continuous streaming. The short record demonstrates the expected output behaviour but is insufficient for detailed spectral-purity or long-term frequency-stability measurements.

The nine-tap FIR is suitable for the demonstrated test cases. A general-purpose receiver would require a filter designed against explicit passband and stopband requirements.

## Author

Mutikedzi Mudzanani
