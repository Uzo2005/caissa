import ./parsePgn, ./parseFen

func convertPieceToChar(chesspiece: ChessPiece): char =
    case `chessPiece`:
        of King : 
            return 'K'
        of Queen : 
            return 'Q'
        of Knight : 
            return 'N'
        of Bishop : 
            return 'B'
        of Rook : 
            return 'R'
        of Pawn : 
            return 'P'
        of NoPiece:
            return ' '
proc updateBoardStateWithMove*(prevState: var BoardState, newMoveInfo: MoveInfo) =
    if not(newMoveInfo.isCastleMove):
        let 
            
            nextIndex =  (8*(8 - newMoveInfo.moveInfo.nextRow)) - (8 - newMoveInfo.moveInfo.nextCol) #this shit needs serious refactoring

        prevState.piecePlacement[nextIndex] = convertPieceToChar(newMoveInfo.moveInfo.piece)


# var
#     boardState = parseFen("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR b KQkq - 0 1")


# const 
#     gamesResourcePath = "./resources/games/"
# let
#     samplePgn = readfile(gamesResourcePath & "sample.pgn")
#     d4MoveInfo = parsePgn(samplePgn).chessMoves[0].whiteMove

# # echo boardState.piecePlacement
# echo "--------------------------------------------------------------"

# # boardState.updateBoardStateWithMove(d4MoveInfo)

# # echo boardState.piecePlacement

