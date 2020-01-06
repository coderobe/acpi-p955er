DefinitionBlock ("", "SSDT", 2, "hack", "coderobe", 0)
{
    // Required external symbols
    External (_SB.WMI.WMBB, MethodObj)
    External (_SB_.PCI0.LPCB.EC__, DeviceObj)
    External (_SB_.PCI0.LPCB.EC__.ECOK, UnknownObj)
    // Custom fan registers
    External (_SB_.PCI0.LPCB.EC__.FC00, UnknownObj)
    External (_SB_.PCI0.LPCB.EC__.FC01, UnknownObj)
    External (_SB_.PCI0.LPCB.EC__.FG00, UnknownObj)
    External (_SB_.PCI0.LPCB.EC__.FG01, UnknownObj)
    External (_SB_.PCI0.LPCB.EC__.FG10, UnknownObj)
    External (_SB_.PCI0.LPCB.EC__.FG11, UnknownObj)

    Device (CDR)
    {
        // Declare as generic device
        Name (_HID, EisaId ("PNP0C02"))
        Name (_CID, "CODEROBE")
        // Proxy for WMBB
        // as direct calls cause a panic (o.O)
        Method (WMI, 3, Serialized)
        {
            \_SB.WMI.WMBB(Arg0, Arg1, Arg2)
        }
        Device (FAN)
        {
            // Declare as generic device
            Name (_HID, EisaId ("PNP0C02"))
            // WMI dispatch method
            Method (CALL, 1, Serialized)
            {
                ^^WMI (0, 0x79, Arg0)
            }
            // Reset controller
            Method (RST, 0, Serialized)
            {
                CALL (0x1000000)
            }
            // Enable auto-mode
            Method (AUTO, 0, Serialized)
            {
                RST ()
                CALL (0x7000000)
            }
        }
        Device (LED)
        {
            // Declare as generic device
            Name (_HID, EisaId ("PNP0C02"))
            // WMI dispatch method
            Method (CALL, 1, Serialized)
            {
                ^^WMI (0, 0x67, Arg0)
            }
            // Reset controller
            Method (RST, 0, Serialized)
            {
                CALL (0x10000000)
            }
            // Enable LEDs
            Method (ON, 0, Serialized)
            {
                CALL (0xE007F001)
            }
            // Disable LEDs
            Method (OFF, 0, Serialized)
            {
                CALL (0xE0003001)
            }
            // LED color state
            Name (LED1, 0)
            Name (LED2, 0)
            Name (LED3, 0)
            // LED current mode
            // 0 - custom color
            // 1 - random
            // 2 - breathe
            // 3 - cycle
            // 4 - wave
            // 5 - dance
            // 6 - tempo
            // 7 - flash
            Name (CMOD, 0)
            // LED WMI offsets
            Name (L1OF, 0xF0000000)
            Name (L2OF, 0xF1000000)
            Name (L3OF, 0xF2000000)
            // Set LED mode
            Method (MODE, 1, Serialized)
            {
                If (Arg0 > 7)
                {
                    Store ("In CDR.LED.MODE: Arg0 out of range, given:", Debug)
                    Store (Arg0, Debug)
                    Return (1)
                }
                CMOD = Arg0
                Switch (Arg0)
                {
                    Case (0) // Custom color mode
                    {
                        COLU ()
                        Return (0)
                    }
                    Case (1) // Random color
                    {
                        Local0 = 0x70000000
                    }
                    Case (2) // "Dance"
                    {
                        Local0 = 0x80000000
                    }
                    Case (3) // "Tempo"
                    {
                        Local0 = 0x90000000
                    }
                    Case (4) // "Flash"
                    {
                        Local0 = 0xA0000000
                    }
                    Case (5) // "Wave"
                    {
                        Local0 = 0xB0000000
                    }
                    Case (6) // "Breathe"
                    {
                        Local0 = 0x1002a000
                    }
                    Case (7) // "Cycle"
                    {
                        Local0 = 0x33010000
                    }
                }
                RST ()
                CALL (Local0)
                Return (0)
            }
            // Get current mode
            Method (GMOD, 0, Serialized)
            {
                Return (CMOD)
            }
            // Update LED color
            Method (COLU, 0, Serialized)
            {
                RST ()
                CALL (\CDR.LED.L1OF | \CDR.LED.LED1)
                CALL (\CDR.LED.L2OF | \CDR.LED.LED2)
                CALL (\CDR.LED.L3OF | \CDR.LED.LED3)
            }
            // Set multicolor RGB
            Method (COLM, 3, Serialized)
            {
                LED1 = Arg0
                LED2 = Arg1
                LED3 = Arg2
                COLU ()
            }
            // Set single color RGB
            Method (COL, 1, Serialized)
            {
                LED1 = Arg0
                LED2 = Arg0
                LED3 = Arg0
                COLU ()
            }
            // Set LED 1 color RGB
            Method (COL1, 1, Serialized)
            {
                LED1 = Arg0
                CALL (L1OF | LED1)
            }
            // Set LED 2 color RGB
            Method (COL2, 1, Serialized)
            {
                LED2 = Arg0
                CALL (L2OF | LED2)
            }
            // Set LED 3 color RGB
            Method (COL3, 1, Serialized)
            {
                LED3 = Arg0
                CALL (L3OF | LED3)
            }
            // Store brightness level (max 255)
            Name (LVLS, 64)
            // Set brightness level
            Method (LVL, 1, Serialized)
            {
                LVLS = Arg0
                CALL (0xF4000000 | LVLS)
            }
            // Increase brightness
            Method (LVLU, 0, Serialized)
            {
                If (LVLS < 248)
                {
                    LVLS = LVLS + 8
                    LVL (LVLS)
                    Return (0)
                }
                Return (1)
            }
            // Decrease brightness
            Method (LVLD, 0, Serialized)
            {
                If (LVLS > 7)
                {
                    LVLS = LVLS - 8
                    LVL (LVLS)
                    Return (0)
                }
                Return (1)
            }
        }
    }

    // Fan interface adapter
    Device (SMCD)
    {
        // Declare as generic device
        Name (_HID, EisaId ("PNP0C02"))
        // Define fan aliases
        Name (
            TACH,
            Package (0x06) {
                "CPU Fan", "FAN0",
                "GPU Fan #1", "FAN1",
                "GPU Fan #2", "FAN2"
            }
        )
        // Fan control helper method
        Method (B1B2, 2, NotSerialized)
        {
            Return(Or(Arg0, ShiftLeft(Arg1, 8)))
        }
        // Fan speed read methods
        Method (FAN0, 0, Serialized)
        {
            If (\_SB.PCI0.LPCB.EC.ECOK)
            {
                Local0 = B1B2(\_SB.PCI0.LPCB.EC.FC01, \_SB.PCI0.LPCB.EC.FC00)
                If (Local0 <= 0)
                {
                    Return (0)
                }
                Local0 = 2156220 / Local0
                Return (Local0)
            }
            Return (0)
        }

        Method (FAN1, 0, Serialized)
        {
            If (\_SB.PCI0.LPCB.EC.ECOK)
            {
                Local0 = B1B2(\_SB.PCI0.LPCB.EC.FG01, \_SB.PCI0.LPCB.EC.FG00)
                If (Local0 <= 0)
                {
                    Return (0)
                }
                Local0 = 2156220 / Local0
                Return (Local0)
            }
            Return (0)
        }

        Method (FAN2, 0, Serialized)
        {
            If (\_SB.PCI0.LPCB.EC.ECOK)
            {
                Local0 = B1B2(\_SB.PCI0.LPCB.EC.FG11, \_SB.PCI0.LPCB.EC.FG10)
                If (Local0 <= 0)
                {
                    Return (0)
                }
                Local0 = 2156220 / Local0
                Return (Local0)
            }
            Return (0)
        }
    }
}

