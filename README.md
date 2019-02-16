# acpi-p955er
ACPI DSDT/SSDT extension &amp; tools to control Clevo P955ER peripherals (LED, FAN)

---

# dsdt.patch

This file contains a patch for your DSDT defining fan speed register operating regions in the EC

It is required to make use of the SMCD interfaces in `ssdt-cdr.dsl`

# ssdt-cdr.dsl

This file contains a custom ACPI SSDT buildable with `iasl`.  


It
- defines a WMI dispatch method
- exposes fan read interfaces as SMC device `SMCD`
- exposes numerous helper methods for fan & led control under `CDR.FAN` and `CDR.LED`

---

# License

This project, originally authored by Robin Broda, is licensed under the GNU Affero General Public License 3.  

You can find a copy of the full license text in `LICENSE`
