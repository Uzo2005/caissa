import ./parsePgn, ./parseFen

# MoveInfo* = object
#         isCheck: bool
#         isCheckMate: bool
#         isCaptureMove: bool
#         case isCastleMove: bool
#             of true:
#                 castleType: CastlingType
#             else:
#                 moveInfo: tuple[piece: AllChessPieces, col: int, row: int]
        
#         case isHighlyAmbiguousMove: bool #when both file and rank info will clarify move
#             of true:
#                     currentCol: int
#                     currentRow: int
#             else:
#                 case isSlightlyAmbiguousMove: bool #when either file or rank info will clarify move
#                     of true:
#                         case fileInfoCanClarify: bool
#                             of true:
#                                 currentColInfo: int
#                             else:
#                                 currentRowInfo: int
#                     else:
#                         discard

proc updateBoardStateWithMoveInfo*(prevState: var BoardState, newMoveInfo: MoveInfo) =
    if not(newMoveInfo.isCastleMove):
        let 
            index = (newMoveInfo.moveInfo.col * 8) + newMoveInfo.moveInfo.row

        prevState.piecePlacement[index] = 'P'


        # echo newMoveInfo.moveInfo

var
    boardState = parseFen("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR b KQkq - 0 1")


const 
    gamesResourcePath = "./resources/games/"
let
    samplePgn = readfile(gamesResourcePath & "sample.pgn")
    d4MoveInfo = parsePgnMoveText(samplePgn).chessMoves[0].whiteMove

# echo boardState.piecePlacement
echo "--------------------------------------------------------------"

# boardState.updateBoardStateWithMoveInfo(d4MoveInfo)

# echo boardState.piecePlacement

