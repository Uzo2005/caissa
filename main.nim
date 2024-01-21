import sequtils, algorithm, os
import raylib
import ./parseFen
import ./parsePgn
import ./utils


const
    svgResourcesPath = "./resources/svg/"
    pngResourcesPath = "./resources/png/"
    fontResourcesPath = "./resources/fonts/"
    gamesResourcePath = "./resources/games/"

    labelFontPath = fontResourcesPath & "NotoSansSC-SemiBold.ttf"

    blackRookSvgPath = svgResourcesPath & "blackRook.svg"
    blackKnightSvgPath = svgResourcesPath & "blackKnight.svg"
    blackBishopSvgPath = svgResourcesPath & "blackBishop.svg"
    blackQueenSvgPath = svgResourcesPath & "blackQueen.svg"
    blackKingSvgPath = svgResourcesPath & "blackKing.svg"
    blackPawnSvgPath = svgResourcesPath & "blackPawn.svg"

    whiteRookSvgPath = svgResourcesPath & "whiteRook.svg"
    whiteKnightSvgPath = svgResourcesPath & "whiteKnight.svg"
    whiteBishopSvgPath = svgResourcesPath & "whiteBishop.svg"
    whiteQueenSvgPath = svgResourcesPath & "whiteQueen.svg"
    whiteKingSvgPath = svgResourcesPath & "whiteKing.svg"
    whitePawnSvgPath = svgResourcesPath & "whitePawn.svg"

    # blackRookPngPath = pngResourcesPath & "blackRook.png"
    # blackKnightPngPath = pngResourcesPath & "blackKnight.png"
    # blackBishopPngPath = pngResourcesPath & "blackBishop.png"
    # blackQueenPngPath = pngResourcesPath & "blackQueen.png"
    # blackKingPngPath = pngResourcesPath & "blackKing.png"
    # blackPawnPngPath = pngResourcesPath & "blackPawn.png"

    # whiteRookPngPath = pngResourcesPath & "whiteRook.png"
    # whiteKnightPngPath = pngResourcesPath & "whiteKnight.png"
    # whiteBishopPngPath = pngResourcesPath & "whiteBishop.png"
    # whiteQueenPngPath = pngResourcesPath & "whiteQueen.png"
    # whiteKingPngPath = pngResourcesPath & "whiteKing.png"
    # whitePawnPngPath = pngResourcesPath & "whitePawn.png"


