// gas_fsm.v
// Modul FSM 6-State untuk Deteksi Gas Berbahaya (VERSI DIPERBAIKI)
// Input: G,T,P,C,F,R (1 = Aman/OK, 0 = Bahaya/Gagal)
// Output: V,B,S,L,A,U (1 = ON/Aktif)
// Menggunakan 3 D-Flip-Flop (Register 3-bit)

module gas_fsm (
    // Input
    input wire clk,
    input wire rst, // Reset (active-high)
    input wire G,   // Gas (1=OK)
    input wire T,   // Suhu (1=OK)
    input wire P,   // Power (1=OK)
    input wire C,   // Arus Kipas (1=OK)
    input wire F,   // Aliran Udara (1=OK)
    input wire R,   // Reset RFID (1=Match)

    // Output
    output reg V,   // Ventilation Fan
    output reg B,   // Backup Power
    output reg S,   // Solenoid Valve
    output reg L,   // Local Alarm
    output reg A,   // Remote Alert
    output reg U    // Visual Alarm
);

    // --- Definisi State (Step 3) ---
    localparam [2:0]
        S0_STANDBY      = 3'b000,
        S1_HAZARD       = 3'b001,
        S2_FAULT_MIT    = 3'b010,
        S3_WAIT_RESET   = 3'b011,
        S4_FAILSAFE_PF  = 3'b100,
        S5_HAZARD_PF    = 3'b101;

    // --- State Register (Implementasi Step 4) ---
    reg [2:0] curr_state, next_state;
    
    // --- [FIX 1] Deklarasi Sinyal Logika Kombinatorial ---
    // (Dipindahkan dari dalam always block)
    wire isHazard = (~G) | (~T); // Gas ATAU Suhu bahaya
    wire isSafe = G & T;
    wire isPowerFail = ~P;
    wire isMitigationFault = (~C) | (~F); // Kipas ATAU Aliran gagal
    wire isResetAuth = R;


    // (Sequential Logic) - Blok D Flip-Flop
    always @(posedge clk or posedge rst) begin
        if (rst)
            curr_state <= S0_STANDBY; // Reset ke S0
        else
            curr_state <= next_state; // Update state pada detak clock
    end

    // --- Logika Transisi (Step 5) ---
    // (Combinational Logic) - Menghitung Next State
    always @(*) begin
        // Default: Tahan state saat ini
        next_state = curr_state;

        case (curr_state)
            S0_STANDBY: begin
                if (isPowerFail)
                    next_state = S4_FAILSAFE_PF;
                else if (isHazard)
                    next_state = S1_HAZARD;
            end
            
            S1_HAZARD: begin
                if (isPowerFail)
                    next_state = S5_HAZARD_PF;
                else if (isMitigationFault)
                    next_state = S2_FAULT_MIT;
                else if (isSafe)
                    next_state = S3_WAIT_RESET;
            end
            
            S2_FAULT_MIT: begin
                if (isPowerFail)
                    next_state = S5_HAZARD_PF; // Fault + Power Fail -> Hazard Power Fail
                else if (isSafe)
                    next_state = S3_WAIT_RESET;
            end
            
            S3_WAIT_RESET: begin
                if (isPowerFail)
                    next_state = S4_FAILSAFE_PF;
                else if (isResetAuth)
                    next_state = S0_STANDBY;
                else if (isHazard) // Jika gas bocor lagi sebelum direset
                    next_state = S1_HAZARD;
            end
            
            S4_FAILSAFE_PF: begin
                if (~isPowerFail) // Jika PLN Pulih (P=1)
                    next_state = S0_STANDBY;
            end
            
            S5_HAZARD_PF: begin
                if (~isPowerFail) // Jika PLN Pulih (P=1)
                    next_state = S1_HAZARD; // Kembali ke state Hazard
            end
            
            default:
                next_state = S0_STANDBY;
        endcase
    end

    // --- Logika Output (Step 7) ---
    // (Combinational Logic) - Menentukan Aktuator (Moore FSM)
    always @(*) begin
        // Default semua aktuator OFF
        V = 1'b0; B = 1'b0; S = 1'b0;
        L = 1'b0; A = 1'b0; U = 1'b0;

        case (curr_state)
            S0_STANDBY:      {V,B,S,L,A,U} = 6'b000000; // Aman
            S1_HAZARD:       {V,B,S,L,A,U} = 6'b101111; // Kipas, Valve, 3 Alarm
            S2_FAULT_MIT:    {V,B,S,L,A,U} = 6'b101111; // Sama, tapi state beda (untuk logging)
            S3_WAIT_RESET:   {V,B,S,L,A,U} = 6'b000111; // Hanya 3 Alarm (menunggu reset)
            S4_FAILSAFE_PF:  {V,B,S,L,A,U} = 6'b010000; // Hanya Backup Power
            S5_HAZARD_PF:    {V,B,S,L,A,U} = 6'b111111; // Semua ON dari UPS
            default:         {V,B,S,L,A,U} = 6'b000111; // Default ke Alarm jika state tidak diketahui
        endcase
    end

endmodule