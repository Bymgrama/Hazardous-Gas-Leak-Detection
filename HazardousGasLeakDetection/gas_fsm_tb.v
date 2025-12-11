// gas_fsm_tb.v
// Testbench untuk FSM Deteksi Gas (VERSI DIPERBAIKI)
`timescale 1ns/1ps

module gas_fsm_tb;

    // --- Deklarasi Sinyal ---
    reg clk, rst;
    reg G, T, P, C, F, R;
    wire V, B, S, L, A, U;
    // [FIX 2] Menghapus wire [2:0] state; (tidak diperlukan untuk simulasi)

    // --- Instansiasi Modul Utama (Unit Under Test) ---
    gas_fsm UUT (
        .clk(clk), .rst(rst), .G(G), .T(T), .P(P), .C(C), .F(F), .R(R),
        .V(V), .B(B), .S(S), .L(L), .A(A), .U(U)
    );
    
    // [FIX 2] Menghapus baris 'assign state = UUT.curr_state;' 
    // (Tidak didukung oleh iverilog)

    // --- Clock Generator (Periode 10 ns) ---
    initial clk = 0;
    always #5 clk = ~clk;

    // --- Dumpfile untuk GTKWave (Membuat file .vcd) ---
    initial begin
        $dumpfile("output.vcd"); 
        $dumpvars(0, gas_fsm_tb); // Simpan semua sinyal
    end

    // --- STIMULUS (Skenario Uji) ---
    initial begin
        // Inisialisasi & Reset
        rst = 1; G=1; T=1; P=1; C=1; F=1; R=0;
        #20; // Tunggu 20 ns
        rst = 0; // Lepas reset
        $display("Time=%0t: S0 (Standby)", $time);

        // --- Skenario 1: Gas Bocor (Pindah ke S1) ---
        #100;
        G = 0; // Gas Bocor!
        #10;
        $display("Time=%0t: S1 (Hazard) - Gas Bocor", $time);

        // --- Skenario 2: Kipas Gagal (Pindah ke S2) ---
        #100;
        C = 0; // Arus Kipas Mati!
        #10;
        $display("Time=%0t: S2 (Fault) - Kipas Rusak", $time);

        // --- Skenario 3: PLN Mati (Pindah ke S5) ---
        #100;
        P = 0; // PLN Mati!
        #10;
        $display("Time=%0t: S5 (Hazard Power Fail)", $time);
        
        // --- Skenario 4: PLN Pulih (Kembali ke S2) ---
        #100;
        P = 1; // PLN Pulih
        #10;
        $display("Time=%0t: S2 (Fault) - PLN Pulih", $time);

        // --- Skenario 5: Bahaya Selesai (Pindah ke S3) ---
        #100;
        G = 1; // Gas Aman
        C = 1; // Kipas (dimisalkan) sudah OK
        #10;
        $display("Time=%0t: S3 (Waiting for Reset)", $time);

        // --- Skenario 6: Otorisasi Reset (Pindah ke S0) ---
        #100;
        R = 1; // Otorisasi RFID
        #10;
        R = 0; // Lepas kartu
        #10;
        $display("Time=%0t: S0 (Standby) - Sistem Reset", $time);

        // --- Skenario 7: PLN Mati saat Standby (Pindah ke S4) ---
        #100;
        P = 0; // PLN Mati
        #10;
        $display("Time=%0t: S4 (Failsafe Power Fail)", $time);

        // --- Skenario 8: PLN Pulih (Kembali ke S0) ---
        #100;
        P = 1; // PLN Pulih
        #10;
        $display("Time=%0t: S0 (Standby) - PLN Pulih", $time);

        // Akhiri simulasi
        #50;
        $display("Simulasi selesai pada waktu %0t ns", $time);
        $finish;
    end

endmodule