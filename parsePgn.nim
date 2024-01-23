import strutils, sequtils, algorithm
import npeg

type 
    GameScore* = enum
        WhiteWins, BlackWins, Draw

    ChessPiece* = enum
        NoPiece, Rook, Knight, Bishop, Queen, King, Pawn
        # WhiteRook, WhiteKnight, WhiteBishop, WhiteQueen, WhiteKing, WhitePawn
        # BlackRook, BlackKnight, BlackBishop, BlackQueen, BlackKing, BlackPawn

    CastlingType = enum
        KingSideCastle, QueenSideCastle

    MoveInfo* = object
        isCheck*: bool
        isCheckMate*: bool
        isCaptureMove*: bool
        case isCastleMove*: bool
            of true:
                castleType*: CastlingType
            else:
                moveInfo*: tuple[piece: ChessPiece, nextCol: int, nextRow: int]
        
        case isHighlyAmbiguousMove: bool #when both col and row info are necessary to clarify which chess piece to move
            of true:
                currentCol*: int
                currentRow*: int
            else:
                case colInfoCanClarify*: bool 
                    of true: #when only col info can clarify which chess piece to move
                        currentColInfo*: int
                    else: #when only row info can clarify which chess piece to move
                        currentRowInfo*: int


    ChessMove* = tuple[moveId: int, whiteMove: MoveInfo, blackMove: MoveInfo]

    ChessGame* = object
        chessMoves*: seq[ChessMove]
        outcome*: GameScore

const
    gamesResources = "./resources/games/"
    samplePgn = readfile(gamesResources & "sample.pgn")
    numberLabels = toSeq 1 .. 8 #TODO: make this all chars to save compute
    letterLabels = toSeq 'a' .. 'h'

template report(msg: varargs[string]) =
    when not defined(release):
        echo `msg`
        quit(1)

func convertToGameScore(strScore: string): GameScore =
    case strScore:
        of "1-0":
            result = WhiteWins
        of "0-1":
            result = BlackWins
        of "1/2-1/2":
            result = Draw

