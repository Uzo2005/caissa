import strutils, sequtils, algorithm
import npeg

type 
    GameScore* = enum
        WhiteWins, BlackWins, Draw

    AllChessPieces = enum
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
                moveInfo*: tuple[piece: AllChessPieces, col: int, row: int]
        
        case isHighlyAmbiguousMove: bool #when both file and rank info will clarify move
            of true:
                    currentCol*: int
                    currentRow*: int
            else:
                case isSlightlyAmbiguousMove*: bool #when either file or rank info will clarify move
                    of true:
                        case fileInfoCanClarify*: bool
                            of true:
                                currentColInfo*: int
                            else:
                                currentRowInfo*: int
                    else:
                        discard


    ChessMove* = tuple[moveId: int, whiteMove: MoveInfo, blackMove: MoveInfo]

    ChessGame* = object
        chessMoves*: seq[ChessMove]
        outcome*: GameScore

const
    gamesResources = "./resources/games/"
    samplePgn = readfile(gamesResources & "sample.pgn")
    numberLabels = toSeq 1 .. 8
    letterLabels = toSeq 'a' .. 'h'

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
            result.moveInfo =  (piece: Pawn, col: letterLabels.find(move[0]), row: numberLabels.find(parseInt $move[1]))
        
        of 3:
            if move == "O-O": #king-side castle
                result.iscastleMove = true
                result.castleType = KingSideCastle
            else:
                case move[0]: #classic move like Bd1
                    of 'K':
                        result.moveInfo.piece = King
                        result.moveInfo.col = letterLabels.find(move[1])
                        result.moveInfo.row = numberLabels.find(parseInt $move[2])
                    of 'Q':
                        result.moveInfo.piece = Queen
                        result.moveInfo.col = letterLabels.find(move[1])
                        result.moveInfo.row = numberLabels.find(parseInt $move[2])
                    of 'N':
                        result.moveInfo.piece = Knight
                        result.moveInfo.col = letterLabels.find(move[1])
                        result.moveInfo.row = numberLabels.find(parseInt $move[2])
                    of 'B':
                        result.moveInfo.piece = Bishop
                        result.moveInfo.col = letterLabels.find(move[1])
                        result.moveInfo.row = numberLabels.find(parseInt $move[2])
                    of 'R':
                        result.moveInfo.piece = Rook
                        result.moveInfo.col = letterLabels.find(move[1])
                        result.moveInfo.row = numberLabels.find(parseInt $move[2])
                    of 'P':
                        result.moveInfo.piece = Pawn
                        result.moveInfo.col = letterLabels.find(move[1])
                        result.moveInfo.row = numberLabels.find(parseInt $move[2])

                    else: #a pawn check like g3+ or a mate like h4#
                        result.moveInfo.piece = Pawn
                        if move[2] == '+':
                            result.isCheck = true
                            result.moveInfo.col = letterLabels.find(move[0])
                            result.moveInfo.row = numberLabels.find(parseInt $move[1])
                        elif move[2] == '#':
                            result.isCheckMate = true
                            result.moveInfo.col = letterLabels.find(move[0])
                            result.moveInfo.row = numberLabels.find(parseInt $move[1])
                        else:
                            echo "Unparseable move: ", move

        of 4: #capture-move like Qxd2 or a check(mate)ing move like Nf5+ or even a check(mate) from king-side castle
            if move[0..2] == "0-0":
                result.isCastleMove = true
                case move[3]:
                    of '+':
                        result.isCheck = true
                    of '#':
                        result.isCheckMate = true
                    else:
                        echo "Unparseable move: ", move
            elif move[1] == 'x': #capture move
                result.isCaptureMove = true
                case move[0]:
                    of 'K':
                        result.moveInfo.piece = King
                        result.moveInfo.col = letterLabels.find(move[2])
                        result.moveInfo.row = numberLabels.find(parseInt $move[3])
                    of 'Q':
                        result.moveInfo.piece = Queen
                        result.moveInfo.col = letterLabels.find(move[2])
                        result.moveInfo.row = numberLabels.find(parseInt $move[3])
                    of 'N':
                        result.moveInfo.piece = Knight
                        result.moveInfo.col = letterLabels.find(move[2])
                        result.moveInfo.row = numberLabels.find(parseInt $move[3])
                    of 'B':
                        result.moveInfo.piece = Bishop
                        result.moveInfo.col = letterLabels.find(move[2])
                        result.moveInfo.row = numberLabels.find(parseInt $move[3])
                    of 'R':
                        result.moveInfo.piece = Rook
                        result.moveInfo.col = letterLabels.find(move[2])
                        result.moveInfo.row = numberLabels.find(parseInt $move[3])
                    of 'P':
                        result.moveInfo.piece = Pawn
                        result.moveInfo.col = letterLabels.find(move[2])
                        result.moveInfo.row = numberLabels.find(parseInt $move[3])
                    else: #pawn captures something like fxg4
                        result.moveInfo.piece = Pawn
                        result.moveInfo.col = letterLabels.find(move[2])
                        result.moveInfo.row = numberLabels.find(parseInt $move[3])
            
            elif move[3] == '+': #check
                result.isCheck = true
                case move[0]:
                    of 'K':
                        result.moveInfo.piece = King
                        result.moveInfo.col = letterLabels.find(move[1])
                        result.moveInfo.row = numberLabels.find(parseInt $move[2])
                    of 'Q':
                        result.moveInfo.piece = Queen
                        result.moveInfo.col = letterLabels.find(move[1])
                        result.moveInfo.row = numberLabels.find(parseInt $move[2])
                    of 'N':
                        result.moveInfo.piece = Knight
                        result.moveInfo.col = letterLabels.find(move[1])
                        result.moveInfo.row = numberLabels.find(parseInt $move[2])
                    of 'B':
                        result.moveInfo.piece = Bishop
                        result.moveInfo.col = letterLabels.find(move[1])
                        result.moveInfo.row = numberLabels.find(parseInt $move[2])
                    of 'R':
                        result.moveInfo.piece = Rook
                        result.moveInfo.col = letterLabels.find(move[1])
                        result.moveInfo.row = numberLabels.find(parseInt $move[2])
                    of 'P':
                        result.moveInfo.piece = Pawn
                        result.moveInfo.col = letterLabels.find(move[1])
                        result.moveInfo.row = numberLabels.find(parseInt $move[2])
                    else:
                        echo "Unparseable move: ", move

            elif move[3] == '#': #mate
                result.isCheckMate = true
                case move[0]:
                    of 'K':
                        result.moveInfo.piece = King
                        result.moveInfo.col = letterLabels.find(move[1])
                        result.moveInfo.row = numberLabels.find(parseInt $move[2])
                    of 'Q':
                        result.moveInfo.piece = Queen
                        result.moveInfo.col = letterLabels.find(move[1])
                        result.moveInfo.row = numberLabels.find(parseInt $move[2])
                    of 'N':
                        result.moveInfo.piece = Knight
                        result.moveInfo.col = letterLabels.find(move[1])
                        result.moveInfo.row = numberLabels.find(parseInt $move[2])
                    of 'B':
                        result.moveInfo.piece = Bishop
                        result.moveInfo.col = letterLabels.find(move[1])
                        result.moveInfo.row = numberLabels.find(parseInt $move[2])
                    of 'R':
                        result.moveInfo.piece = Rook
                        result.moveInfo.col = letterLabels.find(move[1])
                        result.moveInfo.row = numberLabels.find(parseInt $move[2])
                    of 'P':
                        result.moveInfo.piece = Pawn
                        result.moveInfo.col = letterLabels.find(move[1])
                        result.moveInfo.row = numberLabels.find(parseInt $move[2])
                    else: 
                        echo "Unparseable move: ", move
            
            else: #likely a disambiguation move like Rac1
                result.isSlightlyAmbiguousMove = true
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
                        echo "Unparseable move: ", move
                
                if not(move[1].isDigit):
                    result.fileInfoCanClarify = true
                    result.currentColInfo = letterLabels.find(move[1])
                else:
                    result.currentRowInfo = numberLabels.find(parseInt $move[1])

                result.moveInfo.col = letterLabels.find(move[2])
                result.moveInfo.row = numberLabels.find(parseInt $move[3])
            
        of 5: #capture-move with check or mate like Qxd2# or a queenside castle O-O-O, remember pawn captures with check(mate) like gxf5#
            if move == "O-O-O":
                result.isCastleMove = true
                result.castleType = QueenSideCastle
            elif move[1] == 'x': #capture move
                result.isCaptureMove = true
                case move[0]:
                    of 'K':
                        result.moveInfo.piece = King
                        result.moveInfo.col = letterLabels.find(move[2])
                        result.moveInfo.row = numberLabels.find(parseInt $move[3])
                    of 'Q':
                        result.moveInfo.piece = Queen
                        result.moveInfo.col = letterLabels.find(move[2])
                        result.moveInfo.row = numberLabels.find(parseInt $move[3])
                    of 'N':
                        result.moveInfo.piece = Knight
                        result.moveInfo.col = letterLabels.find(move[2])
                        result.moveInfo.row = numberLabels.find(parseInt $move[3])
                    of 'B':
                        result.moveInfo.piece = Bishop
                        result.moveInfo.col = letterLabels.find(move[2])
                        result.moveInfo.row = numberLabels.find(parseInt $move[3])
                    of 'R':
                        result.moveInfo.piece = Rook
                        result.moveInfo.col = letterLabels.find(move[2])
                        result.moveInfo.row = numberLabels.find(parseInt $move[3])
                    of 'P':
                        result.moveInfo.piece = Pawn
                        result.moveInfo.col = letterLabels.find(move[2])
                        result.moveInfo.row = numberLabels.find(parseInt $move[3])
                    else: #likely a pawn capture like gxf5+ or gxf5#
                        case move[4]:
                            of '+':
                                result.moveInfo.piece = Pawn
                                result.moveInfo.col = letterLabels.find(move[2])
                                result.moveInfo.row = numberLabels.find(parseInt $move[3])
                            of '#':
                                result.moveInfo.piece = Pawn
                                result.moveInfo.col = letterLabels.find(move[2])
                                result.moveInfo.row = numberLabels.find(parseInt $move[3])
                            else:
                                echo "Unparseable move: ", move

                case move[4]:
                    of '+':
                        result.isCheck = true
                    of '#':
                        result.isCheckMate = true
                    else:
                        echo "Unparseable move: ", move

            else:
                echo "Unparseable move: ", move

        of 6: #this is likely a check(mate) from a queen side castle e.g O-O-O# or a disambiguation move, will parse these later
            if move[0..4] == "O-O-O":
                result.isCastleMove = true
                case move[5]:
                    of '+':
                        result.isCheck = true
                    of '#':
                        result.isCheckMate = true
                    else:
                        echo "Unparseable move: ", move
            else:
                echo "Unparseable move: ", move, " likely a disambiguation move?"
        
        of 7:
            echo "this is not parsed yet, am tired"
        else:
            echo "Unparseable move: ", move
            

proc parsePgnMoveText*(pgnString: string): ChessGame =
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


echo parsePgnMoveText(samplePgn)