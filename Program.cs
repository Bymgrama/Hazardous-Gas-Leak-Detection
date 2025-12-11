using System;
using System.Threading;

// -------------------------------------------------------------
// PROJECT: Fail-Safe Hazardous Gas Mitigation System
// FILE: Program.cs
// AUTHOR: Muhammad Guntur Ramadhan (NRP: 2042241009)
// DESC: C# Simulation for Microcontroller Implementation
// -------------------------------------------------------------

public enum GasSystemState
{
    S0_STANDBY,
    S1_HAZARD_MITIGATION,
    S2_FAULT_MITIGATION,
    S3_WAITING_FOR_RESET,
    S4_FAILSAFE_POWERFAIL,
    S5_HAZARD_POWERFAIL
}

public class GasSafetyFsm
{
    public GasSystemState CurrentState { get; private set; }

    // Output Aktuator
    public bool V_Fan { get; private set; }
    public bool B_Backup { get; private set; }
    public bool S_Valve { get; private set; }
    public bool L_Alarm { get; private set; }
    public bool A_Alert { get; private set; }
    public bool U_Visual { get; private set; }

    public GasSafetyFsm()
    {
        CurrentState = GasSystemState.S0_STANDBY;
        SetOutputs();
    }

    public void Update(bool G, bool T, bool P, bool C, bool F, bool R)
    {
        // Logika Sensor
        bool isHazard = !G || !T;
        bool isSafe = G && T;
        bool isPowerFail = !P;
        bool isMitigationFault = !C || !F;
        bool isResetAuth = R;

        GasSystemState nextState = CurrentState;

        switch (CurrentState)
        {
            case GasSystemState.S0_STANDBY:
                if (isPowerFail) nextState = GasSystemState.S4_FAILSAFE_POWERFAIL;
                else if (isHazard) nextState = GasSystemState.S1_HAZARD_MITIGATION;
                break;

            case GasSystemState.S1_HAZARD_MITIGATION:
                if (isPowerFail) nextState = GasSystemState.S5_HAZARD_POWERFAIL;
                else if (isMitigationFault) nextState = GasSystemState.S2_FAULT_MITIGATION;
                else if (isSafe) nextState = GasSystemState.S3_WAITING_FOR_RESET;
                break;

            case GasSystemState.S2_FAULT_MITIGATION:
                if (isPowerFail) nextState = GasSystemState.S5_HAZARD_POWERFAIL;
                else if (isSafe) nextState = GasSystemState.S3_WAITING_FOR_RESET;
                break;

            case GasSystemState.S3_WAITING_FOR_RESET:
                if (isPowerFail) nextState = GasSystemState.S4_FAILSAFE_POWERFAIL;
                else if (isResetAuth) nextState = GasSystemState.S0_STANDBY;
                else if (isHazard) nextState = GasSystemState.S1_HAZARD_MITIGATION;
                break;

            case GasSystemState.S4_FAILSAFE_POWERFAIL:
                if (!isPowerFail) nextState = GasSystemState.S0_STANDBY;
                break;

            case GasSystemState.S5_HAZARD_POWERFAIL:
                if (!isPowerFail) nextState = GasSystemState.S1_HAZARD_MITIGATION;
                break;
        }

        CurrentState = nextState;
        SetOutputs();
    }

    private void SetOutputs()
    {
        switch (CurrentState)
        {
            case GasSystemState.S0_STANDBY:
                V_Fan = false; B_Backup = false; S_Valve = false;
                L_Alarm = false; A_Alert = false; U_Visual = false;
                break;

            case GasSystemState.S1_HAZARD_MITIGATION:
            case GasSystemState.S2_FAULT_MITIGATION:
                V_Fan = true; B_Backup = false; S_Valve = true;
                L_Alarm = true; A_Alert = true; U_Visual = true;
                break;

            case GasSystemState.S3_WAITING_FOR_RESET:
                V_Fan = false; B_Backup = false; S_Valve = false;
                L_Alarm = true; A_Alert = true; U_Visual = true;
                break;

            case GasSystemState.S4_FAILSAFE_POWERFAIL:
                V_Fan = false; B_Backup = true; S_Valve = false;
                L_Alarm = false; A_Alert = false; U_Visual = false;
                break;

            case GasSystemState.S5_HAZARD_POWERFAIL:
                V_Fan = true; B_Backup = true; S_Valve = true;
                L_Alarm = true; A_Alert = true; U_Visual = true;
                break;
        }
    }
}

class Program
{
    // Fungsi dummy untuk simulasi input sensor (1=Aman, 0=Gagal)
    static bool ReadSensor(string name, bool value)
    {
        return value;
    }

    static void Main(string[] args)
    {
        GasSafetyFsm fsm = new GasSafetyFsm();
        bool G = true, T = true, P = true, C = true, F = true, R = false;

        Action printStatus = () => {
            Console.ForegroundColor = ConsoleColor.Yellow;
            Console.WriteLine($"\nSTATUS FSM: {fsm.CurrentState}");
            Console.ResetColor();
            // Perbaikan baris teks agar tidak error
            Console.WriteLine($" OUTPUT: Kipas(V)={fsm.V_Fan}, Backup(B)={fsm.B_Backup}, Katup(S)={fsm.S_Valve}");
            Console.WriteLine($"         Alarm(L)={fsm.L_Alarm}, Alert(A)={fsm.A_Alert}, Visual(U)={fsm.U_Visual}");
            Console.WriteLine("---------------------------------------------------------");
        };

        // Skenario 1: Sistem Normal
        fsm.Update(G, T, P, C, F, R);
        printStatus();

        // Skenario 2: Gas Bocor
        G = false;
        fsm.Update(ReadSensor("Gas", G), T, P, C, F, R);
        printStatus();

        // Skenario 3: Kipas Rusak (Fault)
        C = false;
        fsm.Update(G, T, P, ReadSensor("Arus Kipas", C), F, R);
        printStatus();

        // Skenario 4: PLN Mati (Critical Fail)
        P = false;
        fsm.Update(G, T, ReadSensor("Daya PLN", P), C, F, R);
        printStatus();

        // Skenario 5: PLN Pulih
        P = true;
        fsm.Update(G, T, ReadSensor("Daya PLN", P), C, F, R);
        printStatus();

        // Skenario 6: Bahaya Selesai
        G = true; C = true;
        fsm.Update(ReadSensor("Gas", G), T, P, ReadSensor("Arus Kipas", C), F, R);
        printStatus();

        // Skenario 7: Otorisasi Reset
        R = true;
        fsm.Update(G, T, P, C, F, ReadSensor("RFID", R));
        printStatus();

        // Console.ReadLine(); // Opsional: Agar terminal tidak langsung tertutup
    }
}