proc parseChessMove(move: string): MoveInfo =
    case move.len:
        of 2: #a pawn move
            result.moveInfo =  (piece: Pawn, nextCol: letterLabels.find(move[0]), nextRow: numberLabels.find(parseInt $move[1]))
        
        of 3:
            if move == "O-O": #king-side castle
                result.iscastleMove = true
                result.castleType = KingSideCastle
            else:
                case move[0]: #classic move like Bd1
                    of 'K':
                        result.moveInfo.piece = King
                        result.moveInfo.nextCol = letterLabels.find(move[1])
                        result.moveInfo.nextRow = numberLabels.find(parseInt $move[2])
                    of 'Q':
                        result.moveInfo.piece = Queen
                        result.moveInfo.nextCol = letterLabels.find(move[1])
                        result.moveInfo.nextRow = numberLabels.find(parseInt $move[2])
                    of 'N':
                        result.moveInfo.piece = Knight
                        result.moveInfo.nextCol = letterLabels.find(move[1])
                        result.moveInfo.nextRow = numberLabels.find(parseInt $move[2])
                    of 'B':
                        result.moveInfo.piece = Bishop
                        result.moveInfo.nextCol = letterLabels.find(move[1])
                        result.moveInfo.nextRow = numberLabels.find(parseInt $move[2])
                    of 'R':
                        result.moveInfo.piece = Rook
                        result.moveInfo.nextCol = letterLabels.find(move[1])
                        result.moveInfo.nextRow = numberLabels.find(parseInt $move[2])
                    of 'P':
                        result.moveInfo.piece = Pawn
                        result.moveInfo.nextCol = letterLabels.find(move[1])
                        result.moveInfo.nextRow = numberLabels.find(parseInt $move[2])

                    else: #a pawn check like g3+ or a mate like h4#
                        result.moveInfo.piece = Pawn
                        if move[2] == '+':
                            result.isCheck = true
                            result.moveInfo.nextCol = letterLabels.find(move[0])
                            result.moveInfo.nextRow = numberLabels.find(parseInt $move[1])
                        elif move[2] == '#':
                            result.isCheckMate = true
                            result.moveInfo.nextCol = letterLabels.find(move[0])
                            result.moveInfo.nextRow = numberLabels.find(parseInt $move[1])
                        else:
                            report("Unparseable move: ", move)


        of 4: #capture-move like Qxd2 or a check(mate)ing move like Nf5+ or even a check(mate) from king-side castle -> O-0#
            if move[0..2] == "0-0":
                result.isCastleMove = true
                case move[3]:
                    of '+':
                        result.isCheck = true
                    of '#':
                        result.isCheckMate = true
                    else:
                        report("Unparseable move: ", move)
            elif move[1] == 'x': #capture move
                result.isCaptureMove = true
                case move[0]:
                    of 'K':
                        result.moveInfo.piece = King
                        result.moveInfo.nextCol = letterLabels.find(move[2])
                        result.moveInfo.nextRow = numberLabels.find(parseInt $move[3])
                    of 'Q':
                        result.moveInfo.piece = Queen
                        result.moveInfo.nextCol = letterLabels.find(move[2])
                        result.moveInfo.nextRow = numberLabels.find(parseInt $move[3])
                    of 'N':
                        result.moveInfo.piece = Knight
                        result.moveInfo.nextCol = letterLabels.find(move[2])
                        result.moveInfo.nextRow = numberLabels.find(parseInt $move[3])
                    of 'B':
                        result.moveInfo.piece = Bishop
                        result.moveInfo.nextCol = letterLabels.find(move[2])
                        result.moveInfo.nextRow = numberLabels.find(parseInt $move[3])
                    of 'R':
                        result.moveInfo.piece = Rook
                        result.moveInfo.nextCol = letterLabels.find(move[2])
                        result.moveInfo.nextRow = numberLabels.find(parseInt $move[3])
                    of 'P':
                        result.moveInfo.piece = Pawn
                        result.moveInfo.nextCol = letterLabels.find(move[2])
                        result.moveInfo.nextRow = numberLabels.find(parseInt $move[3])
                    else: #pawn captures something like fxg4
                        result.moveInfo.piece = Pawn
                        result.moveInfo.nextCol = letterLabels.find(move[2])
                        result.moveInfo.nextRow = numberLabels.find(parseInt $move[3])
            
            elif move[3] == '+': #check
                result.isCheck = true
                case move[0]:
                    of 'K':
                        result.moveInfo.piece = King
                        result.moveInfo.nextCol = letterLabels.find(move[1])
                        result.moveInfo.nextRow = numberLabels.find(parseInt $move[2])
                    of 'Q':
                        result.moveInfo.piece = Queen
                        result.moveInfo.nextCol = letterLabels.find(move[1])
                        result.moveInfo.nextRow = numberLabels.find(parseInt $move[2])
                    of 'N':
                        result.moveInfo.piece = Knight
                        result.moveInfo.nextCol = letterLabels.find(move[1])
                        result.moveInfo.nextRow = numberLabels.find(parseInt $move[2])
                    of 'B':
                        result.moveInfo.piece = Bishop
                        result.moveInfo.nextCol = letterLabels.find(move[1])
                        result.moveInfo.nextRow = numberLabels.find(parseInt $move[2])
                    of 'R':
                        result.moveInfo.piece = Rook
                        result.moveInfo.nextCol = letterLabels.find(move[1])
                        result.moveInfo.nextRow = numberLabels.find(parseInt $move[2])
                    of 'P':
                        result.moveInfo.piece = Pawn
                        result.moveInfo.nextCol = letterLabels.find(move[1])
                        result.moveInfo.nextRow = numberLabels.find(parseInt $move[2])
                    else:
                        report("Unparseable move: ", move)

            elif move[3] == '#': #mate
                result.isCheckMate = true
                case move[0]:
                    of 'K':
                        result.moveInfo.piece = King
                        result.moveInfo.nextCol = letterLabels.find(move[1])
                        result.moveInfo.nextRow = numberLabels.find(parseInt $move[2])
                    of 'Q':
                        result.moveInfo.piece = Queen
                        result.moveInfo.nextCol = letterLabels.find(move[1])
                        result.moveInfo.nextRow = numberLabels.find(parseInt $move[2])
                    of 'N':
                        result.moveInfo.piece = Knight
                        result.moveInfo.nextCol = letterLabels.find(move[1])
                        result.moveInfo.nextRow = numberLabels.find(parseInt $move[2])
                    of 'B':
                        result.moveInfo.piece = Bishop
                        result.moveInfo.nextCol = letterLabels.find(move[1])
                        result.moveInfo.nextRow = numberLabels.find(parseInt $move[2])
                    of 'R':
                        result.moveInfo.piece = Rook
                        result.moveInfo.nextCol = letterLabels.find(move[1])
                        result.moveInfo.nextRow = numberLabels.find(parseInt $move[2])
                    of 'P':
                        result.moveInfo.piece = Pawn
                        result.moveInfo.nextCol = letterLabels.find(move[1])
                        result.moveInfo.nextRow = numberLabels.find(parseInt $move[2])
                    else: 
                        report("Unparseable move: ", move)
            
            else: #likely a disambiguation move like Rac1
                case move[0]:
                    of 'K':
                        result.moveInfo.piece = King
                    of 'Q':
                        result.moveInfo.piece = Queen
                    of 'N':
                        result.moveInfo.piece = Knight
                    of 'B':
                        result.moveInfo.piece = Bishop
                    of 'R':
                        result.moveInfo.piece = Rook
                    of 'P':
                        result.moveInfo.piece = Pawn
                    else: 
                        report("Unparseable move: ", move)
                
                if move[1].isDigit:
                    result.currentRowInfo = numberLabels.find(parseInt $move[1])
                else:
                    result.colInfoCanClarify = true
                    result.currentColInfo = letterLabels.find(move[1])

                result.moveInfo.nextCol = letterLabels.find(move[2])
                result.moveInfo.nextRow = numberLabels.find(parseInt $move[3])
            
        of 5: #capture-move with check(mate) like Qxd2# or a queenside castle O-O-O, or even a pawn capture which leads to check(mate) like gxf5#, or an ambiguos move clarified with something like Ra3g3, even Raxf3
            if move == "O-O-O":
                result.isCastleMove = true
                result.castleType = QueenSideCastle
            elif move[1] == 'x': #capture move
                result.isCaptureMove = true
                case move[0]:
                    of 'K':
                        result.moveInfo.piece = King
                        result.moveInfo.nextCol = letterLabels.find(move[2])
                        result.moveInfo.nextRow = numberLabels.find(parseInt $move[3])
                    of 'Q':
                        result.moveInfo.piece = Queen
                        result.moveInfo.nextCol = letterLabels.find(move[2])
                        result.moveInfo.nextRow = numberLabels.find(parseInt $move[3])
                    of 'N':
                        result.moveInfo.piece = Knight
                        result.moveInfo.nextCol = letterLabels.find(move[2])
                        result.moveInfo.nextRow = numberLabels.find(parseInt $move[3])
                    of 'B':
                        result.moveInfo.piece = Bishop
                        result.moveInfo.nextCol = letterLabels.find(move[2])
                        result.moveInfo.nextRow = numberLabels.find(parseInt $move[3])
                    of 'R':
                        result.moveInfo.piece = Rook
                        result.moveInfo.nextCol = letterLabels.find(move[2])
                        result.moveInfo.nextRow = numberLabels.find(parseInt $move[3])
                    of 'P':
                        result.moveInfo.piece = Pawn
                        result.moveInfo.nextCol = letterLabels.find(move[2])
                        result.moveInfo.nextRow = numberLabels.find(parseInt $move[3])
                    else: #likely a pawn capture like gxf5+ or gxf5#
                        case move[4]:
                            of '+':
                                result.moveInfo.piece = Pawn
                                result.moveInfo.nextCol = letterLabels.find(move[2])
                                result.moveInfo.nextRow = numberLabels.find(parseInt $move[3])
                            of '#':
                                result.moveInfo.piece = Pawn
                                result.moveInfo.nextCol = letterLabels.find(move[2])
                                result.moveInfo.nextRow = numberLabels.find(parseInt $move[3])
                            else:
                                report("Unparseable move: ", move)

                case move[4]:
                    of '+':
                        result.isCheck = true
                    of '#':
                        result.isCheckMate = true
                    else:
                        echo "Unparseable move: ", move
            elif move[2] == 'x': #Raxf3 
                result.isCaptureMove = true
                case move[0]:
                    of 'K':
                        result.moveInfo.piece = King
                        result.moveInfo.nextCol = letterLabels.find(move[3])
                        result.moveInfo.nextRow = numberLabels.find(parseInt $move[4])
                    of 'Q':
                        result.moveInfo.piece = Queen
                        result.moveInfo.nextCol = letterLabels.find(move[3])
                        result.moveInfo.nextRow = numberLabels.find(parseInt $move[4])
                    of 'N':
                        result.moveInfo.piece = Knight
                        result.moveInfo.nextCol = letterLabels.find(move[3])
                        result.moveInfo.nextRow = numberLabels.find(parseInt $move[4])
                    of 'B':
                        result.moveInfo.piece = Bishop
                        result.moveInfo.nextCol = letterLabels.find(move[3])
                        result.moveInfo.nextRow = numberLabels.find(parseInt $move[4])
                    of 'R':
                        result.moveInfo.piece = Rook
                        result.moveInfo.nextCol = letterLabels.find(move[3])
                        result.moveInfo.nextRow = numberLabels.find(parseInt $move[4])
                    of 'P':
                        result.moveInfo.piece = Pawn
                        result.moveInfo.nextCol = letterLabels.find(move[3])
                        result.moveInfo.nextRow = numberLabels.find(parseInt $move[4])
                    else:
                        report("Unparseable move: ", move)

                if move[1].isDigit:
                    result.currentRowInfo = numberLabels.find(parseInt $move[1])
                else:
                    result.colInfoCanClarify = true
                    result.currentColInfo = letterLabels.find(move[1])
            else: #probably stuff like Ra3f3
                result.isHighlyAmbiguousMove = true
                result.currentCol = letterLabels.find(move[1])
                result.currentRow = numberLabels.find(parseInt $move[2])
                case move[0]:
                    of 'K':
                        result.moveInfo.piece = King
                        result.moveInfo.nextCol = letterLabels.find(move[3])
                        result.moveInfo.nextRow = numberLabels.find(parseInt $move[4])
                    of 'Q':
                        result.moveInfo.piece = Queen
                        result.moveInfo.nextCol = letterLabels.find(move[3])
                        result.moveInfo.nextRow = numberLabels.find(parseInt $move[4])
                    of 'N':
                        result.moveInfo.piece = Knight
                        result.moveInfo.nextCol = letterLabels.find(move[3])
                        result.moveInfo.nextRow = numberLabels.find(parseInt $move[4])
                    of 'B':
                        result.moveInfo.piece = Bishop
                        result.moveInfo.nextCol = letterLabels.find(move[3])
                        result.moveInfo.nextRow = numberLabels.find(parseInt $move[4])
                    of 'R':
                        result.moveInfo.piece = Rook
                        result.moveInfo.nextCol = letterLabels.find(move[3])
                        result.moveInfo.nextRow = numberLabels.find(parseInt $move[4])
                    of 'P':
                        result.moveInfo.piece = Pawn
                        result.moveInfo.nextCol = letterLabels.find(move[3])
                        result.moveInfo.nextRow = numberLabels.find(parseInt $move[4])
                    else:
                        report("Unparseable move: ", move)


        of 6: #this is likely a check(mate) from a queen side castle e.g O-O-O# or a disambiguation move, will parse these later
            if move[0..4] == "O-O-O": # O-O-O# or O-O-O+
                result.isCastleMove = true
                result.castleType = QueenSideCastle
                case move[5]:
                    of '+':
                        result.isCheck = true
                    of '#':
                        result.isCheckMate = true
                    else:
                        report("Unparseable move: ", move)
            else:
                report("Unparseable move: ", move, " likely a disambiguation move?")
        
        of 7:
            report("this is not parsed yet, am tired")
        else:
            report("Unparseable move: ", move)
            

proc parsePgn*(pgnString: string): ChessGame =
    let chessMoveParser = peg("chessMoves", chessGame: ChessGame):
        chessMoves <- chessMove * *(' ' * *chessMove) * >gameOutCome:
            chessGame.outcome = convertToGameScore($1)
        moveId <- +Digit
        whiteMove <- +Graph
        blackMove <- +Graph
        gameOutCome <- +Graph
        chessMove <- >moveId * '.' * >whiteMove * *'\n' * ' '[0..1] * *'\n' * * >blackMove * *'\n':
            add(chessGame.chessMoves, (moveId: parseInt($1), whiteMove: parseChessMove($2), blackMove: parseChessMove($3)))

    assert chessMoveParser.match(pgnString, result).ok

when isMainModule:
    template echoMove(id: int) =
        echo parsePgn(samplePgn).chessMoves[id-1]
    
    echoMove 1
