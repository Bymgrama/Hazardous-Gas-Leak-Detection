# -------------------------------------------------------------
# JUDUL: Simulasi Deteksi Gas menggunakan Quantum Toffoli Gate
# PENULIS: Muhammad Guntur Ramadhan
# REFERENSI: Laporan Step 9 (Simulasi Quantum)
# -------------------------------------------------------------

# Library: Qiskit
from qiskit import QuantumCircuit, Aer, execute

def run_quantum_simulation(gas_input, temp_input):
    """
    Input: 1 (Aman), 0 (Bahaya)
    Output Logic: Alarm (q2) aktif jika Gas=0 ATAU Suhu=0
    """
    # Inisialisasi: 3 Qubit (q0=Gas, q1=Suhu, q2=Alarm) + 1 Bit Klasik
    qc = QuantumCircuit(3, 1)

    # 1. ENCODING INPUT (Memetakan kondisi sensor ke Qubit)
    # Set qubit ke |1> jika input sensor Aman (Logika 1)
    if gas_input == 1: qc.x(0) 
    if temp_input == 1: qc.x(1) 

    # 2. LOGIKA QUANTUM (NAND via Toffoli)
    # Inisialisasi Alarm ke |1> (Waspada/Default ON) agar Fail-Safe
    qc.x(2)
    
    # Toffoli (CCNOT): Jika Gas=1 AND Suhu=1, Balik Alarm jadi 0 (OFF)
    qc.ccx(0, 1, 2)

    # 3. PENGUKURAN (Measurement)
    # Ukur q2, simpan ke bit klasik c0
    qc.measure(2, 0) 

    # 4. EKSEKUSI PADA SIMULATOR
    # Menggunakan simulator QASM bawaan Aer
    simulator = Aer.get_backend('qasm_simulator')
    job = execute(qc, simulator, shots=1024)
    result = job.result()
    counts = result.get_counts(qc)
    return counts

# --- SKENARIO PENGUJIAN ---
if __name__ == "__main__":
    print("--- HASIL SIMULASI QUANTUM (Sesuai Laporan) ---")
    
    # Kasus 1: Semua Aman (1, 1) -> Harapan: Alarm 0 (Mati)
    # Output counts harus dominan di '0'
    print(f"Input (1,1) Aman   -> Output Counts: {run_quantum_simulation(1, 1)}")
    
    # Kasus 2: Gas Bocor (0, 1) -> Harapan: Alarm 1 (Nyala)
    # Output counts harus dominan di '1'
    print(f"Input (0,1) Bahaya -> Output Counts: {run_quantum_simulation(0, 1)}")