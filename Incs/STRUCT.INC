'Structure to hold bounding boxes.
TYPE RectType
    Top    AS INTEGER
    Left   AS INTEGER
    Bottom AS INTEGER
    Right  AS INTEGER
END TYPE

'Structure to hold energy costs.
TYPE EnergyCostsType
    Move AS INTEGER
    Shot AS INTEGER
END TYPE

'Structure to hold coordenates.
TYPE CoordType
    X AS INTEGER
    Y AS INTEGER
END TYPE

'Structure to hold classes of enemy ships.
TYPE EnemyShipClassType
'Ship's boundaries:
    Boundaries         AS RectType
'Energy related fields:
    Cost               AS EnergyCostsType
    EnergyRestoreSpeed AS INTEGER
    MaxEnergy          AS INTEGER
'Ship behavior related fields:
    Acceleration       AS INTEGER
    Inteligence        AS INTEGER
'Ship's shot related fields:
    ShotBounds         AS RectType
    ShotType           AS INTEGER
    ShotSpeed          AS INTEGER
END TYPE

'Structure to hold information of on-screen shots.
TYPE ShotType
'Shot fired flag:
    Fired       AS INTEGER
'Shot's boundaries:
    Boundaries  AS RectType
'Shot behavior related fields:
    Direction   AS INTEGER
    Position    AS CoordType
    ShotType    AS INTEGER
    Speed       AS INTEGER
END TYPE

'Structure to hold ship information.
TYPE ShipType
'Ship's boundaries:
    Boundaries         AS RectType
'Ship's energy related fields:
    Energy             AS INTEGER
    EnergyRestoreSpeed AS INTEGER
    MaxEnergy          AS INTEGER
'Ship's behavior related fields:
    Acceleration       AS INTEGER
    Position           AS CoordType
    ShipType           AS INTEGER
    Speed              AS INTEGER
    State              AS INTEGER
'Ship's shot related fields:
    ShotBounds         AS RectType
    ShotType           AS INTEGER
    ShotSpeed          AS INTEGER
END TYPE

'Structure to hold star's information.
TYPE StarType
    C AS INTEGER
    S AS INTEGER
    X AS INTEGER
    Y AS INTEGER
END TYPE

'Structure to hold hall of fame entries.
TYPE EntryType
    PName AS STRING * 30
    Score AS LONG
END TYPE

