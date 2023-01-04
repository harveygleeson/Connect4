//
//  ViewController.swift
//  Connect4
//
//  Created by COMP47390 on 20/01/2022.
//  Copyright © 2020 COMP47390. All rights reserved.
//

import UIKit
import Alpha0Connect4

class ViewController: UIViewController {
    // MARK : - UI Outlets
    @IBOutlet weak var indicatorView: UIActivityIndicatorView!
    @IBOutlet weak var gameView: UIView!
    @IBOutlet weak var boardView: BoardView!
    @IBOutlet var tapGesture: UITapGestureRecognizer!
    @IBAction func tap(_ sender: UITapGestureRecognizer) {
        let touchCoordinates = sender.location(in: boardView)
        dropDisc(at: touchCoordinates)
    }
    
    @IBOutlet weak var gameMessage: UILabel!
    
    private var boardWidth: CGFloat = 0.0
    private var boardHeight: CGFloat = 0.0
    private var columnWidth: CGFloat = 0.0
    private var rowHeight: CGFloat = 0.0
    private var discDiameter: CGFloat = 0.0
    private var discCount: Int = 0
    private var discArray = [DiscView]()
    
    private func botDropsDisc(at location: (row: Int, column: Int)) {
        discCount += 1
        let column = location.column

        let discColor: UIColor = botColor.description == "red" ? .red : .yellow
        
        var frame = CGRect()
        frame.origin = CGPoint.zero
        frame.size = CGSize.init(width: discDiameter, height: discDiameter)
        
        let x = CGFloat(column - 1) * columnWidth
        frame.origin.x = x
        
        let discView = DiscView(frame: frame)
        discView.backgroundColor = discColor
        discView.discNumber = discCount
        discArray.append(discView)
        gameView.addSubview(discView)
        elasticBehaviour.addItem(discView)

        collider.addItem(discView)
        gravity.addItem(discView)

    }
    
    // Function for user to drop disc
    private func dropDisc(at touchLocation: CGPoint) {
        let discColor: UIColor = botColor == .yellow ? .red : .yellow
        discCount += 1
        print(touchLocation.debugDescription)
        print(boardView.bounds.width)
        
        // Frame for disc
        var frame = CGRect()
        frame.origin = CGPoint.zero
        frame.size = CGSize.init(width: discDiameter, height: discDiameter)
        
        let x = touchLocation.x
        frame.origin.x = roundToCellCoordinates(x: x)
        
        let discView = DiscView(frame: frame)
        discView.backgroundColor = discColor
        discView.discNumber = discCount
        discArray.append(discView)
        gameView.addSubview(discView)
        
        collider.addItem(discView)
        gravity.addItem(discView)
        elasticBehaviour.addItem(discView)
        
        // Drop disc
        let column = round(roundToCellCoordinates(x: x) / columnWidth)
        gameSession.dropDiscAt(Int(column) + 1)
    }
    
    // Round x point on screen to correct column
    private func roundToCellCoordinates(x: CGFloat) -> CGFloat {
        let width = boardView.frame.width
        let cellWidth = width / 7
        return cellWidth * CGFloat(floor(x / cellWidth))
    }
    
    private var gravity = UIGravityBehavior()
    private var collider = UICollisionBehavior()
    private var elasticBehaviour = UIDynamicItemBehavior()
    private var animator: UIDynamicAnimator?
    
    // Set random bot parameters
    private var botColor: GameSession.DiscColor = Bool.random() ? .red : .yellow
    private var isBotFirst = Bool.random()
    // Game session
    private var gameSession = GameSession()
    

    // MARK - VC lifecyle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Start new game session
        newGameSession()
        
        boardWidth = boardView.frame.width
        boardHeight = boardView.frame.height
        columnWidth = boardWidth / 7
        rowHeight = boardHeight / 6
        discDiameter = min(columnWidth, rowHeight) * 0.99
        self.animator = UIDynamicAnimator(referenceView: self.gameView)
        elasticBehaviour.elasticity = 0.45
        self.animator?.addBehavior(self.elasticBehaviour)
        self.animator?.addBehavior(self.gravity)
        
        // Set boundary function
        setBoundaries()
        
        // Swipe to clear
        let swipeHandler = UISwipeGestureRecognizer(target: self, action: #selector(swipeToClear))
        swipeHandler.direction = .down
        self.view.addGestureRecognizer(swipeHandler)
    }