const
    screenHeight = 900
    screenWidth = 1000
    boardSize = 800
    numberOfSquares = 8
    squareSize: int32 = boardSize div numberOfSquares
    labelPadding = squareSize div 5
    labelFontSize = float32(squareSize div 5)
    numberLabels = reversed(toSeq 1 .. 8)
    letterLabels = toSeq 'a' .. 'h'
    darkBoardColor = getColor(0xb58863ff'u32)
    lightBoardColor = getColor(0xf0d9b5ff'u32)
    pieceSize: int32 = (squareSize * 4) div 5
    pieceTint = White
    piecePadding = (squareSize div 5) div 2
    gameStartFen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
    afterE4Fen = "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1"
    samplePgn = readfile(gamesResourcePath & "sample.pgn")


initAudioDevice()

let 
    classicalMusic = loadSound("./resources/music/mozart-rondo-alla-turca-piano-sonata-no-11-a-major-kv-331-180136.mp3")

initWindow(screenWidth, screenHeight, "Caissa")
playSound(classicalMusic)

let
    labelFont = loadFont(labelFontPath)
    blackRook = loadTextureFromImage(loadImageSvg(blackRookSvgPath, pieceSize, pieceSize))
    blackKnight = loadTextureFromImage(loadImageSvg(blackKnightSvgPath,
            pieceSize, pieceSize))
    blackBishop = loadTextureFromImage(loadImageSvg(blackBishopSvgPath,
            pieceSize, pieceSize))
    blackQueen = loadTextureFromImage(loadImageSvg(blackQueenSvgPath, pieceSize, pieceSize))
    blackKing = loadTextureFromImage(loadImageSvg(blackKingSvgPath, pieceSize, pieceSize))
    blackPawn = loadTextureFromImage(loadImageSvg(blackPawnSvgPath, pieceSize, pieceSize))

    whiteRook = loadTextureFromImage(loadImageSvg(whiteRookSvgPath, pieceSize, pieceSize))
    whiteKnight = loadTextureFromImage(loadImageSvg(whiteKnightSvgPath,
            pieceSize, pieceSize))
    whiteBishop = loadTextureFromImage(loadImageSvg(whiteBishopSvgPath,
            pieceSize, pieceSize))
    whiteQueen = loadTextureFromImage(loadImageSvg(whiteQueenSvgPath, pieceSize, pieceSize))
    whiteKing = loadTextureFromImage(loadImageSvg(whiteKingSvgPath, pieceSize, pieceSize))
    whitePawn = loadTextureFromImage(loadImageSvg(whitePawnSvgPath, pieceSize, pieceSize))

var
    boardTexture = loadRenderTexture(boardSize, boardSize)
    boardState: BoardState

let
    boardTextureFlipped = Rectangle(x: 0.float32, y: 0.float32,
            width: boardSize.float32, height: -boardSize.float32)

    windowCenterPositionForBoard = Rectangle(
            x: ((screenWidth - boardSize) div 2), y: ((screenHeight -
                    boardSize) div 2), width: boardSize.float32,
            height: boardSize.float32)

    windowOrigin = Vector2(x: 0, y: 0)

    # centeredBoardPos = Vector2(x: ((screenWidth - boardSize) div 2), y: ((
    #         screenHeight - boardSize) div 2))

template drawPieceFromBoardState(piece: untyped, piecePos: Vector2): untyped =
    case `piece`:
        of 'R': drawTexture(whiteRook, piecePos, pieceTint)
        of 'N': drawTexture(whiteKnight, piecePos, pieceTint)
        of 'B': drawTexture(whiteBishop, piecePos, pieceTint)
        of 'Q': drawTexture(whiteQueen, piecePos, pieceTint)
        of 'K': drawTexture(whiteKing, piecePos, pieceTint)
        of 'P': drawTexture(whitePawn, piecePos, pieceTint)

        of 'r': drawTexture(blackRook, piecePos, pieceTint)
        of 'n': drawTexture(blackKnight, piecePos, pieceTint)
        of 'b': drawTexture(blackBishop, piecePos, pieceTint)
        of 'q': drawTexture(blackQueen, piecePos, pieceTint)
        of 'k': drawTexture(blackKing, piecePos, pieceTint)
        of 'p': drawTexture(blackPawn, piecePos, pieceTint)

        else:
            discard

template drawAllChessPiecesFromBoardState(boardState: BoardState): untyped =
    for index, chessPiece in boardState.piecePlacement:
        #index = (row * numberOfSquares) + col
        #numberOfSquares = 8

        let
            col = if boardState.isWhiteActive: (index mod 8) else: 7 - (index mod 8)
            row = if boardState.isWhiteActive: (index - (col)) div 8 else: 7 - ((index - (index mod 8)) div 8)
        #[
            remember boardPlacement follows fen structure
            where the first index is a8 and the last is h1, 
            moving strictly from left to right across each row.
        ]#
            squarePositionWithinTexture = Vector2(x: float32(col * squareSize),
                    y: float32(row * squareSize))
            #remember opengl y-flipping
            piecePositionWithinSquare = Vector2(
                    x: (squarePositionWithinTexture.x + piecePadding.float32),
                    y: (squarePositionWithinTexture.y + piecePadding.float32))

        drawPieceFromBoardState(chessPiece, piecePositionWithinSquare)


template drawChessBoard(isWhitePlayer: bool) =
    for i in 0..<numberOfSquares:
        for j in 0..<numberOfSquares:
            let
                posX = (i.int32 * squareSize)
                posY = (j.int32 * squareSize)

            #Draw Chess Board and square labels
            if ((i + j) and 1) != 0: #odd square
                drawRectangle(posX, posY, squareSize, squareSize, darkBoardColor)
            else: #even square
                drawRectangle(posX, posY, squareSize, squareSize, lightBoardColor)

            let
                numberLabelPos = Vector2(x: float32(posX + squareSize -
                        labelPadding), y: float32(posY + (labelPadding div 2)))
                letterLabelPos = Vector2(x: float32(posX + (
                        labelPadding div 2)), y: float32(posY + squareSize - labelPadding))

                numberLabelIndex = if isWhitePlayer: j else: 7 - j
                letterLabelIndex = if isWhitePlayer: i else: 7 - i
            
            if i == numberOfSquares - 1:
                drawText(labelFont, cstring $numberLabels[numberLabelIndex],
                        numberLabelPos, labelFontSize, float32 0.0, if ((i +
                                j) and 1) !=
                                0: lightBoardColor else: darkBoardColor)
            if j == numberOfSquares - 1:
                drawText(labelFont, cstring $letterLabels[letterLabelIndex],
                        letterLabelPos, labelFontSize, float 0.0, if ((i +
                        j) and 1) != 0: lightBoardColor else: darkBoardColor)

proc initBoardFromFen(boardTexture: RenderTexture2D, boardState: var BoardState,
        fenString: string = gameStartFen) =
    beginTextureMode(boardTexture)
    defer: endTextureMode()

    boardState = parseFen(fenString)

    drawChessBoard(boardState.isWhiteActive)

    drawAllChessPiecesFromBoardState(boardState)

proc gameMoves(pgnGame: ChessGame): iterator(): tuple[move: ChessMove, score: GameScore] =
    result = iterator(): tuple[move: ChessMove, score: GameScore] =
        for chessMove in pgnGame.chessMoves:
            yield (move: chessMove, score: pgnGame.outcome)


proc updateBoardTextureWithState(boardTexture: RenderTexture2D, state: BoardState) =
    beginTextureMode(boardTexture)
    defer: endTextureMode()

    drawChessBoard(isWhitePlayer = boardState.isWhiteActive)

    drawAllChessPiecesFromBoardState(state)


clearBackground(Black)

initBoardFromFen(boardTexture, boardState, gameStartFen)


setTargetFPS(60)


while(not windowShouldClose()):
    beginDrawing()

    #fliping the boardTexture around the x-axis because opengl decided to be silly
    drawTexture(boardTexture.texture, boardTextureFlipped,
        windowCenterPositionForBoard, windowOrigin, 0, White)
        
    boardTexture.updateBoardTextureWithState(boardState)

    endDrawing()

    if isKeyPressed(Space):
        let d4MoveInfo = parsePgnMoveText(samplePgn).chessMoves[0].whiteMove
        boardState.updateBoardStateWithMoveInfo(d4MoveInfo)
        # boardState.isWhiteActive = not boardState.isWhiteActive
        # boardState.piecePlacement = parseFen(afterE4Fen).piecePlacement
        # pauseSound(classicalMusic)

closeAudioDevice()
closeWindow()
