import strutils, sequtils, algorithm

type CastlingOptions* = enum
    WhiteKingSide, WhiteQueenSide, BlackKingSide, BlackQueenSide

type BoardState* = object
    piecePlacement*: array[64, char]
    isWhiteActive*: bool
    castlingOptions*: set[CastlingOptions]
    enPassentSquare*: int
    halfMoveClock*: uint8
    fullMoveNumber*: int

const
    blackRookSymbol* = 'r'
    blackKnightSymbol* = 'n'
    blackBishopSymbol* = 'b'
    blackQueenSymbol* = 'q'
    blackKingSymbol* = 'k'
    blackPawnSymbol* = 'p'
    
    whiteRookSymbol* = 'R'
    whiteKnightSymbol* = 'N'
    whiteBishopSymbol* = 'B'
    whiteQueenSymbol* = 'Q'
    whiteKingSymbol* = 'K'
    whitePawnSymbol* = 'P'

    numberLabels = reversed(toSeq 1 .. 8)
    letterLabels = toSeq 'a' .. 'h'


func isNumber(x: char): bool =
  try:
    discard parseInt($x)
    result = true
  except ValueError:
    result = false

proc setBoardContents(fenInfo: seq[string], piecePlacement: var array[64, char]) =
    for x,row in fenInfo:
        var cursorPos = 0
        for column in row:
            if column.isNumber:
                #skip this amount of space on this row
                inc cursorPos, parseInt($column)
            else:
                piecePlacement[(x*8) + cursorPos] = column
                inc cursorPos

proc setActivePlayer(fenInfo: string, isWhiteActive: var bool) =
    case fenInfo:
        of "w":
            isWhiteActive = true
        of "b":
            isWhiteActive = false

proc setCastlingOptions(fenInfo: string, castlingOptions: var set[CastlingOptions]) =
    for option in fenInfo:
        case option:
            of 'K':
                castlingOptions.incl WhiteKingSide
            of 'Q':
                castlingOptions.incl WhiteQueenSide
            of 'k':
                castlingOptions.incl BlackKingSide
            of 'q':
                castlingOptions.incl BlackQueenSide
            of '-':
                castlingOptions = {}
            else:
                discard

proc setEnPassentSquare(fenInfo: string, enPassentSquare: var int) =
    case fenInfo:
        of "-":
            enPassentSquare = -1
        else:
            assert fenInfo.len == 2, "This does not look like a valid chess square"
            let
                column = letterLabels.find fenInfo[0]
                row = numberLabels.find parseInt($fenInfo[1])
            
            enPassentSquare = (row * 8) + column


proc parseFen*(fenStr: string): BoardState =
    let 
        fields = fenStr.splitWhiteSpace
        boardContents = fields[0].split("/")
        activeColor = fields[1]
        castlingOptions = fields[2]
        enPassentSquare = fields[3]
        halfMoveClock = parseUInt fields[4]
        fullMoveNumber = parseInt fields[5]

    assert fields.len == 6, "This is an invalid fen string, fields length is not 6"
    assert boardContents.len == 8, "This board doesnt have 8 rows"

    setBoardContents(boardContents, result.piecePlacement)
    setActivePlayer(activeColor, result.isWhiteActive)
    setCastlingOptions(castlingOptions, result.castlingOptions)
    setEnPassentSquare(enPassentSquare, result.enPassentSquare)

    result.halfMoveClock = halfMoveClock.uint8
    result.fullMoveNumber = fullMoveNumber
