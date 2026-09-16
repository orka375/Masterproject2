# Robot Command Standard Patch

Basis: aktuelle `Masterproject2`-Dateien vom 2026-09-11 (FB_1_ROB/FB_2_ROB_MANIP/FB_1_CommunicationModul/UR/Meca Stand nach dem Recovery-Patch).

## Geänderte Dateien

- `POUs/Robots/FB_1_ROB.TcPOU`
  - `Ready` als generische Pflicht-Property ergänzt (`Busy` bleibt geerbt aus `FB_0_Base`).
  - `CanAcceptCommand` blockiert parallele semantische Commands.
  - aktiver Command fließt in das geerbte `Busy` ein.
  - `CommandID/CommandState/CommandResult` bleiben gelatcht.
  - `CancelCommand` akzeptiert nur die aktuell gelatchte CommandID.

- `POUs/Communication/FB_1_CommunicationModul.TcPOU`
  - gemeinsamer COMM-Lifecycle: `CanAcceptCommand`, `AcceptedCommandID`, `ActiveCommandID`, `CommandBusy`, `CommandState`, `CommandResult`.
  - `ResetCommunication()` ergänzt.
  - Lifecycle-Backing liegt in FB_1, damit auch ein `POINTER TO FB_1_CommunicationModul` korrekte Werte sieht.

- `POUs/Robots/UR/FB_2_COMM_UR.TcPOU`
  - URScript-Transport hinter COMM-API (`BeginCommand`, `AppendCommandLine`, `SendCommand`).
  - RTDE Register werden hier auf `eProgress/eResult` gemappt.
  - `CancelCommand`, `StopMotion`, `ResetCommunication` implementiert.
  - terminale Ergebnisse werden gelatcht; kein automatischer Replay.

- `POUs/Robots/UR/ROBOT_UR.TcPOU`
  - erzeugt weiterhin die CommandID und übersetzt `eBA` nach URScript.
  - greift für Transport nicht mehr direkt auf `UR_COMM.Script` zu.
  - wertet Command-Fortschritt nicht mehr selbst aus RTDE-Rohstatus aus, sondern mappt den generischen COMM-Lifecycle.

- `POUs/Robots/Mecademic/FB_2_COMM_MECA.TcPOU`
  - `SendCommand(CommandID, native...)` als neue Standard-Transportaktion.
  - `QueueMotion()` bleibt als kompatibler Alias bestehen.
  - Ack/Running/Done/Error-Erkennung aus EtherCAT liegt vollständig in COMM.
  - `SendHome(CommandID)`, `CancelCommand`, `StopMotion`, `ResetCommunication` ergänzt.

- `POUs/Robots/Mecademic/ROBOT_MECA500.TcPOU`
  - CommandID wird ausschließlich im Robot-Layer erzeugt.
  - verwendet `SendCommand`/`SendHome`.
  - Robot-Lifecycle wird nur noch aus `MECA_COMM.CommandState/CommandResult` übernommen.
  - `BA_Annulate` auf `MECA_COMM.CancelCommand` gemappt.

## Bereits konform, daher bewusst nicht geändert

- `FB_2_ROB_MANIP.TcPOU`: die vorhandenen `MoveLinear`, `MoveJoint`, `MoveLinearRelative`, `MoveJointRelative`, `MoveJointAbsolute`, `Home` liefern bereits `UINT` und rufen intern `BA_Handler()`.
- `Skill_PickPlace.TcPOU`: benutzt bereits `MoveJoint/MoveLinear` und wartet über `CommandID/CommandState/CommandResult`; kein direkter `BA_Handler`-Zugriff mehr.
- `Skill_StandardExample.TcPOU`: enthält bereits Subskill-Execute/Done/Result sowie MoveID + Timeout + `CancelCommand`.
- `eProgress` und `eResult`: unverändert wiederverwendet; kein neuer Lifecycle-Enum.

## Semantik

`CommandID = 0` = kein gültiger Auftrag.

`INIT -> ACKNOWLEDGE -> RUNNING -> FINALIZED` bzw. `ABORTED`.

`CommandResult`: `NONE` während laufend; `SUCCESS`, `FAILURE` oder `ERROR` terminal.

`CommandID`, `CommandState`, `CommandResult` auf Robot-Ebene bleiben nach terminalem Abschluss erhalten und werden erst überschrieben, wenn der nächste gültige Auftrag von der jeweiligen COMM lokal übernommen wurde.

`SendCommand() = TRUE` bedeutet nur lokale Übernahme durch COMM, niemals erfolgreiche physische Ausführung.

## Validierung

Alle geänderten `.TcPOU` wurden als XML geparst. Kein `RUNTIME.plcproj`-Update nötig, da keine neue PLC-Datei hinzugefügt wurde.
Ein echter TwinCAT-Compile bleibt erforderlich.