    // Swipe to clear the game
    @objc private func swipeToClear() {
        self.collider.removeAllBoundaries()
        self.collider.translatesReferenceBoundsIntoBoundary =  false
        discCount = 0
        
        // Wait 3 seconds before starting new game
        Task {
            try await Task.sleep(nanoseconds: 3_000_000_000)
            await MainActor.run {
                newGameSession()
                setBoundaries()
            }
        }
    }
    
    private func setBoundaries() {
        self.collider.translatesReferenceBoundsIntoBoundary =  true
        
        // Create column padding so discs remain in their columns
        for i in 0 ..< 7 {

            let column = CGRect(x: CGFloat(i) * columnWidth, y: 0, width: 0.2, height: boardHeight)
            let columnBound = UIBezierPath(rect: column)
            self.collider.addBoundary(withIdentifier: "ColumnBound\(i)" as NSCopying, for: columnBound)
        }
        self.animator?.addBehavior(self.collider)
    }
    
    // Start game session with random bot parameter
    private func newGameSession() {
        // Random bot parameters
        botColor = Bool.random() ? .red : .yellow
        isBotFirst = Bool.random()
        
        // Print game layout
        print("CONNECT4 \(gameSession.boardLayout.rows) rows by \(gameSession.boardLayout.columns) columns")
        
        // Start game, resuming with some discs
        // set initialMoves to [(Int, Int)]() to start with clear board
        let initialMoves = [(Int, Int)]()
        self.gameSession.startGame(delegate: self, botPlays: self.botColor, first: self.isBotFirst, initialPositions: initialMoves)
    }
}


// MARK: - GameSessionProtocol

extension ViewController: GameSessionProtocol
{
    // GameSessionProtocol update for game state changes
    func stateChanged(_ gameSession: GameSession, state: SessionState, for playerTurn: DiscColor, textLog: String) {
        // Handle state transition
        print(state)
        switch state
        {
        // Inital state
        case .cleared:
            // Enable button if player turn is user
            let isUserTurn = (playerTurn != botColor)
            tapGesture.isEnabled = isUserTurn

        // Player evaluating position to play
        case .thinking(_):
            // Disable button while thinking
            tapGesture.isEnabled = false
            
        // Waiting for player to play
        case .idle(let color):
            // If player is bot, drop piece automatically
            // otherwise enable drop disc button
            if color == botColor {
                tapGesture.isEnabled = false
                gameSession.dropDisc()
                gameMessage.text? = ""
            } else {
                tapGesture.isEnabled = true
                print("waiting for \(color)")
                gameMessage.text? = "Your turn"
            }
            
        // End of game, update UI with game result, start new game
        case .ended(let outcome):
            // Disable button
            tapGesture.isEnabled = false

            // Display game result
            var gameResult: String
            switch outcome {
            case botColor:
                gameResult = "Bot (\(botColor)) wins!"
                gameMessage.text? = gameResult
            case !botColor:
                gameResult = "User (\(!botColor)) wins!"
                gameMessage.text? = gameResult
            default:
                gameResult = "Draw!"
                gameMessage.text? = gameResult
            }
            
            // Show results
            for disc in discArray {
                disc.numberLabel?.isHidden = false
            }
            
            // Save to core date
            let moc = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext
            _ = CoreDataSession.save(botPlays: botColor, first: isBotFirst, layout: gameSession.boardLayout,
                                     positions: gameSession.playerPositions, winningPositions: gameSession.winningPositions,
                                     in: moc)

            
            // Wait a while, clear the board, and start a new session
            indicatorView.startAnimating()
            Task {
                try await Task.sleep(nanoseconds: 3_000_000_000)
                await MainActor.run {
                    swipeToClear()
                }
                try await Task.sleep(nanoseconds: 1_000_000_000)
                await MainActor.run {
                    indicatorView.stopAnimating()
                    newGameSession()
                    setBoundaries()
                }
            }
            
        @unknown default:
            break
        }
    }
    
    
    // GameSessionProtocol notifying of the result of a player action
    // textLog provides some string visualization of the game board for debug purposes
    func didDropDisc(_ gameSession: GameSession, color: DiscColor, at location: (row: Int, column: Int), index: Int, textLog: String) {
        if color == botColor {
            botDropsDisc(at: location)
        }
        print("\(color) drops at \(location)")
    }

    
    // GameSessionProtocol notification of next player to play
    func turnToPlay(_ gameSession: GameSession, color: DiscColor) {
        print("\(color) turn")
    }

    
    // GameSessionProtocol notification of end of game
    func didEnd(_ gameSession: GameSession, color: DiscColor?, winningActions: [(row: Int, column: Int)]) {
        // Display winning disc positions
        print(winningActions.map({"\($0)"}).joined(separator: " "))
    }

}



