# VHDL CORDIC Library

This repository contains a comprehensive **VHDL CORDIC (Coordinate Rotation Digital Computer)** library implementing both **Rotation** and **Vectoring** modes. The core is designed for high-precision DSP applications using **Q3.13 Fixed-Point Arithmetic** and supports full-circle operation (Quadrant Correction).

## 📦 Modules

### 1. Rotation Mode (`RotationMode.vhd`)
Calculates **Sine** and **Cosine** for a given input angle.
- **Input:** Angle $\theta$ (Radians)
- **Output:** $\sin(\theta)$, $\cos(\theta)$
- **Range:** Full Circle ($-180^\circ$ to $+180^\circ$)
- **Application:** Direct Digital Synthesis (DDS), Signal Generation.

### 2. Vectoring Mode (`VectoringMode.vhd`)
Calculates **Magnitude** and **Phase Angle** for a given vector $(x, y)$.
- **Input:** Vector Coordinates $(x, y)$
- **Output:** Magnitude ($R$), Phase Angle ($\theta$)
- **Range:** Full 4-Quadrant Arctangent
- **Application:** Radar Signal Processing, Field Oriented Control (FOC).

## 🚀 Key Features
- **Precision:** 16-bit Signed Fixed-Point (**Q3.13** Format).
- **Architecture:** 16-Iteration State Machine (Area Optimized).
- **Quadrant Correction:** Automatically handles inputs across all 4 quadrants (Full Circle Support).
- **Verification:** Includes comprehensive testbenches for both modes.

## 🔢 Data Format (Q3.13)
The design uses a 16-bit signed fixed-point representation to handle fractional values without floating-point units.

* **Total Bits:** 16
* **Integer Bits:** 3 bits (Range $\pm 3.99$, covers $\pi$)
* **Fractional Bits:** 13 bits
* **Scaling Factor:** $2^{13} = 8192$

| Value | Calculation | Fixed-Point (Decimal) | Hex |
| :--- | :--- | :--- | :--- |
| **+1.0** | $1.0 \times 8192$ | `8192` | `0x2000` |
| **+90° ($\pi/2$)** | $1.571 \times 8192$ | `12868` | `0x3244` |
| **+180° ($\pi$)** | $3.142 \times 8192$ | `25736` | `0x6488` |
| **K (Gain)** | $0.607 \times 8192$ | `4975` | `0x136F` |

## 🛠 Simulation & Usage
The repository includes two testbenches:
1. `tb_RotationMode.vhd`: Verifies Sin/Cos generation across different angles.
2. `tb_VectoringMode.vhd`: Verifies Magnitude/Angle calculation (including complex scenarios).

**How to Verify:**
1. Import source files into Vivado or ModelSim.
2. Run the behavioral simulation.

> **Note on Vectoring Mode:** The magnitude output is scaled by the CORDIC gain $K \approx 1.647$. To get the true magnitude, the output must be multiplied by $0.607$ (or processed accordingly).

## 👤 Author
**Abdullah Ömer Gündoğan**
Sakarya University - Electrical and Electronics Engineering
