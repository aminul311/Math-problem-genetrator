// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MathProblemGenerator {
    
    // Struct to store problem data
    struct Problem {
        uint256 num1;
        uint256 num2;
        uint8 operation; // 0: addition, 1: subtraction, 2: multiplication, 3: division
        uint256 answer;
        uint256 timestamp;
        bool solved;
    }
    
    // Events
    event ProblemGenerated(address indexed user, uint256 indexed problemId, uint256 num1, uint256 num2, uint8 operation);
    event ProblemSolved(address indexed user, uint256 indexed problemId, bool correct);
    event DifficultyChanged(address indexed user, uint8 newDifficulty);
    
    // State variables
    mapping(address => Problem[]) public userProblems;
    mapping(address => uint256) public userScores;
    mapping(address => uint8) public userDifficulty; // 1: easy, 2: medium, 3: hard
    mapping(address => uint256) public totalProblemsSolved;
    
    uint256 private nonce;
    
    constructor() {
        nonce = 0;
    }
    
    // Function 1: Generate a new math problem
    function generateProblem() external {
        uint8 difficulty = userDifficulty[msg.sender] == 0 ? 1 : userDifficulty[msg.sender];
        uint8 operation = uint8(_random() % 4);
        
        uint256 num1;
        uint256 num2;
        uint256 answer;
        
        // Generate numbers based on difficulty
        if (difficulty == 1) { // Easy: 1-20
            num1 = (_random() % 20) + 1;
            num2 = (_random() % 20) + 1;
        } else if (difficulty == 2) { // Medium: 1-100
            num1 = (_random() % 100) + 1;
            num2 = (_random() % 100) + 1;
        } else { // Hard: 1-1000
            num1 = (_random() % 1000) + 1;
            num2 = (_random() % 1000) + 1;
        }
        
        // Calculate answer based on operation
        if (operation == 0) { // Addition
            answer = num1 + num2;
        } else if (operation == 1) { // Subtraction
            if (num1 < num2) {
                (num1, num2) = (num2, num1); // Ensure positive result
            }
            answer = num1 - num2;
        } else if (operation == 2) { // Multiplication
            answer = num1 * num2;
        } else { // Division
            // Ensure clean division
            answer = num1;
            num1 = answer * num2;
        }
        
        Problem memory newProblem = Problem({
            num1: num1,
            num2: num2,
            operation: operation,
            answer: answer,
            timestamp: block.timestamp,
            solved: false
        });
        
        userProblems[msg.sender].push(newProblem);
        uint256 problemId = userProblems[msg.sender].length - 1;
        
        emit ProblemGenerated(msg.sender, problemId, num1, num2, operation);
    }
    
    // Function 2: Submit answer to a problem
    function submitAnswer(uint256 problemId, uint256 userAnswer) external {
        require(problemId < userProblems[msg.sender].length, "Problem does not exist");
        require(!userProblems[msg.sender][problemId].solved, "Problem already solved");
        
        Problem storage problem = userProblems[msg.sender][problemId];
        bool isCorrect = (userAnswer == problem.answer);
        
        problem.solved = true;
        
        if (isCorrect) {
            userScores[msg.sender] += userDifficulty[msg.sender] == 0 ? 1 : userDifficulty[msg.sender];
        }
        
        totalProblemsSolved[msg.sender]++;
        
        emit ProblemSolved(msg.sender, problemId, isCorrect);
    }
    
    // Function 3: Set difficulty level
    function setDifficulty(uint8 difficulty) external {
        require(difficulty >= 1 && difficulty <= 3, "Invalid difficulty level");
        userDifficulty[msg.sender] = difficulty;
        
        emit DifficultyChanged(msg.sender, difficulty);
    }
    
    // Function 4: Get user's current problem
    function getCurrentProblem(uint256 problemId) external view returns (
        uint256 num1,
        uint256 num2,
        uint8 operation,
        bool solved,
        uint256 timestamp
    ) {
        require(problemId < userProblems[msg.sender].length, "Problem does not exist");
        
        Problem memory problem = userProblems[msg.sender][problemId];
        return (problem.num1, problem.num2, problem.operation, problem.solved, problem.timestamp);
    }
    
    // Function 5: Get user statistics
    function getUserStats() external view returns (
        uint256 totalProblems,
        uint256 problemsSolved,
        uint256 currentScore,
        uint8 difficulty
    ) {
        return (
            userProblems[msg.sender].length,
            totalProblemsSolved[msg.sender],
            userScores[msg.sender],
            userDifficulty[msg.sender] == 0 ? 1 : userDifficulty[msg.sender]
        );
    }
    
    // Function 6: Get total number of problems for user
    function getTotalProblems() external view returns (uint256) {
        return userProblems[msg.sender].length;
    }
    
    // Internal function to generate pseudo-random numbers
    function _random() private returns (uint256) {
        nonce++;
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, msg.sender, nonce)));
    }
}
