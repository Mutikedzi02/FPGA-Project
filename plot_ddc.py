from pathlib import Path
import csv
import matplotlib.pyplot as plt

folder = Path(__file__).resolve().parent
csv_path = folder / "DDC_18kHz_1791116258309.csv"

with csv_path.open(newline="") as file:
    rows = list(csv.DictReader(file))

time_us = [float(row["time_us"]) for row in rows]
i_samples = [int(row["I"]) for row in rows]
q_samples = [int(row["Q"]) for row in rows]

fig, ax = plt.subplots(figsize=(9, 4.5))

ax.plot(time_us, i_samples, "o-", label="I")
ax.plot(time_us, q_samples, "s-", label="Q")

ax.set_title("Measured DDC output: 20 kHz input, 18 kHz LO")
ax.set_xlabel("Time from first captured sample (µs)")
ax.set_ylabel("Amplitude (integer sample units)")
ax.grid(True, alpha=0.3)
ax.legend()
fig.tight_layout()

output_path = folder / "DDC_18kHz_IQ.png"
fig.savefig(output_path, dpi=300)

print(f"Loaded {len(rows)} I/Q pairs")
print(f"Figure saved to: {output_path}")

plt.show()