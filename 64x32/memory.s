.segment "ZEROPAGE"
  Temp: .res 16
  retraces: .res 1
  keydown: .res 2
  keylast: .res 2
  keynew:  .res 2
  PlayerX: .res 1
  PlayerY: .res 1
  WhichNMI: .res 1
  OamPtr: .res 1
  WhichTool: .res 1

  ShowSecondCursor: .res 1
  PlayerX2: .res 1
  PlayerY2: .res 1

  RowCount: .res 1
  Neighbors: .res 1
  NeedRedrawGrid: .res 1
  NeedRedrawGrid2: .res 1
  NeedRedrawGrid3: .res 1
  IsPaused: .res 1
  KeyRepeat: .res 2

  CurGrid = $300
  RefGrid = $400
  CurGrid2 = $500
  RefGrid2 = $600

CellBirthTL = $100-73
CellSurviveTL = CellBirthTL + 9
CellBirthTR = CellSurviveTL + 9
CellSurviveTR = CellBirthTR + 9
CellBirthBL = CellSurviveTR + 9
CellSurviveBL = CellBirthBL + 9
CellBirthBR = CellSurviveBL + 9
CellSurviveBR = CellBirthBR + 9

