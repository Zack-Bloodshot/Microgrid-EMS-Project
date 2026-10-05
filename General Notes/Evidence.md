# Evidence Note: Microgrid EMS Project Justification

## Project Title
Design & Modelling of a Cost-Optimized Energy Management System (EMS) for a Grid-Tied PV Microgrid

---

## 1. Technical & Regulatory Evidence

### Real-World Utility Implementation of Battery Storage
* APDCL actively tenders and deploys hybrid rooftop solar microgrids equipped with Battery Energy Storage Systems (BESS) for commercial/institutional facilities [[bid-NRE-219.pdf|bid-NRE-219.pdf]].
* Specific deployment examples include a 30 kWp grid-interactive rooftop solar PV system with a 240 V, 300 Ah VRLA battery bank installed at government facilities in Guwahati [[bid-NRE-219.pdf|bid-NRE-219.pdf]]].

### Permissibility under Government Schemes
* The PM-Surya Ghar: Muft Bijli Yojana explicitly permits rooftop solar installations to include battery storage systems and hybrid configurations [[202404162127034309.pdf|202404162127034309.pdf]].
* Non-metered grid-connected, behind-the-meter, and battery hybrid systems are recognized under metering and inspection protocols [[202404162127034309.pdf|202404162127034309.pdf]].

### Time-of-Day (ToD) Tariff Structure
* APDCL enforces dynamic Time-of-Day (ToD) tariff multiplier rates across time slots [[TariffnoticeforFY2026-27.pdf|TariffnoticeforFY2026-27.pdf]]:
  * **Solar Hours (09:00 - 17:00 hrs):** 80% of normal energy charges [[TariffnoticeforFY2026-27.pdf|TariffnoticeforFY2026-27.pdf]].
  * **Peak Hours (17:00 - 22:00 hrs):** 120% of normal energy charges [[TariffnoticeforFY2026-27.pdf|TariffnoticeforFY2026-27.pdf]].
  * **Normal Hours (22:00 - 09:00 hrs):** 100% of normal energy charges [[TariffnoticeforFY2026-27.pdf|TariffnoticeforFY2026-27.pdf]].
* ToD tariffs are available at the option of eligible consumers via communication with APDCL [[TariffnoticeforFY2026-27.pdf|TariffnoticeforFY2026-27.pdf]].

### Regional Financial Subsidies
* The combined financial assistance structure in Assam for residential installations includes [[Notification-Operational Guidelines.pdf|Notification-Operational Guidelines.pdf]]:
  * **1 kW System:** ₹30,000 Central + ₹15,000 State = ₹45,000 Total Subsidy [[Notification-Operational Guidelines.pdf|Notification-Operational Guidelines.pdf]].
  * **2 kW System:** ₹60,000 Central + ₹30,000 State = ₹90,000 Total Subsidy [[Notification-Operational Guidelines.pdf|Notification-Operational Guidelines.pdf]].
  * **3 kW System & above:** ₹78,000 Central + ₹45,000 State = ₹1,23,000 Total Subsidy [[Notification-Operational Guidelines.pdf|Notification-Operational Guidelines.pdf]].

---

## Source File References
* [[TariffnoticeforFY2026-27.pdf|APDCL FY 2026-27 Tariff Schedule]]
* [[202404162127034309.pdf|MNRE PM-Surya Ghar Scheme Guidelines]]
* [[bid-NRE-219.pdf|APDCL Tender RfS No. APDCL/CGM (NRE)/NRE-219/2026-27/123]]
* [[Notification-Operational Guidelines.pdf|Government of Assam Operational Guidelines for PM-Surya Ghar]]

----
# Understanding Battery Classification in Grid-Tied Solar Systems: The DISCOM Perspective

## 1. Why a Battery is NOT Classified as a Standard Load
A standard electrical load (such as a motor, air conditioner, or heater) is a passive, unidirectional consumer of power. In contrast, a DISCOM classifies a Battery Energy Storage System (BESS) as an **Energy Storage System (ESS)** or **Distributed Energy Resource (DER)** because it acts as a dynamic, bidirectional energy asset.

---

## 2. Key Regulatory & Utility Concerns

### A. Reverse Power Flow & Islanding Hazards
* **The Hazard:** An ordinary load can never feed electricity back into the distribution grid. A BESS, however, can act as a active generator.
* **Line-Worker Safety:** If utility grid power fails during maintenance, an unmanaged BESS could back-feed high voltage into dead distribution lines, creating a fatal risk for DISCOM field personnel.
* **Mandatory Interconnection Standards:** Because of this bidirectional capability, DISCOMs require hybrid installations to include certified anti-islanding protection (IEC 62116) and relay-operated automatic isolation switches before approving a grid connection. Standard loads require no such grid-interconnection approvals.

### B. Time-of-Day (ToD) Tariffs & Net-Metering Mechanics
* **Peak Demand Management:** DISCOMs enforce Time-of-Day (ToD) tariff structures to discourage heavy grid draw during peak hours.
* **Strategic Energy Shifting:** A BESS allows consumers to store energy during off-peak or solar hours and substitute grid draw during peak pricing periods.
* **Accounting Compliance:** Because a BESS directly alters the time, magnitude, and direction of energy crossing the boundary meter, it is regulated under specific Net-Metering / EXIM (Export-Import) framework rules enforced by State Electricity Regulatory Commissions.

### C. Impact on Local Distribution Infrastructure
* **Grid Load vs. Grid Asset:** While a standard load adds strain to local distribution transformers during peak hours, an EMS-managed BESS can perform peak shaving and voltage regulation, actively relieving local transformer stress.
* **Utility Utility Deployment:** Utility-driven commercial BESS tenders are designed specifically to utilize storage as a grid-balancing asset rather than a simple consumption load.

---

## 3. Summary Statement
To a DISCOM, a battery is a **Distributed Energy Resource (DER)**. While it acts as a load during its charging phase, its ability to discharge and offset grid draw changes the electrical dynamics of the grid connection. This dual capability is why utilities enforce specialized interconnection, safety, and bi-directional metering protocols for hybrid installations.

---
