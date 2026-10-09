from pathlib import Path
import csv
import matplotlib.pyplot as plt

folder = Path(__file__).resolve().parent

captures = [
    ("DDC_18kHz_1791116258309.csv",
     "18 kHz LO: expected 2 kHz output"),
    ("DDC_20kHz_1791117450737.csv",
     "20 kHz LO: expected DC output"),
]

fig, axes = plt.subplots(
    2, 1, figsize=(9, 7), sharex=True, sharey=True
)

for ax, (filename, title) in zip(axes, captures):
    with (folder / filename).open(newline="") as file:
        rows = list(csv.DictReader(file))

    time_us = [float(row["time_us"]) for row in rows]
    i_samples = [int(row["I"]) for row in rows]
    q_samples = [int(row["Q"]) for row in rows]

    ax.plot(time_us, i_samples, "o-", label="I")
    ax.plot(time_us, q_samples, "s-", label="Q")
    ax.set_title(title)
    ax.set_ylabel("Amplitude (integer units)")
    ax.set_ylim(-6500, 6500)
    ax.grid(True, alpha=0.3)
    ax.legend(loc="upper right")

axes[-1].set_xlabel("Time from first captured sample (µs)")
fig.suptitle("Measured DDC outputs: 20 kHz internal input")
fig.tight_layout(rect=[0, 0, 1, 0.95])

output = folder / "DDC_LO_Comparison.png"
fig.savefig(output, dpi=300)
print(f"Figure saved to: {output}")

plt.show()