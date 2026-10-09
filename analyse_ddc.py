from pathlib import Path
import csv
import numpy as np

folder = Path(__file__).resolve().parent

for filename, lo_hz in [
    ("DDC_18kHz_1791116258309.csv", 18000),
    ("DDC_20kHz_1791117450737.csv", 20000),
]:
    with (folder / filename).open(newline="") as file:
        rows = list(csv.DictReader(file))

    time_s = np.array(
        [float(row["time_us"]) for row in rows]
    ) * 1e-6

    i = np.array([int(row["I"]) for row in rows])
    q = np.array([int(row["Q"]) for row in rows])
    z = i + 1j * q

    magnitude = np.abs(z)
    phase = np.unwrap(np.angle(z))

    # Estimate frequency from phase change over elapsed time.
    frequency_hz = (
        (phase[-1] - phase[0])
        / (2 * np.pi * (time_s[-1] - time_s[0]))
    )

    print(f"\nLO frequency: {lo_hz} Hz")
    print(f"Captured pairs: {len(rows)}")
    print(f"Estimated output frequency: {frequency_hz:.2f} Hz")
    print(f"Mean I/Q magnitude: {magnitude.mean():.2f}")
    print(f"Mean I: {i.mean():.2f}")
    print(f"Mean Q: {q.mean():.2f}")