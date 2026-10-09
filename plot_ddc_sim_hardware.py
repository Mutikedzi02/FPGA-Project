from pathlib import Path
import csv
import matplotlib.pyplot as plt

folder = Path(__file__).resolve().parent

cases = [
    (18, "DDC_18kHz_1791116258309.csv", "SIM_DDC_18kHz.csv"),
    (20, "DDC_20kHz_1791117450737.csv", "SIM_DDC_20kHz.csv"),
]


def read_csv(filename):
    with (folder / filename).open(newline="") as file:
        return [
            {key: int(value) for key, value in row.items()}
            for row in csv.DictReader(file)
        ]


fig, axes = plt.subplots(
    2, 2, figsize=(11, 6), sharex=True, sharey=True
)

for row_index, (lo_khz, hardware_file, simulation_file) in enumerate(cases):
    hardware = read_csv(hardware_file)
    simulation = read_csv(simulation_file)

    if len(hardware) != 16 or len(simulation) != 16:
        raise ValueError(f"{lo_khz} kHz: expected 16 pairs in each CSV.")

    hardware_times = [(r["sample"], r["time_us"]) for r in hardware]
    simulation_times = [(r["sample"], r["time_us"]) for r in simulation]

    if hardware_times != simulation_times:
        raise ValueError(f"{lo_khz} kHz: sample indices or times differ.")

    time_us = [r["time_us"] for r in hardware]

    for column_index, channel in enumerate(("I", "Q")):
        ax = axes[row_index, column_index]

        hardware_values = [r[channel] for r in hardware]
        simulation_values = [r[channel] for r in simulation]

        max_error = max(
            abs(hw - sim)
            for hw, sim in zip(hardware_values, simulation_values)
        )
        print(
            f"{lo_khz} kHz LO, {channel}: "
            f"maximum absolute error = {max_error}"
        )

        ax.plot(
            time_us,
            simulation_values,
            color="#205493",
            linewidth=1.5,
            label="RTL simulation",
        )
        ax.plot(
            time_us,
            hardware_values,
            linestyle="none",
            marker="o",
            markersize=5,
            markerfacecolor="none",
            markeredgecolor="#cf661a",
            label="FPGA hardware",
        )

        ax.set_title(f"{lo_khz} kHz LO — {channel} channel")
        ax.set_ylim(-6500, 6500)
        ax.grid(alpha=0.25)
        ax.legend(fontsize=8, loc="upper right")

        if column_index == 0:
            ax.set_ylabel("Amplitude (integer units)")
        if row_index == 1:
            ax.set_xlabel("Time from first captured pair (µs)")

fig.suptitle(
    "DDC simulation and hardware comparison · 20 kHz internal input",
    fontsize=13,
)
fig.tight_layout()

output_path = folder / "DDC_Simulation_Hardware_Comparison.png"
fig.savefig(output_path, dpi=300)
print(f"\nFigure saved to: {output_path}")

plt.show()